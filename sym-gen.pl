#!/usr/bin/env perl

# このディレクトリ以下のファイルへのシンボリックリンクを
# $HOMT/bin 等のパスの通ったディレクトリに自動的に生成するスクリプト
# (不足しているものを探して作成する)

use v5.24;
use warnings;
use diagnostics;

use File::Basename;

use Getopt::Kingpin;
my $kingpin  = Getopt::Kingpin->new();
my $f_dryrun = $kingpin->flag('dry_run', 'dry run')->short('d')->bool;

$kingpin->parse;


# my @files = qx(find `pwd` -type f);
my @files = qx(find `pwd` -type d -name disabled -prune -o -type f -print);

for my $file ( @files ) {
  chomp $file;
  next if $file =~ m!/.git/!;

  my $res = $f_dryrun ? '' : qx(ln -s $file \$HOME/bin 2>&1);

  $res !~ /File exists/ and say "create symbolic link '\$HOME/bin/" . basename($file) . "'";
}



