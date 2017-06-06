#!/usr/bin/env bash

set -euo pipefail
# -u         : undefined variable → ${1:-} 
# -e         : error (command)    → option or '|| true'
# -o pipefail: 

basename=$1                 # tex-file name
filename=${basename%.*}     # no suffix


# ----- file check -----
if [ ! -f ${filename}.tex ]; then
    echo "file : '${filename}.tex' does not exist."
    return
fi


# ----- encode check -----
if [ $(file $basename | grep UTF-8 | wc -l) -lt 1 ]; then
    echo '[ convert to UTF-8     ]'
    # check if 'nkf' command exists
    if [ $(type nkf | grep -c 'not found') -eq 1 ]; then
        sudo apt-get install nkf -y
    fi
    nkf -w --overwrite $basename
else
    echo '[ check encode (UTF-8) ]'
fi


# ----- generate dvi -----
echo '[ generate tex -> dvi  ]'
platex ${filename}.tex                  # tex -> dvi 
platex ${filename}.tex 1>/dev/null 2>&1


# ----- check dvi -----
if [ ! -f ${filename}.dvi ]; then
    echo "file : '${filename}.dvi' does not exist."
    return
fi


# ----- generate pdf -----
dvipdfmx ${filename}.dvi 2> /dev/null   # dvi -> pdf
echo '[ generate dvi -> pdf  ]'


# ----- open pdf -----
if [ ! -f ${filename}.pdf ]; then
    echo "file : '${filename}.pdf' does not exist."
    return
fi  

# evince ${filename}.pdf &  # open pdf
#### ↑ if this line is not commented out, open pdf automatically ####

# ----- delete unnecessary files -----
rm ${filename}.dvi
rm ${filename}.aux
rm ${filename}.log
rm ${filename}.toc
