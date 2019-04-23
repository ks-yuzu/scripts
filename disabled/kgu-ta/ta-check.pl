#!/usr/bin/env perl
use v5.20;
use warnings;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

use HTTP::Request::Common;
use LWP::UserAgent;

use Path::Tiny;
use Getopt::Kingpin;

# constant
my $USER   = 'M7301';
my $YEAR   = 2017;
my $LESSON = 'prog1';
my $CLASS  = 3;

main(@ARGV);


sub main {
  # parse command line
  my $kingpin = Getopt::Kingpin->new();
  my $options = {
    output  => $kingpin->flag('output',  'specify output filename')->short('o')->string,
    nodl    => $kingpin->flag('nodl',    'use donwloaded sources')->bool,
    nocpl   => $kingpin->flag('nocpl',   'execute compiled binary')->bool,
    open    => $kingpin->flag('open',    'open sources w/ some commonad')->bool,
    verbose => $kingpin->flag('verbose', 'show the http response')->bool,
  };
  my $filename = $kingpin->arg('file', 'the name of downlaod file')->required;
  $kingpin->parse;

  # output setting
  my $output = path($options->{output} || "$filename.zip");
  if ( $output->is_dir ) {
    $output = $output->child("$filename.zip");
  }

  # download
  if ( not $options->{nodl} ) {
    # make url string
    my $range = substr $filename, 0, 2;
    my $cgi_url = 'http://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/report/main.cgi';
    my $url = "${cgi_url}?S=${YEAR}${LESSON}&act_download_multi=1&c=${CLASS}&r=${range}&i=${filename}";

    # input password from stdin
    my $password = type_password();

    # make and send a HTTP request
    say '[download]';
    my $req = HTTP::Request->new( GET => $url );
    $req->authorization_basic($USER, $password);
    my $ua = LWP::UserAgent->new();
    my $res = $ua->request($req);

    # check error in the HTTP response
    if ( not $res->is_success() ) {
      die $res->status_line;
    }

    check_error_in_res($res);

    # ouput zip
    path($output)->spew($res->content);
    say '  saved ' . path($output)->absolute->stringify;
    say '';
  }

  chdir path($output)->parent;

  # unzip
  if ( not $options->{nodl} ) {
    say "[unzip]  unzip -q $output";
    system "unzip -o -q $output";
    say '';
  }

  # compile
  chdir "${filename}-${CLASS}";
  my @ids = map { s/\.c//; $_ } split /\s/, qx|ls *.c 2> /dev/null|;
  if ( not $options->{nocpl} ) {
    print "[compile]\n ";
    for my $id ( @ids ) {
      say "skip $id" && next if $id !~ /^\d{4}$/;
      print " $id";
      my $rc = system "gcc ${id}.c -o $id 2> /dev/null";
      print RED '(failed)' if $rc;
    }
    say "\n";
  }

  # exec
  my $num = scalar grep {/^\d{4}$/} @ids;
  say '[exec] ' . $num . ' programs';
  for my $id ( @ids ) {
    say "skip $id" && next if $id !~ /^\d{4}$/;
    say BOLD YELLOW "* $id ";
    if( path($id)->exists ) {
      system "./${id}";
    }
    else {
      say "(error) file '$id' does not exist.";
    }

    system "emacsclient -n ./${id}.c" if $options->{open};
    say '';
    <stdin>;
  }
}


sub type_password {
  system "stty -echo";
  print "Password: ";
  chomp(my $pass = <STDIN>);
  system "stty echo";
  print "\n";

  return $pass;
}


sub check_error_in_res {
  my ($res, $options) = @_;

  # check response
  die "no response from server\n" if not defined $res;

  # check access
  die $res->content if $res->content =~ /Can't connect to/;

  # check authentication
  die $res->content if $res->content =~ /このページを見るのには許可が必要です/;

  # check URL error
  die $res->content if $res->content =~ /400 URL missing/;

  # show the HTTP response
  say $res->content if $options->{f_verbose};
}
