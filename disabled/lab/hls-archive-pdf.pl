#!/usr/bin/env perl

# 月毎の進捗報告をまとめる雑スクリプト
#
# usage:
# $ perl [filename] 2018 12  # 2018 年 12 月
#
# (Path::Tiny 必須)

use v5.26;
use warnings;
use autodie qw(:all);

use Cwd;
use Path::Tiny;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;


# cmdline params
my $year  = shift // die;
my $month = shift // die;


# settings
my $ID = 'M7301';
my $PW = '!! type your passwrod here !!';

my $URL          = 'https://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/webfiler/lab/main.cgi';
my $archive_path = 'HLS/LATEST';

my $cover_basename         = 'cover';
my $target_filename_regexp = qr/^${year}-${month}.*\.pdf$/;
my $archive_filename       = "${year}-${month}-hls.pdf";


# script
my $work_dir = Cwd::getcwd();
main();


sub main {
  download_dir($archive_path);
  make_cover();
  archive_pdf($target_filename_regexp, $archive_filename);

  path($work_dir)->child('all_pdf.zip')->remove();
  path($work_dir)->child('cover.pdf')->remove();
  path($work_dir)->child('LATEST')->remove_tree();
}


sub make_cover {
  my $cover_tex = join '', <DATA>;

  $cover_tex =~ s/\$\(YEAR\)/$year/;
  $cover_tex =~ s/\$\(MONTH\)/$month/;

  my $tempdir = Path::Tiny->tempdir // die 'failed to make tempdir';
  chdir $tempdir;

  my $path_cover_tex = $tempdir->child("${cover_basename}.tex");
  $path_cover_tex->spew($cover_tex);

  # シェルコマンド (インデント有りヒアドキュメントは Perl 5.26+)
  my $cmd = <<~'SCRIPT_END';
  set -euo pipefail

  platex $(cover_basename).tex                  # tex -> dvi
  platex $(cover_basename).tex                  # 2nd for \ref and \cite
  dvipdfmx $(cover_basename).dvi 2> /dev/null   # dvi -> pdf
  rm $(cover_basename).dvi
  rm $(cover_basename).aux
  rm $(cover_basename).log
  SCRIPT_END

  $cmd =~ s/\$\(cover_basename\)/$cover_basename/g;
  system "bash -c $cmd";

  chdir $work_dir;
  $tempdir->child("${cover_basename}.pdf")->copy($work_dir);
}


sub download_dir {
  my $dir = shift // die;

  my $params = "D=archives&dir=$dir";
  my $body   = "D=archives&dir=$dir&act_download_zip=download%20all%20in%20zip";

  my $cmd = <<~"SCRIPT_END";
  set -euo pipefail

  curl -X POST '${URL}?${params}' -d '$body' -u ${ID}:${PW} -o all_pdf.zip
  unzip all_pdf.zip
  SCRIPT_END

  system "bash -c $cmd";
}


sub archive_pdf {
  my $target_filename_regexp  = shift // die;
  my $archive_filename        = shift // die;

  my @target_files = sort map {
    $_->stringify
  } path($work_dir)->child('LATEST')->children($target_filename_regexp);

  say 'archive files:';
  say "  $_" for @target_files;

  system "pdftk @target_files cat output $archive_filename";
}


__DATA__
\documentclass[a4paper, 10.5pt]{jarticle}

\usepackage{txfonts}
\usepackage{bm}
\usepackage{boxedminipage}
\usepackage{multicol}
\usepackage[dvipdfmx]{graphicx}

\setlength{\topmargin}{-20mm}
\setlength{\oddsidemargin}{-14mm}
\setlength{\textwidth}{180mm}
\setlength{\textheight}{260mm}

\makeatletter
\def\section{\@startsection{section}{1}{\z@}%
{1.75ex plus 0.5ex minus .2ex}{0.75ex plus .2ex}{\normalsize\bf}}
\def\subsection{\@startsection{subsection}{2}{\z@}%
{1.5ex plus 0.5ex minus .2ex}{0.5ex plus .2ex}{\normalsize\bf}}
\def\subsection{\@startsection{subsection}{3}{\z@}%
{1.0ex plus 0.5ex minus .2ex}{0.5ex plus .2ex}{\normalsize\bf}}
\makeatother
\renewcommand{\baselinestretch}{0.85}

\begin{document}

\begin{flushleft}
\textbf{HLS 進捗報告}
\end{flushleft}

\begin{center}
\vspace*{\stretch{1}}
{\Huge $(YEAR). $(MONTH) HLS}
\vspace{\stretch{1}}
\end{center}

\end{document}
