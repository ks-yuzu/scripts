#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use Getopt::Kingpin;
use Math::Random::MT;

my $kingpin = Getopt::Kingpin->new();
my $num         = $kingpin->flag('number', 'the number of select')->short('n')->default(1)->int;
my $sort        = $kingpin->flag('sort', 'sort')->short('s')->default('index')->string;
my $dupl        = $kingpin->flag('dupl', 'duplication')->short('d')->bool;
my $samples_obj = $kingpin->arg('samples', ' a list of sample')->string_list;

$kingpin->parse;

my @samples = @{ $samples_obj->value };

my %selected = ();
for ( 1 .. $num ) {
  my $mt = Math::Random::MT->new();
  my $index = int( $mt->rand( scalar @samples ) );

  next if exists $selected{$index};
  $selected{$index} = $samples[$index];
}
say for %selected;
say '';
