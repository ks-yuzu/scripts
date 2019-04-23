#!/usr/bin/zsh

local I=$1
local L=$2

mkdir I${I}L${L} && cd $_

ilpbind.pl -c25 -i1 -l1 -M s2m.dp.pl -m MLDV_MUL+1 s2m.sch  
bndeval.pl s2m.bnd 2>&1 | grep '^TOTAL'

acap.pl -Z1 -M s2m.dp.pl s2m.bnd
