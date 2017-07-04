#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

my $asm_name = shift;
die q/suffix is not '.asm'/ unless $asm_name =~ /\.asm$/;

system qq!perl ~/works/lab/astem/kuesim/assembler/assembler.pl $asm_name!;

my $bin_name = $asm_name =~ s/\.[^\.]*/.bin/r;

system qq!/bin/cat ~/works/lab/astem/kuesim/simulator/template-head.html $bin_name ~/works/lab/astem/kuesim/simulator/template-tail.html > ~/works/lab/astem/kuesim/simulator/kuesim.html!;
