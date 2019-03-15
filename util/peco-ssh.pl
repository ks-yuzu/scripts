#!/usr/bin/env perl
use v5.20;
use warnings;
use diagnostics;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

use List::Util qw/max/;
use Path::Tiny;

use DDP;


# テスト用
return 1 if caller;
main(shift @ARGV // "$ENV{HOME}/.ssh/config");


# 以下の関数を利用して目的の処理を実現する
sub main {
  my $config         = load_config(shift);
  my $hosts          = parse_config($config);
  my $choices        = make_choices($hosts);
  my $selected_lines = select_by_peco($choices);

  if    ( scalar @$selected_lines == 0 ) { return 0 }
  elsif ( scalar @$selected_lines >= 2 ) { die "selected too many hosts\n" }

  my $selected_host  = extract_host_from_choiced_line(shift @$selected_lines);
  # ssh($selected_host);
  say $selected_host;
}


# 与えられたファイル名から中身を読み込んで返す. なければ...？
sub load_config {
  return path(shift)->slurp;
}


# ssh config を受け取り, ハッシュの配列にして返す
sub parse_config {
  my $config = shift;
  $config =~ s/#.*\n//g;

  my $res = [];
  my @matched = $config =~ /Host (?<host>.*?)\n(?<option>.*?)\n{2,}/sg;
  while ( @matched ) {
    my ($hostname, $options) = splice @matched, 0, 2;
    push @$res, +{
      Host => $hostname,
      map { /\s+(\S+)\s+(\S+)/ and ($1 => $2) } split /\n+/, $options
    };
  }

  return $res;
}


# [git@192.218.172.56] lab56-git  形式
sub make_choices {
  my $hosts = shift;
  $hosts = [ grep { $_->{Host} !~ /\*/ } @$hosts ];

  my $len = max map { length get_user_and_host_str($_) } @$hosts;
  return join "\n", map {
    sprintf "[ %-${len}s ] %s", get_user_and_host_str($_), $_->{Host}
  } @$hosts;
}


sub get_user_and_host_str {
  my $host = shift;
  my $user = $_->{User};
  return $user . ($user ? '@' : '') . $host->{HostName};
}


# 引数で指定した文字列を出力し, peco で選択した結果全てを配列のリファレンスで返す
sub select_by_peco {
  my $choices = shift;
  return [ split "\n", qx!echo "$choices" | peco! ];
}


# 選択肢の文字列から対象の 'Host' 名称を抽出して返す
sub extract_host_from_choiced_line {
  my $choice = shift;
  $choice =~ /\]\s*(?<host>\S+)/;
  return $+{host};
}


# 引数で指定した対象の 'Host' へ ssh する
sub ssh {
  my $host = shift;
  exec "ssh $host";
}
