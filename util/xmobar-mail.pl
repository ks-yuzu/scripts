#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use Net::IMAP::Client;

use utf8;
use open IO => qw/:encoding(UTF-8) :std/;
use Encode qw(decode);

# 接続情報を設定
my $imap = Net::IMAP::Client->new(
  # server => 'webmail.kwansei.ac.jp',
  server => 'outlook.office365.com',
  user   => 'fwm83185@nuc.kwansei.ac.jp',
  pass   => 'Pm4emKbh',
  ssl    => 1,
  port   => 993
) // (print "📨 -/-" and exit);

# 接続
$imap->login || die $imap->last_error;

# 操作対象のフォルダを選択
$imap->select('INBOX') || die $!;

my $inbox = $imap->status('INBOX');
printf "📨 %d/%d", $inbox->{UNSEEN}, $inbox->{MESSAGES};
