#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use Getopt::Kingpin;
my $kingpin = Getopt::Kingpin->new();
my $module_acap      = $kingpin->flag('acap'     , 'include from acap modules'     )->short('a')->bool;
my $module_mipslite  = $kingpin->flag('mips'     , 'include from mipslite modules' )->short('m')->bool;
my $module_testbench = $kingpin->flag('testbench', 'include from testbench modules')->short('t')->bool;
my $module_all       = $kingpin->flag('all'      , 'include from all modules'      )->short('f')->bool;
$kingpin->parse;

use Path::Tiny;
if ($module_acap      || $module_all) {
  chomp, path($_)->copy('.') for qx!find ~/ccap/modules             -name '*.v' | peco!
}

if ($module_mipslite  || $module_all) {
  chomp, path($_)->copy('.') for qx!find ~/tools/mipslite           -name '*.v' | peco!
}

if ($module_testbench || $module_all) {
  chomp, path($_)->copy('.') for qx!find ~/tools/mipslite/testbench -name '*.v' | peco!
}





