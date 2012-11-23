#!/usr/bin/perl
# Author      : Jesus Gimenez
# Date        : August 7, 2006
# Description : SVM-based sequential learner.
#
# Usage: SVMTlearn [options] config-file
#
# --------------------------------------------------------------------------
# ------------------------------------------------------------------------

#Copyright (C) 2004-2006 Jesus Gimenez and Lluis Marquez

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# ------------------------------------------------------------------------

use strict;
use IO;
use Benchmark;
use Data::Dumper;
use SVMTool::DICTIONARY;
use SVMTool::SVMTAGGER;
use SVMTool::COMMON;

sub get_out
{
     $0 =~ /\/([^\/]*$)/;
     print STDERR "Usage : ", $1, " [options] <config-file>\n\n";
     print STDERR "options:\n";
     print STDERR "  - V <verbose> -> 0: none verbose\n";
     print STDERR "                   1: low verbose [default]\n";
     print STDERR "                   2: medium verbose\n";
     print STDERR "                   3: high verbose\n";
     print STDERR "\nExample : $1 -V 2 config.svmt\n\n";
     exit;
}

# -- main program --
my $NARG = 1;

# check number of argments
my $ARGLEN = scalar(@ARGV);
if ($ARGLEN < $NARG) { get_out(); }

my $verbose = 1;
my $config;

my $ARGOK = 0;
my $i = 0;
my $stop = 0;
while (($i < $ARGLEN) and (!$stop)) {
   my $opt = shift(@ARGV);
   if (($opt eq "-V") or ($opt eq "-v")) { $verbose = shift(@ARGV) + 0; }
   else {
      if ($opt ne "") { $config = $opt; $ARGOK = 1; $stop = 1; }
   }
   $i++;
}

if (!($ARGOK)) { get_out(); }

# ======================================================================================
# ================================= MAIN PROGRAM =======================================
# ======================================================================================

# ======================================================================================
#READING CONFIGURATION FILE
my $CONFIG = SVMTAGGER::read_config_file($config);
my $set = $CONFIG->{set};
my $trainset = $CONFIG->{trainset};
my $valset = $CONFIG->{valset};
my $testset = $CONFIG->{testset};
my $model = $CONFIG->{model};
#if ($model =~ /.*\/.*/) { $model =~ s/.*\///g; }

# ======================================================================================
#RANDOMIZE SET (SPLITTING INTO TRAINING:VALIDATION:TEST)
if ((exists($CONFIG->{set})) and ((!exists($CONFIG->{trainset})) or (!exists($CONFIG->{testset})) or (!exists($CONFIG->{valset})))) {
   $trainset = $model.".".$COMMON::trainext;               #TRAINING SET   (out)
   $valset = $model.".".$COMMON::valext;                   #VALIDATION SET (out)
   $testset = $model.".".$COMMON::testext;                 #TEST SET       (out)
   SVMTAGGER::randomize_sentences($set, $trainset, $valset, $testset, $CONFIG->{TRAINP}, $CONFIG->{VALP}, $CONFIG->{TESTP});
   $CONFIG->{trainset} = $trainset;
   $CONFIG->{valset} = $valset;
   $CONFIG->{testset} = $testset;
}

# ======================================================================================
#REPORT FILE
my $reportfile = $model.".".$COMMON::EXPEXT;                     #REPORT FILE
if ($verbose > 0) {
   COMMON::report($reportfile, "----------------------------------------------------------------------------------------\n$COMMON::appname v$COMMON::appversion\n(C) $COMMON::appyear TALP RESEARCH CENTER.\nWritten by Jesus Gimenez and Lluis Marquez.\n----------------------------------------------------------------------------------------\n");
   if ($CONFIG->{set} ne "") { COMMON::report($reportfile, "SET = ".$CONFIG->{set}."\n"); }
   if ($CONFIG->{trainset} ne "") { COMMON::report($reportfile, "TRAINING SET = ".$CONFIG->{trainset}."\n"); }
   if ($CONFIG->{valset} ne "") { COMMON::report($reportfile, "VALIDATION SET = ".$CONFIG->{valset}."\n"); }
   if ($CONFIG->{testset} ne "") { COMMON::report($reportfile, "TEST SET = ".$CONFIG->{testset}."\n"); }
   COMMON::report($reportfile, "----------------------------------------------------------------------------------------\n----------------------------------------------------------------------------------------\n\n");
}

