#!/usr/bin/env perl
use v5.24;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use List::Util qw/max/;
use Path::Tiny;
use Getopt::Kingpin;
use DDP;
use Time::Piece;

use lib "$ENV{HOME}/works/";
use MyPassword::Archive; # ID, PW


# constant
my $URL = 'https://ist.ksc.kwansei.ac.jp/~ishiura/cgi-bin/webfiler/lab/main.cgi';
my $USER = MyPassword::Archive::USER;
my $PASS = MyPassword::Archive::PASS;


sub { # main
  my $kingpin = Getopt::Kingpin->new();
  my %options = (
    f_show      => $kingpin->flag('show',         'show the list of files' )->short('s')->bool,
    f_list      => $kingpin->flag('long',         'long listing (like ls)' )->short('l')->bool,
    f_upload    => $kingpin->flag('upload',       'upload files'           )->short('u')->bool,
    f_download  => $kingpin->flag('download',     'download files'         )->short('d')->bool,
    f_recursive => $kingpin->flag('download zip', 'download files'         )->short('r')->bool,
    f_verbose   => $kingpin->flag('verbose',      'show http response'     )->short('v')->bool,
    output      => $kingpin->flag('output',       'specify output filename')->short('o')->string,
  );
  my $args_obj  = $kingpin->arg('args',     'dir file1 file2 ...'   )->string_list;
  $kingpin->parse;

  my @args = @{ $args_obj->value };

  # show, upload, download 指定がなければ show
  if ( !$options{f_show} and !$options{f_upload} and !$options{f_download} ) {
    $options{f_show} = 1;
  }

  # パスワードファイルチェック
  die "[error] no loggin information\n" if ! defined $USER || ! defined $PASS;

  # ファイル一覧表示
  if ( $options{f_show} ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリ指定チェック
    show($dir, \%options);
  }

  # アップロード
  if ( $options{f_upload} ) {
    my $dir = shift @args // die "specify the upload dir"; # ディレクトリ指定チェック
    die "no input file\n" if scalar @args == 0;            # ファイル指定チェック
    for my $file ( @args ) {                               # ファイル存在チェック
      die "file '$file' does not exist.\n" if not -f $file;
    }
    upload($dir, \@args, \%options);
  }

  # ダウンロード
  if ( $options{f_download} && !$options{f_recursive} ) {
    die "specify the donwload file" if scalar @args == 0;  # ファイル指定チェック
    for my $file ( @args ) {
      download($file, \%options);
    }
  }

  # zip ダウンロード
  if ( $options{f_download} && $options{f_recursive} ) {
    my $dir = shift @args // die "specify the donwload dir"; # ディレクトリ指定チェック
    download_zip($dir, \%options);
  }
}->();


sub check_error_in_res {
  my ($res, $options) = @_;

  # レスポンスチェック
  die "no response from server\n" if not defined $res;

  # アクセスチェック
  die $res->content if $res->content =~ /Can't connect to/;

  # 認証チェック
  die $res->content if $res->content =~ /このページを見るのには許可が必要です/;

  # HTTP のレスポンスを表示 (-v)
  say $res->content if $options->{f_verbose};

  # ディレクトリエラーチェック
  if ( $res->content =~ /invalid dir\((?<dir>.*?)\)/ ) {
    die "Invalid dir: $+{dir}\n"
  }
}


sub show {
  my ($dir, $options) = @_;

  # HTTP リクエストを作って投げる
  my $req = HTTP::Request->new(GET => "${URL}?D=archives&dir=${dir}&sortby=filename");
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # HTTP レスポンスからエラーチェック
  check_error_in_res($res, $options);

  # リスト出力
  show_parse_res($res->content, $options);
};


sub show_parse_res {
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
    Content_Type => 'multipart/form-data',
    Content      => $content
  );
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # HTTP レスポンスからエラーチェック
  check_error_in_res($res, $options);

  # ファイル一覧出力
  my @files = $res->content =~ /uploaded '(.*?)'/g;
  say "uploaded the files to archive/$dir";
  say join "\n", (map { "- $_"  } @files);
};


sub download {
  my ($path, $options) = @_;

  my $dir      = path($path)->parent->stringify;
  my $filename = path($path)->basename;

  # HTTP リクエストを作って投げる
  my $req = HTTP::Request->new(
    GET => "${URL}?D=archives&dir=${dir}&act_download=1&filename=${filename}"
  );
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # HTTP レスポンスからエラーチェック
  check_error_in_res($res, $options);

  # 出力
  $filename = $options->{output} if $options->{output};
  path($filename)->spew($res->content);
  say 'saved ' . path($filename)->absolute->stringify;
};


sub download_zip {
  my ($dir, $options) = @_;
  $dir =~ s|/$||;                  # パスの最後に / があると空のファイルが返ってくる

  # POST メソッドで送る content
  my $content = [
    D                => 'archives',
    dir              => $dir,
    act_download_zip => 'download all in zip',
  ];

  # HTTP リクエストを作って投げる
  my $req = POST(
    "${URL}?D=archives&dir=${dir}",
    Content_Type => 'application/x-www-form-urlencoded',
    Content      => $content
  );

  # 認証情報をつける
  $req->authorization_basic($USER, $PASS);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  # HTTP レスポンスからエラーチェック
  check_error_in_res($res, $options);

  # 出力パスの決定
  my $path;
  if ( $options->{output} ) {
    $path = path($options->{output}); # 出力ファイル名の指定があればそれを使う
  }
  else {
    my $t = localtime;                  # Time::Piece オブジェクト
    my $filename = $dir=~ s|/|_|gr;     # ファイル名に / は使えないので _ に置換
    $path = path($t->date . "_archive_${filename}.zip");
  }

  # ファイル出力
  $path->spew($res->content);
  say 'saved ' . path($path)->absolute->stringify;
};
