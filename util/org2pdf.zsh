#!/usr/bin/zsh

org_file=$1                 # org-file name
basename=${org_file%.*}     # no suffix

tex_file="${basename}.tex"

# add header
cat <<EOF > $tex_file
\documentclass[a4paper, 10.5pt]{jsarticle}
\usepackage[dvipdfmx]{graphicx}
\usepackage{url}
\usepackage{atbegshi}
\AtBeginShipoutFirst{\special{pdf:tounicode EUC-UCS2}}
\usepackage[dvipdfmx,setpagesize=false]{hyperref}
  \renewcommand \maketitle{}
\usepackage{boites}
\usepackage{txfonts}
\usepackage{bm}
\usepackage{boxedminipage}
\usepackage{multicol}
\setlength{\topmargin}{-20mm}
\setlength{\oddsidemargin}{-10mm}
\setlength{\textwidth}{180mm}
\setlength{\textheight}{260mm}
\author{Yuuki Oosako}
\date{\today}
\title{}
\hypersetup{
 pdfauthor={Yuuki Oosako},
 pdftitle={},
 pdfkeywords={},
 pdfsubject={},
 pdfcreator={Emacs 25.1.1 (Org mode 8.3.5)}, 
 pdflang={Ja}}
\begin{document}

\makeatletter
\def\section{\@startsection{section}{1}{\z@}%
{1.75ex plus 0.5ex minus .2ex}{0.75ex plus .2ex}{\normalsize\bf}}
\def\subsection{\@startsection{subsection}{2}{\z@}%
{1.5ex plus 0.5ex minus .2ex}{0.5ex plus .2ex}{\normalsize\bf}}
\def\subsection{\@startsection{subsection}{3}{\z@}%
{1.0ex plus 0.5ex minus .2ex}{0.5ex plus .2ex}{\normalsize\bf}}
\makeatother
\renewcommand{\baselinestretch}{0.85}

\begin{flushleft}
\textbf{$2}
\end{flushleft}
\begin{flushright}
$3\par
$4
\end{flushright}

EOF

# add body
pandoc $org_file -t latex | grep -v tightlist >> $tex_file

# add footer
cat <<EOF >> $tex_file

\end{document}
EOF

# compile
echo "compile $tex_file"
tex2pdf $tex_file

if [ -f ${basename}.out ]; then
    rm ${basename}.out
fi


