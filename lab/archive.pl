#!/usr/bin/env perl
use v5.24;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use Getopt::Kingpin;

use lib "$ENV{HOME}/works/";
use MyPassword::Archive;                          # ID, PW

# constant
my $url = 'http://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/webfiler/lab/main.cgi';
my $user = MyPassword::Archive::USER;
my $pass = MyPassword::Archive::PASS;

sub { # main
  my $kingpin = Getopt::Kingpin->new();
  my $f_list    = $kingpin->flag('list',    'show the list of files')->short('l')->bool;
  my $f_upload  = $kingpin->flag('upload',  'upload files'          )->short('u')->bool;
  my $f_verbose = $kingpin->flag('verbose', 'show http response'    )->short('v')->bool;
  my $args_obj  = $kingpin->arg('args',     'dir file1 file2 ...'   )->string_list;
  $kingpin->parse;

  my @args = @{ $args_obj->value };

  # list, upload 指定がなければ list
  if ( ! $f_list and ! $f_upload ) {
    $f_list = 1;
  }

  # パスワードファイルチェック
  die "[error] no loggin information\n" if ! defined $user || ! defined $pass;

  # ファイル一覧表示
  if ( $f_list ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリチェック
    list($dir, $f_verbose);
  }

  # アップロード
  if ( $f_upload ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリチェック
    die "no input file\n" if scalar @args == 0;            # ファイル指定チェック
    for my $file ( @args ) {                               # ファイル存在チェック
      die "file '$file' does not exist.\n" if not -f $file;
    }
    upload($dir, \@args);
  }
}->();


sub list {
  my ($dir, $f_verbose) = @_;

  # HTTP リクエストを作って投げる
  my $req = HTTP::Request->new(GET => "${url}?D=archives&dir=${dir}&sortby=filename");
  $req->authorization_basic($user, $pass);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # レスポンスチェック
  die "no response from server\n" if not defined $res;
  die $res->content if $res->content =~ /Can't connect to/;

  # HTTP のレスポンスを表示 (-v)
  say $res->content if $f_verbose;

  # ディレクトリエラーチェック
  die "Invalid dir: $dir\n" if $res->content =~ /invalid dir\($dir\)/;

  # リスト出力
  my @files = $res->content =~ /<input type="checkbox" name="SEL_(.*?)">/g;
  say STDERR "files in archive/$dir";
  # (scalar @files > 0) ? say join "\n", (map { "- $_"  } @files)
  (scalar @files > 0) ? say join "\n", (map { "$_"  } @files)
                      : say '(no file)';
};


sub upload {
  my ($dir, $files) = @_;

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
  my $req = POST($url,
                 Content_Type => 'form-data',
                 Content      => $content
            );
  $req->authorization_basic($user, $pass);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # レスポンスチェック
  die "no response from server\n" if not defined $res;
  die $res->content if $res->content =~ /Can't connect to/;

  # ディレクトリエラーチェック
  die "Invalid dir: $dir\n" if $res->content =~ /invalid dir\($dir\)/;

    # リスト出力
  my @files = $res->content =~ /uploaded '(.*?)'/g;
  say "uploaded the files to archive/$dir";
  say join "\n", (map { "- $_"  } @files);

  # say $res->content;
};
