#!/usr/bin/env perl
use v5.18;
use warnings;
use diagnostics;

# use utf8;
# use open IO => qw/:encoding(UTF-8) :std/;

use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Term::ANSIColor qw(:constants);

use Path::Class;

## parse color options
my $f_colored = 1;
my $f_detail = 1;
GetOptions(
  'color!' => \$f_colored,
  'detail!' => \$f_detail
);

## constants
my $ESC="\e[";
my $ESCEND="m";
my $OK = "[  " . color("OK", GREEN) . "  ]  ";
my $NG = "[  " . color("NG", RED  ) . "  ]  ";



# main
check_format();
check_words();
check_bib();
check_ref();



sub check_format {
  my %ng_formats = (
    ' 1 ことで'   => '',
    ' 2 といった' => '',
    ' 3 。'       => '',
    ' 4 、'       => '',
    ' 5 ．'       => '',
    ' 6 ，'       => '',
    ' 7 　'       => '',
    ' 8 です'     => '6',
    ' 9 ます'     => '6',
    '10 及び'     => '',
    '11 など'     => '',
    '12 \(\('     => '',
    '13 言える'   => '',
    '14 り\.'     => '',
    '15 る,'      => '',
  );

  say '';
  say '***** check format *****';
  say '';

  for my $pattern ( sort keys %ng_formats ) {
    # 検索対象ファイルリストの作成
    my $exclude = $ng_formats{$pattern};
    my $target_files = qx/ls *.tex | grep -vP '\[!$exclude]'/;
    $target_files =~ s/\s+/ /g;

    # 先頭の数字を削除 (仮)
    $pattern =~ s/\s*\d+\s+(.*)/$1/;

    # マッチ行数を取得
    my $count = qx(hw --no-group --no-color -e '^[^\n%]*${pattern}' $target_files | grep -c '' | perl -pe "s/\\s//");

    # 出力
    my $pattern_non_escaped = $pattern =~ s/\\(.)/$1/gr;
    print '  ' . (!$count ? $OK : $NG) . "${pattern_non_escaped} ($count)\n";
    system qq(
      hw --group -e '^[^\n%]*${pattern}' $target_files |
        perl -pe 's/${pattern}/${ESC}31${ESCEND}${pattern}${ESC}${ESCEND}/g;
                  s/^( *)([0-9]+):/\$1${ESC}37${ESCEND}\$2${ESC}${ESCEND} : /;
                  s/^(.*.tex)/${ESC}32${ESCEND}\$1${ESC}${ESCEND}/;
                  s/^/              /
    '); # パターンを赤色, 行番号の後に空白挿入, ファイル名を緑にする
  }

  say '';
}



sub check_words {
  my @ng_words = (file 'ng_words.txt')->slurp(chomp => 1);
  @ng_words = grep { $_ =~ /\S/; $_ } @ng_words;

  say '';
  say '***** check words *****';
  say '';
  for my $pattern ( @ng_words ) {
    # 検索対象ファイルリストの作成
    my $exclude = '8';
    my $target_files = qx/ls *.tex | grep -vP '\[!$exclude]'/;
    $target_files =~ s/\s+/ /g;

    # マッチ行数を取得
    my $count = qx(hw --no-group --no-color -e '^[^\n%]*${pattern}' $target_files | grep -c '' | perl -pe "s/\\s//");

    # 出力
    my $pattern_non_escaped = $pattern =~ s/\\(.)/$1/gr;
    print '  ' . (!$count ? $OK : $NG) . "${pattern_non_escaped} ($count)\n";
    system qq(
      hw --group -e '^[^\n%]*${pattern}' $target_files | 
        perl -pe 's/${pattern}/${ESC}31${ESCEND}${pattern}${ESC}${ESCEND}/g;
                  s/^( *)([0-9]+):/\$1${ESC}37${ESCEND}\$2${ESC}${ESCEND} : /;
                  s/^(.*.tex)/${ESC}32${ESCEND}\$1${ESC}${ESCEND}/;
                  s/^/              /
    '); # パターンを赤色, 行番号の後に空白挿入, ファイル名を緑にする
  }

  say '';
}



sub check_bib {
  say '';
  say '***** check referece *****';
  say '';

  # /(数字)./ で始まるファイル中の 'bibitem' を含む行を検索
  my @bibs = qx/cat \$(ls -v | grep -P '^\\d+\\.') | grep -P "^[^%]*bibitem"/;

  # 各 bibitem に対応する番号表を作成
  my %bib_ids = ();
  for ( 0 .. $#bibs ) {
    $bibs[$_] =~ /\\bibitem\{(.*)\}/;
    $bib_ids{$1} = $_ + 1;
  }

  # /(数字)./ で始まるファイル中の 'cite' を含む行を検索
  my @cites = qx/grep -n cite \$(ls -v | grep -P '^\\d+\\.')/;
  my @buf = ();                         # 出力メッセージ用バッファ
  my %cite_appeared = (0 => 1);         # 出現した 'cite' のリスト
  my $f_error = 0;                      # エラー発生フラグ
  for ( @cites ) {
    chomp;
    /(?<file>[^:]+?):(?<line>[^:]+?):.*cite\{(?<name>.*?)\}/;
    my $bib_id = $bib_ids{$+{name}};
    push @buf, sprintf "%-50s %-20s %s\n", $+{file} . " (l.$+{line})", $+{name}, $bib_id;

    # order check
    if ( ! exists $cite_appeared{$bib_id} ) {
      use List::Util qw(max);
      $f_error = 1 if $bib_id < max(keys %cite_appeared);
      $cite_appeared{$bib_id} = 1;
    }
  }

  say '  ' . (!$f_error ? $OK : $NG) . 'bib order';
  print ' ' x 14 . $_ for @buf;
  say '';
}


sub check_ref {

  say '';
  say '';
  say '  [      ]  reference error (IT HAS NOT BEEN IMPLEMENTED)';
  say '';
  # ?? check
  # unrefered bib check
}



## util
sub color {
    my $str = shift;
    my $style = shift;
    return $f_colored ? ("${style}${str}" . RESET) : $str;
}


sub format_detail {
  map { s/^(.*?):(.*?):(.*)$/color($1,CYAN) . ":" . color($2, YELLOW) . ":$3"/e } @_;
  return @_;
}


sub indent {
  my ($level, @msg) = @_;
  return map {' ' x $level . $_} @msg;
}
