#!/usr/bin/env perl
use v5.26;
use warnings;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;

use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Term::ANSIColor qw(:constants);

use Path::Tiny;
use Test2::V0;

use Encode;
use DDP;

## parse color options
my $f_colored = 1;
my $f_detail  = 1;
GetOptions(
  'color!'  => \$f_colored,
  'detail!' => \$f_detail,
);

## constants
my $ESC="\e[";
my $ESCEND="m";
my $OK = "[  " . color("OK", GREEN) . "  ]  ";
my $NG = "[  " . color("NG", RED  ) . "  ]  ";



# main
sub {
  my $tex_filename = shift;
  my @tex = path($tex_filename)->lines({chomp => 1});

  check_format(\@tex);
  # check_words(\@tex);
  # check_bib(\@tex);
  # check_ref(\@tex);
}->(@ARGV);



sub check_format {
  my $tex = shift;

  my @ng_patterns = (
    { pattern => 'ことで'  , category => '' },
    { pattern => 'といった', category => '' },
    { pattern => '。'      , category => '' },
    { pattern => '、'      , category => '' },
    { pattern => '．'      , category => '' },
    { pattern => '，'      , category => '' },
    { pattern => '　'      , category => '' },
    { pattern => 'です'    , category => '' },
    { pattern => 'ます'    , category => '' },
    { pattern => '及び'    , category => '' },
    { pattern => 'など'    , category => '' },
    { pattern => '\(\('    , category => '' },
    { pattern => '言える'  , category => '' },
    { pattern => 'り\.'    , category => '' },
    { pattern => 'る,'     , category => '' },
    { pattern => 'TODO'    , category => '' },
  );

  subtest 'check format' => sub {
    for my $pattern ( map {$_->{pattern}} @ng_patterns ) {
      my @tmp = map {
        my $idx = index($tex->[$_], $pattern);
        $idx >= 0 ? ("l.$_ " . $tex->[$_]) : ()
      } 0..$#$tex;
      is \@tmp, [], "$pattern";
    }
  };


  # for my $pattern ( sort keys %ng_formats ) {
  #   # 検索対象ファイルリストの作成
  #   my $exclude = $ng_formats{$pattern};
  #   my $target_files = qx/ls *.tex | grep -vP '\[!$exclude]'/;
  #   $target_files =~ s/\s+/ /g;

  #   # 先頭の数字を削除 (仮)
  #   $pattern =~ s/\s*\d+\s+(.*)/$1/;

  #   # マッチ行数を取得
  #   my $count = qx(hw --no-group --no-color -e '^[^\n%]*${pattern}' $target_files | grep -c '' | perl -pe "s/\\s//");

  #   # 出力
  #   my $pattern_non_escaped = $pattern =~ s/\\(.)/$1/gr;
  #   print '  ' . (!$count ? $OK : $NG) . "${pattern_non_escaped} ($count)\n";
  #   system qq(
  #     hw --group -e '^[^\n%]*${pattern}' $target_files |
  #       perl -pe 's/${pattern}/${ESC}31${ESCEND}${pattern}${ESC}${ESCEND}/g;
  #                 s/^( *)([0-9]+):/\$1${ESC}37${ESCEND}\$2${ESC}${ESCEND} : /;
  #                 s/^(.*.tex)/${ESC}32${ESCEND}\$1${ESC}${ESCEND}/;
  #                 s/^/              /
  #   '); # パターンを赤色, 行番号の後に空白挿入, ファイル名を緑にする
  # }

  # say '';
}



sub check_words {

  my @ng_words = path('./ng_words.txt')->exists
    ? path('./ng_words.txt')->slurp()
    : ();
  @ng_words = grep { $_ =~ /\S/; $_ } @ng_words;

  say '';
  say '***** check words *****';
  say '';
  for my $pattern ( @ng_words ) {
    # 検索対象ファイルリストの作成
    my $exclude = '';
    my $target_files = qx/ls *.tex | grep -vP '\[!$exclude]'/; # TODO: fix exclude
    $target_files =~ s/\s+/ /g;
    if ( length $target_files == 0 ) {
      say 'no file to check word';
      next;
    }

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



# sub check_bib {
#   say '';
#   say '***** check referece *****';
#   say '';

#   # /(数字)./ で始まるファイル中の 'bibitem' を含む行を検索
#   # my @bibs = qx/cat \$(ls -v | grep -P '^\\d+\\.') | grep -P "^[^%]*bibitem"/;  # bt
#   # 指定したファイル中の 'bibitem' を含む行を検索
#   my @bibs = qx/grep -P "^[^%]*bibitem" ${tex_file}/; # general

#   # 各 bibitem に対応する番号表を作成
#   my %bib_ids = ();
#   for ( 0 .. $#bibs ) {
#     $bibs[$_] =~ /\\bibitem\{(.*)\}/;
#     $bib_ids{$1} = $_ + 1;
#   }

#   # /(数字)./ で始まるファイル中の 'cite' を含む行を検索
#   # my @cites = qx/grep -n cite \$(ls -v | grep -P '^\\d+\\.')/;  # bt
#   my @cites = qx/grep -n '^[^%]*cite' ${tex_file}/;
#   my @buf = ();                         # 出力メッセージ用バッファ
#   my %cite_appeared = (0 => 1);         # 出現した 'cite' のリスト
#   my $f_error = 0;                      # エラー発生フラグ
#   for ( @cites ) {
#     my ($line) = /([^:]+?):/;           # 行番号のキャプチャ

#     while( /cite\{(?<name>.*?)\}/g ) {  # 行内の cite を順番にチェック
#       # 存在チェック
#       my $bib_id = $bib_ids{$+{name}};
#       if ( not defined $bib_id ) {
#         say STDERR "  (error) found an undefined bib '$+{name}'";
#         $f_error = 1;
#         next;
#       }

#       # 出力テキスト作成
#       push @buf, sprintf "%-50s %-20s %s\n", # $+{file} . 
#         " (l.${line})", $+{name}, $bib_id;

#       # order check
#       if ( ! exists $cite_appeared{$bib_id} ) {
#         use List::Util qw(max);
#         # $f_error = 1 if $bib_id < max(keys %cite_appeared);
#         $f_error = 1 if $bib_id != max(keys %cite_appeared) + 1;
#         $cite_appeared{$bib_id} = 1;
#       }
#     }
#   }

#   say '  ' . (!$f_error ? $OK : $NG) . 'bib order';
#   print ' ' x 14 . $_ for @buf;
#   say '';
# }


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
