#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

my $num_page_orig = shift;
my $num_page = $num_page_orig;

$num_page += ($num_page % 4) ? (4 - $num_page % 4) : 0;
say "pages: $num_page_orig -> $num_page";


my $head = 1;
my $tail = $num_page - 1;

# n, 1, 2, n-1, n-2, 3, 4, n-3, n-4, 5, 6, n-5, n-6, 7, 8, n-7, n-8, 9, 10, n-9, n-10, 11, 12, n-11...
my @pages = ();
push @pages, $num_page;
while ( 1 ) {
  push @pages, $head;  $head++;
  last unless $head <= $tail;
  push @pages, $head;  $head++;
  last unless $head <= $tail;
  push @pages, $tail;  $tail--;
  last unless $head <= $tail;
  push @pages, $tail;  $tail--;
  last unless $head <= $tail;
}

print join ', ', @pages;




