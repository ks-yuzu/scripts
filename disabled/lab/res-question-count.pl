#!/usr/bin/env perl
use v5.26;
use warnings;
use diagnostics;
use autodie qw(:all);

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

use Encode;

use HTTP::Request::Common;
use LWP::UserAgent;

use Term::ANSIColor qw(:constants);
# use Term::ExtendedColor qw(:all);
use Text::UnicodeTable::Simple;

use Getopt::Kingpin;

my $kingpin = Getopt::Kingpin->new();
my $f_countup = $kingpin->flag('countup', 'count up')->short('c')->bool;
$kingpin->parse;



my $URL_SUMMARY = 'https://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/res/q/main.cgi';
my $URL_COUNTUP = 'https://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/res/q/main.cgi?act_newq=1&mid=M7301';
my $user = 'M7301';
my $pass = '';

if ( $f_countup ) {
  count_up();
}

while ( 1 ) {
  system 'clear';
  show_count_table();
  sleep 3;
}

sub count_up {
  my $req = GET($URL_COUNTUP);
  http_request($req);
}


sub show_count_table {
  my $req = GET($URL_SUMMARY);
  my $res = Encode::decode 'utf-8', http_request($req)->content;

  $res =~ m!<table>(.*)</table>!s or die;
  my $table_content = $1;

  my $table = Text::UnicodeTable::Simple->new(
    header     => [ qw/name count/ ],
    ansi_color => 1,
    alignment  => 'left',
  );

  # my $table = Text::ASCIITable->new({alignHeadRow => 'center'});
  while ( $table_content =~ m!<td.*?>(.*?)</td>!g ) {
    my $cell = $1;

    if ( $cell =~ m!<a.*?>(.*?)</a>!g ) {
      my ($name, $count) = split '<br>', $1;
      $cell = GREEN."$name (you)".RESET.'<br>'.GREEN.$count.RESET;
    }

    $table->add_rows([split '<br>', $cell]);
  }

  say $table->draw;
}


sub http_request {
  my ($req, $options) = @_;

  $req->authorization_basic($user, $pass);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # HTTP のレスポンスを表示 (-v)
  say $res->content if $options->{verbose};

  return $res;
}
