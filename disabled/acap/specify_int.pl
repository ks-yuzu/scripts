#!/usr/bin/env perl
use v5.20;
use warnings;
use diagnostics;
use Path::Class;

my @system_int_functions_name = qw/
_ccap_interrupt
interrupt_call_end
run_exc_handler
run_syscall_handler
int_prohibition_func
/;


# ファイル名取得
my $OUT_FILENAME       = shift // die "perl [thisfile].pl [outfile] [int_funcs_list_file]\n";
my $INT_FUNCS_FILENAME = shift // die "perl [thisfile].pl [outfile] [int_funcs_list_file]\n";


# ファイル読み込み
my $out_code                = (file $OUT_FILENAME      )->slurp();
my @user_int_functions_name = (file $INT_FUNCS_FILENAME)->slurp(chomp => 1);


# 重複する関数名を削除
my %appeared;
my @int_functions_name =
    grep {!$appeared{$_}++} (@system_int_functions_name, @user_int_functions_name);


# .out のコードに #int_module を指定
my $MODULE_NAME = 'int_module';
for( @int_functions_name ) {
    # メッセージ出力
    say "  Specify " . (sprintf '%-25s', "'$_'") . " as a function in '$MODULE_NAME'.";

    # 次の行に '#int_module' を追加
    die "[ERROR] Not found a function '$_'.  "
        unless $out_code =~ s/([^\n]*)<$_>:/$&\n#$MODULE_NAME/;
}


# 書き出し
## ファイル名生成
(my $OUT_FILENAME_MODIFIED = $OUT_FILENAME) =~ s/^(.*)\.out$/$1_int.out/;

## ファイルを開いて書きこみ
my $writer = (file $OUT_FILENAME_MODIFIED)->open('w');
$writer->print($out_code);
$writer->close;
