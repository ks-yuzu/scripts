#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;
use Path::Tiny;

use Getopt::Kingpin;
my $kingpin = Getopt::Kingpin->new();
my $f_sim          = $kingpin->flag('sim', 'generate simlation script')->default(0)->bool;
my $f_synth        = $kingpin->flag('synth', 'generate synthesis script')->default(0)->bool;
my $f_delete       = $kingpin->flag('delete', 'delete script')->short('d')->bool;
my $f_template_gen = $kingpin->flag('template', 'generate template')->short('t')->bool;
my $config_file    = $kingpin->arg('config-file', 'config file name')->string;

$kingpin->parse;


# 入力ファイルチェック
if ( ! $f_template_gen && ! $config_file ) {
  say '[Error] no input or option.';
  say '';
  say '1. generate a template of configuration';
  say '  $ ' . path( $0 )->basename . ' -t [filename]';
  say '';
  say '2. edit the configuration file';
  say '';
  say '3. generate script files for simulation and synth';
  say '  $ ' . path( $0 )->basename . ' [filename]';
  say '';

  exit(1);
}


# テンプレートファイル生成
if ( $f_template_gen ) {

  my $conf_template = <<EOF;
{
  # HW 設計ファイルの設定
  design_files      => [ 'sample.v', 'alu.v', 'LDST.v' ], # デザインファイル (verilog)
  top_module        => 'mips_hw',                         # トップモジュール名

  # シミュレーション用のファイルの設定
  simulation_files  => [ 'mips_hw_test.v' ],    # シミュレーション用ファイル
  testbench         => 'mips_hw_test',          # テストベンチのモジュール名

  # 基本的に以下は放置で OK
  # ワークスペース名？
  workspace         => 'work',

  # ターゲット
  target            => 'xc7a100tcsg324-3',

  # スクリプトファイル名
  sim_script_name   => 'run',
  synth_script_name => 'synth',
}
EOF

  path( $config_file || './vivado-script.conf' )->spew($conf_template);
  exit(0);
}


# config ファイルの読み込み
my $config = require $config_file;


# シミュレーション用設定
my $sim_script_name   = $config->{sim_script_name};
my $workspace         = $config->{workspace};
my @design_files      = @{ $config->{design_files} };
my $testbench         = $config->{testbench};

# 論理合成用設定
my $synth_script_name = $config->{synth_script_name};
my @simulation_files  = @{ $config->{simulation_files} };
my $top_module        = $config->{top_module};
my $target            = $config->{target};


# 生成したスクリプトの削除
if ( $f_delete ) {
  delete_sim_script()   if $f_sim   || (!$f_sim && !$f_synth);
  delete_synth_script() if $f_synth || (!$f_sim && !$f_synth);
} else {
  make_sim_script()   if $f_sim   || (!$f_sim && !$f_synth);
  make_synth_script() if $f_synth || (!$f_sim && !$f_synth);
}



# ========================= function =========================
sub delete_sim_script {
  path("${sim_script_name}.sh")->remove();
  path("${sim_script_name}.prj")->remove();
  path("${sim_script_name}.tcl")->remove();
}


sub delete_synth_script {
  path("${synth_script_name}.sh")->remove();
  path("${synth_script_name}.tcl")->remove();
}


sub make_synth_script {
  # sh ファイル生成
  my @sh = ();
  push @sh, "vivado -mode batch -nolog -nojournal -source ./${synth_script_name}.tcl\n";
  path("${synth_script_name}.sh")->spew(@sh);
  path("${synth_script_name}.sh")->chmod(0775);

  # tcl ファイル生成
  my @tcl = ();
  push @tcl, "read_verilog " . (join ' ', @design_files) . "\n";
  push @tcl, "synth_design -top ${top_module} -part ${target}\n";
  push @tcl, "report_utilization               -file report_utilization.txt\n";
  push @tcl, "report_utilization -hierarchical -file report_utilization-hierarchical.txt\n";
  push @tcl, "report_timing_summary -file report_timing.txt -report_unconstrained\n";
  path("${synth_script_name}.tcl")->spew(@tcl);

  my @parse = ();
  push @parse, "echo \n";
  push @parse, "echo \n";
  push @parse, "echo -n 'FFs  : '\n";
  push @parse, q!grep 'Register as Flip Flop' report_utilization.txt | perl -nE '/\D+?(\d+)/ && say $1'! . "\n";
  push @parse, "echo -n 'LUTs : '\n";
  push @parse, q!grep 'Slice LUTs' report_utilization.txt | perl -nE '/\D+?(\d+)/ && say $1'! . "\n";
  push @parse, "echo -n 'Delay: '\n";
  push @parse, q!grep -A 10 'Max Delay Paths' report_timing.txt | perl -nE '/Data Path Delay:\s*(.*?ns)/ && say $1'!;

  path("parse-report.sh")->spew(@parse);
  path("parse-report.sh")->chmod(0775);
}


sub make_sim_script {
  # sh ファイル生成
  my @sh = ();
  push @sh, "rm -rf xsim.dir/${workspace}\n\n";
  push @sh, "xelab ${workspace}.${testbench} --prj ${sim_script_name}.prj -s ${workspace} -timescale '1ns/1ns' -nolog\n";
  push @sh, "xsim --noieeewarnings ${workspace} -tclbatch ${sim_script_name}.tcl -nolog\n\n";
  push @sh, "rm -f webtalk*.jou webtalk*.log xsim*.jou\n";
  path("${sim_script_name}.sh")->spew(@sh);
  path("${sim_script_name}.sh")->chmod(0775);

  # prg ファイル生成
  my @prg = ();
  push @prg, qq/verilog ${workspace} "$_"\n/ for @design_files;
  push @prg, qq/verilog ${workspace} "$_"\n/ for @simulation_files;
  path("${sim_script_name}.prj")->spew(@prg);

  # tcl ファイル生成
  my @tcl = ();
  push @tcl, "run all\n";
  push @tcl, "quit\n";
  path("${sim_script_name}.tcl")->spew(@tcl);
}

