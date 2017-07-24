#!/usr/bin/env perl
use v5.24;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use Getopt::Kingpin;
use List::Util qw/max/;
use DDP;

use lib "$ENV{HOME}/works/";
use MyPassword::Archive;                          # ID, PW

# constant
my $URL = 'http://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/webfiler/lab/main.cgi';
my $USER = MyPassword::Archive::USER;
my $PASS = MyPassword::Archive::PASS;

sub { # main
  my $kingpin = Getopt::Kingpin->new();
  my %options;
  $options{f_show}    = $kingpin->flag('show',    'show the list of files')->short('s')->bool;
  $options{f_upload}  = $kingpin->flag('upload',  'upload files'          )->short('u')->bool;
  $options{f_list}    = $kingpin->flag('long',    'long listing (like ls)')->short('l')->bool;
  $options{f_verbose} = $kingpin->flag('verbose', 'show http response'    )->short('v')->bool;
  my $args_obj  = $kingpin->arg('args',     'dir file1 file2 ...'   )->string_list;
  $kingpin->parse;

  my @args = @{ $args_obj->value };

  # list, upload 指定がなければ list
  if ( ! $options{f_show} and ! $options{f_upload} ) {
    $options{f_show} = 1;
  }

  # パスワードファイルチェック
  die "[error] no loggin information\n" if ! defined $USER || ! defined $PASS;

  # ファイル一覧表示
  if ( $options{f_show} ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリチェック
    list($dir, \%options);
  }

  # アップロード
  if ( $options{f_upload} ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリチェック
    die "no input file\n" if scalar @args == 0;            # ファイル指定チェック
    for my $file ( @args ) {                               # ファイル存在チェック
      die "file '$file' does not exist.\n" if not -f $file;
    }
    upload($dir, \@args, \%options);
  }

  # ダウンロード
  if ( 1 ) {
    
  }
}->();


sub list {
  my ($dir, $options) = @_;

  # HTTP リクエストを作って投げる
  my $req = HTTP::Request->new(GET => "${URL}?D=archives&dir=${dir}&sortby=filename");
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # レスポンスチェック
  die "no response from server\n" if not defined $res;
  die $res->content if $res->content =~ /Can't connect to/;

  # HTTP のレスポンスを表示 (-v)
  say $res->content if $options->{f_verbose};

  # ディレクトリエラーチェック
  die "Invalid dir: $dir\n" if $res->content =~ /invalid dir\($dir\)/;

  # リスト出力
  list_parse_res($res->content, $options);
};


sub list_parse_res {
  my ($res, $options) = @_;

  # HTTP レスポンスのパース
  my @files;
  while ( $res =~ m|<tr>(?<item>.*?)</tr>|g ) {
    my ($select, $actions, $filename, $size, $time) = ($+{item} =~ m|<td.*?>(?<column>.*?)</td>|g);

    next if $select !~ /name="SEL_/;    # 上の階層に戻る (↑) は除外

    # 余計なタグ・文字実体参照を削除
    $filename =~ s/<.*?>//g;
    $filename =~ s/&.*?;\s*//g;
    $size =~ s/<.*?>//g;
    $time =~ s/<.*?>//g;

    push @files, { filename => $filename, size => $size, time => $time, };
  }

  if ( @files == 0 ) {
    say STDERR '(no file)';
    return;
  }

  # say STDERR "files in archive/$dir";

  # ファイルリスト表示
  if ( $options->{f_list} ) {
    my $width_size_column = max map {length $_->{size}} @files;
    for my $file ( @files ) {
      printf "%s  %${width_size_column}s  %s\n", $file->{time}, $file->{size}, $file->{filename};
    }
  }
  else {
    say join "\n", map { $_->{filename} } @files;
  }
}


sub upload {
  my ($dir, $files, $options) = @_;

  # POST メソッドで送る content
  my $content = [
    D               => 'archives',
    dir             => $dir,
    act_upload_exec => 'UPLOAD ALL',
    n_items         => scalar @$files,
  ];

  # ファイルを content に追加
  for my $id ( 0 .. $#{ $files } ) {
    push @$content, "src_f_$id";
    push @$content, [$files->[$id]];
    push @$content, "dst_f_$id";
    push @$content, '';
  }

  # HTTP リクエストを作って投げる
  my $req = POST(
    $URL,
    Content_Type => 'form-data',
    Content      => $content
  );
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # レスポンスチェック
  die "no response from server\n" if not defined $res;
  die $res->content if $res->content =~ /Can't connect to/;

  # HTTP のレスポンスを表示 (-v)
  say $res->content if $options->{f_verbose};

  # ディレクトリエラーチェック
  die "Invalid dir: $dir\n" if $res->content =~ /invalid dir\($dir\)/;

  # リスト出力
  my @files = $res->content =~ /uploaded '(.*?)'/g;
  say "uploaded the files to archive/$dir";
  say join "\n", (map { "- $_"  } @files);
};
