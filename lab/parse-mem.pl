#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

use lib '/home/yuzu/works/lab/lib/perl';
use ACAP::ParseMem;

use Getopt::Kingpin;
use Data::Printer { deparse => 1 };


# parse option/argument
my $kingpin       = Getopt::Kingpin->new();
my $opt_list      = $kingpin->flag('list', 'show symbols list')->short('l')->bool;
my $opt_detail    = $kingpin->flag('detail', 'show symbols list')->bool;
my $opt_mem_image = $kingpin->flag('dmem', 'specify d.mem file')->short('m')->default('')->string;
my $opt_mem_data  = $kingpin->flag('dump', 'specify memory dump file')->short('d')->default('')->string;
my $arg_symbols   = $kingpin->arg('symbol names', 'symbol names')->string_list;

$kingpin->parse;


# main process
my $mem = ACAP::ParseMem->new({
  mem_image => $opt_mem_image->value() || undef,
  mem_data  => $opt_mem_data->value()  || undef,
});

if ( $opt_list ) {
  if ( $opt_detail ) { p $mem->symbols() }
  else {
    my $symbols = $mem->symbols();
    say '[ '.$symbols->{$_}->{addr}.' ]'." $_" for
      sort { $symbols->{$a}->{addr} cmp $symbols->{$b}->{addr} } keys %$symbols;
  };
}
elsif ( not @{ $arg_symbols->value() } ) {
  $kingpin->help();
}
else {
  for my $symbol ( @{ $arg_symbols->value() } ) {
    next if not defined $mem->data($symbol);
    say "< $symbol >";
    p $mem->data($symbol);
    say "";
  }
}
