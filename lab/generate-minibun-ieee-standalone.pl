#!/usr/bin/env perl
use v5.26;
use warnings;
use diagnostics;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

use HTTP::Tiny;
use JSON::XS;
use Getopt::Kingpin;


my $kingpin = Getopt::Kingpin->new();
my $prez_date = $kingpin->flag('date', 'presentation date')->short('d')->string->default('20XX-YY-ZZ');
my $name      = $kingpin->flag('name', 'presenter name')->short('n')->string->default('大迫 裕樹');
my $urls      = $kingpin->arg('urls', ' a list of urls')->string_list;

$kingpin->parse;
$urls = $urls->value;


sub { # main
  print_header();

  for my $i ( 0 .. $#$urls ) {
    my $url = $urls->[$i];
    my $metadata = get_metadata($url);
    print_bib($metadata);
  }

  print_footer();
}->();


sub get_metadata {
  my ($url) = @_;

  my $html = _get_html($url);
  my $json = _extract_metadata_from_html($html);

  return JSON::XS::decode_json $json;
}


sub _get_html {
  my ($url) = @_;

  my $http = HTTP::Tiny->new;
  my $res = $http->get($url);

  unless ( $res->{success} ) {
    say $res->status_line;
    die "cannot access $url";
  }

  return $res->{content}
}


sub _extract_metadata_from_html {
  my ($html) = @_;

  $html =~ /global\.document\.metadata=(?<json>{.*?});/;
  return $+{json};
}


# 手抜き...
sub print_header {
  say <<EOF;
\\documentclass[a4paper, 10pt]{jarticle}

\\topmargin -0.8in
\\oddsidemargin -7mm
\\evensidemargin
\\oddsidemargin
\\textwidth 174mm
\\textheight 274mm

\\renewcommand{\\baselinestretch}{1.0}
\\pagestyle{empty}

\\begin{document}

\\begin{flushright}
  ${prez_date} ${name}
\\end{flushright}

\\begin{center}
  \\Large{文献調査\\\\}
\\end{center}

EOF
}


sub print_bib {
  my ($metadata) = @_;

  state $call_count = 0;
  ++$call_count;

  my $pub_year     = $metadata->{publicationDate} =~ s/^.*?(\S+)$/$1/r;
  my $pub_month    = $metadata->{publicationDate} =~ s/^(\S+).*?$/$1/r;
  my $title        = $metadata->{formulaStrippedArticleTitle};
  my $authors      = join ', ', map { $_->{name} } @{ $metadata->{authors} };
  my $id           = ($metadata->{authors}->[0]->{name} =~ s/^.*?(\S+)$/$1/r) . $pub_year;
  my $published_in = $metadata->{publicationTitle} =~ s/^(.*), (.*)/$2 $1/r;
  my $start_page   = $metadata->{startPage};
  my $end_page     = $metadata->{endPage};
  my $abstract     = $metadata->{abstract};
  $abstract =~ s/%/\%/;                 # % があるとコメント扱いになるのでエスケープ

  say <<EOF;
%% ------------------------- bib ${call_count} -------------------------
\\begin{center}
  \\textbf{\\large{
      ${title} [${id}]
  \\\\}}
  ${published_in}\\\\
  ${authors}\\\\
  pp. ${start_page}-${end_page} (${pub_month}, ${pub_year})
\\end{center}

\\textbf{ABSTRACT\\\\}
${abstract}

\\vspace{2em}
%% ---------------------------------------------------------

EOF
}


sub print_footer {
say <<EOF;

\\end{document}

EOF
}
