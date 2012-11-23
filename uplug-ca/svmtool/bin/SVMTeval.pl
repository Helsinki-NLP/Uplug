#!/usr/bin/perl
# Author      : Jesus Gimenez
# Date        : August 7, 2006
# Description : SVMTool evaluation tool.
#
# Usage: SVMTeval  [mode]   <model>   <corpus.gold>   <corpus.predicted>
#
# ------------------------------------------------------------------------
# ------------------------------------------------------------------------

#Copyright (C) 2004-2006 Jesus Gimenez and Lluis Marquez

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# ------------------------------------------------------------------------

use strict;
use SVMTool::SVMTAGGER;

# constant values

# -- main program --
my $NARG = 3;

# ======================================================================================
# ================================= MAIN PROGRAM =======================================
# ======================================================================================

# check number of argments
my $ARGLEN = scalar(@ARGV);
if ($ARGLEN < $NARG) { 
  $0 =~ /\/([^\/]*$)/;
  print "Usage : ", $1, " [mode] <model> <gold> <pred>\n\n";
  print "      - mode:  0 - complete report (everything)\n";
  print "               1 - overall accuracy only [default]\n";
  print "               2 - accuracy of known vs unknown words\n";
  print "               3 - accuracy per level of ambiguity\n";
  print "               4 - accuracy per kind of ambiguity\n";
  print "               5 - accuracy per part of speech\n";
  print "      - model: model location (path + name)\n";
  print "      - gold:  correct tagging file\n";
  print "      - pred:  predicted tagging file\n";
  print "\nExample : $1 WSJTP wsjtp.gold wsjtp.tagged\n\n";
  exit;
}

my $mode = 1;
if ($ARGLEN == 4) { $mode = shift(@ARGV); }
my $model = shift(@ARGV);
my $input = shift(@ARGV);
my $output = shift(@ARGV);
my $verbose = 0;

# =========================================================================================

if ($verbose) {
   print STDERR "----------------------------------------------------------------------------------------\n$COMMON::appname v$COMMON::appversion\n(C) $COMMON::appyear TALP RESEARCH CENTER.\nWritten by Jesus Gimenez and Lluis Marquez.\n----------------------------------------------------------------------------------------\n";
}

if ($mode == -1) { SVMTAGGER::SVMT_brief_eval($model, $input, $output, 0); }
else { SVMTAGGER::SVMT_deep_eval($model, $input, $output, $mode, 3); }

# =========================================================================================

