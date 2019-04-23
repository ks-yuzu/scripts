#!/bin/bash

basename=$1                 # tex-file name
filename=${basename%.*}     # no suffix

export TEXINPUTS=$TEXINPUTS:./:~/works/styles

if [ -f ${filename}.tex ]; then
    if [ $(file $basename | grep UTF-8 | wc -l) -lt 1 ]; then
        echo '[ convert to UTF-8     ]'
        nkf -w --overwrite $basename
    else
        echo '[ check encode (UTF-8) ]'
    fi

    if [ -f /tmp/$filename.tex ]; then
        rm -f /tmp/${filename}.tex
    fi
    cp ${filename}.tex /tmp
    pushd . > /dev/null
    cd /tmp > /dev/null
    echo '[ generate tex -> dvi  ]'
    platex ${filename}.tex      # tex -> dvi
else
    echo "file : '${filename}.tex' does not exist."
    return
fi

if [ -f ${filename}.dvi ]; then
    dvipdfmx ${filename}.dvi 2> /dev/null   # dvi -> pdf
    echo '[ generate dvi -> pdf  ]'
else
    echo "file : '/tmp/${filename}.dvi' does not exist."
    return
fi

if [ -f ${filename}.pdf ]; then
    popd > /dev/null 2>&1
    rm -f ${filename}.pdf 2> /dev/null
    cp /tmp/${filename}.pdf ./
    echo '[ open generated pdf   ]'
    evince ${filename}.pdf &  # open pdf
else
    echo "file : '/tmp/${filename}.pdf' does not exist."
fi  
