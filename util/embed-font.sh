#!/bin/sh
filename=${1%.*}
infile=${filename}.pdf
outfile=${filename}_with_fonts.pdf

# check input file
if [ ! -f ${infile} ]; then
    echo "Not found file '${infile}'"
    exit 1
fi

# embed fonts
echo "Generating a pdf file with all fonts"
gs -q -dNOPAUSE -dBATCH -dPDFSETTINGS=/prepress -sDEVICE=pdfwrite -sOutputFile=${outfile} ${infile}

# check enbedded fonts
count_no_font=$(pdffonts ${outfile} | \
                perl -nE '@vs=split / {3,}/; say $vs[3]' | \
                awk '{print $1}' | \
                grep no | wc -l )

if [ $count_no_font != 0 ]; then
    echo
    pdffonts ${outfile} | perl -pe 's/^/  /'
    echo
    echo "Found 'no' in column 'enb'"
    echo 'error'
    echo
    exit 1
fi

# success message
echo "Generated successfully!"
echo "  ${infile} → ${outfile}"
