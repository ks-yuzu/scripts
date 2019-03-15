#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use File::Basename;

my @files = qx(find `pwd` -type f);

for my $file ( @files ) {
  chomp $file;
  next if $file =~ m!/.git/!;

  my $res = qx(ln -s $file \$HOME/bin 2>&1);

  $res !~ /File exists/ and say "create symbolic link '\$HOME/bin/" . basename($file) . "'";
}