if ($verbose > $COMMON::verbose2) { print Dumper ($CONFIG), "\n"; }

# ======================================================================================
#DICTIONARY CREATION
my $dict = $model.".".$COMMON::DICTEXT;                          #DICTIONARY
my $supervised = SVMTAGGER::create_dictionary($CONFIG->{trainset}, $CONFIG->{LEX}, $CONFIG->{BLEX}, $CONFIG->{R}, $CONFIG->{Dratio}, $dict, $reportfile, $verbose);

# ======================================================================================

COMMON::write_list($CONFIG->{A0k}, $model.".".$COMMON::A0EXT);
COMMON::write_list($CONFIG->{A1k}, $model.".".$COMMON::A1EXT);
COMMON::write_list($CONFIG->{A2k}, $model.".".$COMMON::A2EXT);
COMMON::write_list($CONFIG->{A3k}, $model.".".$COMMON::A3EXT);
COMMON::write_list($CONFIG->{A4k}, $model.".".$COMMON::A4EXT);
COMMON::write_list($CONFIG->{A0u}, $model.".".$COMMON::A0EXT.".".$COMMON::unkext);
COMMON::write_list($CONFIG->{A1u}, $model.".".$COMMON::A1EXT.".".$COMMON::unkext);
COMMON::write_list($CONFIG->{A2u}, $model.".".$COMMON::A2EXT.".".$COMMON::unkext);
COMMON::write_list($CONFIG->{A3u}, $model.".".$COMMON::A3EXT.".".$COMMON::unkext);
COMMON::write_list($CONFIG->{A4u}, $model.".".$COMMON::A4EXT.".".$COMMON::unkext);
my @winsetup = ($CONFIG->{wlen}, $CONFIG->{wcore});
COMMON::write_list(\@winsetup, $model.".".$COMMON::WINEXT);

# ======================================================================================

my $rdict;
#FINDING/WRITING AMBP & UNKP
if (!(exists($CONFIG->{AP}))) { $CONFIG->{AP} = DICTIONARY::find_ambp($dict); }
if (!(exists($CONFIG->{UP}))) { $CONFIG->{UP} = DICTIONARY::find_unkp($dict); }
COMMON::write_list($CONFIG->{AP}, $model.".".$COMMON::AMBPEXT);
COMMON::write_list($CONFIG->{UP}, $model.".".$COMMON::UNKPEXT);
$rdict = new DICTIONARY($dict, $model.".".$COMMON::AMBPEXT, $model.".".$COMMON::UNKPEXT);
if ($verbose > 0) { COMMON::report($reportfile, "DICTIONARY <$dict> [".$rdict->get_nwords." words]\n"); }

# ======================================================================================

# -------------------------------------------------------------------------------------------
my $time1 = new Benchmark;
# -------------------------------------------------------------------------------------------

#PROCESSING ACTION ITEMS
if (scalar(@{$CONFIG->{do}}) != 0) {
   foreach my $action (@{$CONFIG->{do}}) {
      my @command = split(/:/, $action);
      my $CKTopt = "";
      my $CUTopt = "";
      my $Topt = ""; #default [-> no test]
      if ($command[2] =~ /^CK;/) { $CKTopt = $command[2]; }
      elsif ($command[2] =~ /^CU;/) { $CUTopt = $command[2]; }
      elsif ($command[2] =~ /^T/) { $Topt = $command[2]; }
      if ($command[3] =~ /^CK;/) { $CKTopt = $command[3]; }
      elsif ($command[3] =~ /^CU;/) { $CUTopt = $command[3]; }
      elsif ($command[3] =~ /T/) { $Topt = $command[3]; }
      if ($command[4] =~ /^CK;/) { $CKTopt = $command[4]; }
      elsif ($command[4] =~ /^CU;/) { $CUTopt = $command[4]; }
      elsif ($command[4] =~ /T/) { $Topt = $command[4]; }
      SVMTAGGER::SVMT_learn($CONFIG, $command[0], $command[1], $CKTopt, $CUTopt, $Topt, $rdict, $supervised, $reportfile, $verbose);
   }
}
else { print STDERR "[WARNING] NO ACTION ITEMS TO PROCESS!!\n"; }

# -------------------------------------------------------------------------------------------
my $time2 = new Benchmark;
# -------------------------------------------------------------------------------------------
if ($verbose > 0) {
   COMMON::print_benchmark($time1, $time2, $reportfile);
   print "\nTERMINATION... [DONE]\n";
}


