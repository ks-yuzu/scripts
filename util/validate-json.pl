#!/usr/bin/env perl
use v5.24;
use warnings;
use diagnostics;

use Path::Tiny;
use JSON;
use JSON::Validator;

use DDP { deparse => 1, };

# file
my $file_json   = shift // die;
my $file_schema = shift // {type => "object"};

# validator
my $validator = JSON::Validator->new;
$validator->schema( $file_schema ) if $file_schema;

my $json = path( $file_json )->slurp();
my $json_h = from_json($json);
my @errors = $validator->validate( $json_h );

die @errors if @errors;

p $json_h;

