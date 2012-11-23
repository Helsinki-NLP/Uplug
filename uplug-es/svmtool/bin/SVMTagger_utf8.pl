#!/usr/bin/perl
# Author      : Jesus Gimenez
# Date        : October 7, 2004
# Description : SVM-based sequential tagger.
#
# Usage: SVMTagger  [options]  model  <  stdin  > stdout
#
# ------------------------------------------------------------------------
# ------------------------------------------------------------------------

#Copyright (C) 2004 Jesus Gimenez and Lluis Marquez

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

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use strict;
use Benchmark;
use SVMTool::SVMTAGGER;
use SVMTool::COMMON;
use SVMTool::LEMMATIZER;
use SVMTool::ENTRY;

sub get_out
{
     $0 =~ /\/([^\/]*$)/;
     print STDERR "Usage : ", $1, " [options] <model>\n\n";
     print STDERR "options:\n";
     print STDERR "  - T <strategy>\n";
     print STDERR "            $COMMON::st0: one-pass   (default - requires model $COMMON::mode0)\n";
     print STDERR "            $COMMON::st1: two-passes [revisiting results and relabeling - requires model $COMMON::mode2 and model $COMMON::mode1]\n";
     print STDERR "            $COMMON::st2: one-pass   [robust against unknown words - requires model $COMMON::mode0 and model $COMMON::mode2]\n";
     print STDERR "            $COMMON::st3: one-pass   [unsupervised learning models - requires model $COMMON::mode3]\n";
     print STDERR "            $COMMON::st4: one-pass   [very robust against unknown words - requires model $COMMON::mode4]\n";
     print STDERR "            $COMMON::st5: one-pass   [sentence-level likelihood - requires model $COMMON::mode0]\n";
     print STDERR "            $COMMON::st6: one-pass   [robust sentence-level likelihood - requires model $COMMON::mode4]\n";
     print STDERR "  - S <direction>\n";
     print STDERR "            $COMMON::lrmode: left-to-right (default)\n";
     print STDERR "            $COMMON::rlmode: right-to-left\n";
     print STDERR "           $COMMON::lrlmode: both left-to-right and right-to-left\n";
     print STDERR "          $COMMON::glrlmode: both left-to-right and right-to-left (global assignment, only applicable under a sentence level tagging strategy)\n";
     print STDERR "  - K <n> weight filtering threshold for known words (default is 0)\n";
     print STDERR "  - U <n> weight filtering threshold for unknown words (default is 0)\n";
     print STDERR "  - Z <n> number of beams in beam search, only applicable under sentence-level strategies (default is disabled)\n";
     print STDERR "  - R <n> dynamic beam search ratio, only applicable under sentence-level strategies (default is disabled)\n";
     print STDERR "  - F <n> softmax function to transform SVM scores into probabilities (default is 1)\n";
     print STDERR "              0: do_nothing\n";
     print STDERR "              1: ln(e^score(i) / [sum:1<=j<=N:[e^score(j)]])\n";
     print STDERR "  - A     predicitons for all possible parts-of-speech are returned\n";
     print STDERR "  - B     <backup_lexicon>\n";
     print STDERR "  - L     <lemmae_lexicon>\n";
     print STDERR "  - EOS   enable usage of end_of_sentence '<s>' string (disabled by default, [!.?] used instead)\n";
     print STDERR "  - V     <verbose> -> 0: none verbose\n";
     print STDERR "                       1: low verbose\n";
     print STDERR "                       2: medium verbose\n";
     print STDERR "                       3: high verbose\n";
     print STDERR "                       4: very high verbose\n";
     print STDERR "\nmodel: model location (path/name) (name as declared in the config-file NAME)\n";
     print STDERR "\nExample : $1 -V 2 -S LRL -T 0 /home/me/svmtool/eng/WSJTP < wsj.test > wsj.test.out\n\n";
     exit;
}

# -- main program --
my $NARG = 1;

# check number of argments
my $ARGLEN = scalar(@ARGV);
if ($ARGLEN < $NARG) { get_out(); }

my $epsilon = 0;
my $omega = 0;
my $corpus;
my $S = $COMMON::lrmode;
my $T = $COMMON::st0;
my $B = "";
my $L = "";
my $A = 0;
my $Z = -1;
my $R = 0;
my $F = $COMMON::softmax1;
my $verbose = $COMMON::verbose0;
my $Stime = 0;
my $Ftime = 0;
my $Ctime = 0;
my $EOS = 0;

my $ARGOK = 0;
my $i = 0;
while (($i < $ARGLEN) and (!$ARGOK)) {
   my $opt = shift(@ARGV);
   if (($opt eq "-K") or ($opt eq "-k")) { $epsilon = shift(@ARGV); }
   elsif (($opt eq "-U") or ($opt eq "-u")) { $omega = shift(@ARGV); }
   elsif (($opt eq "-S") or ($opt eq "-s")) { $S = shift(@ARGV); }
   elsif (($opt eq "-T") or ($opt eq "-t")) { $T = shift(@ARGV); }
   elsif (($opt eq "-B") or ($opt eq "-b")) { $B = shift(@ARGV); }
   elsif (($opt eq "-L") or ($opt eq "-l")) { $L = shift(@ARGV); }
   elsif (($opt eq "-Z") or ($opt eq "-z")) { $Z = shift(@ARGV); }
   elsif (($opt eq "-R") or ($opt eq "-r")) { $R = shift(@ARGV); }
   elsif (($opt eq "-F") or ($opt eq "-f")) { $F = shift(@ARGV); }
   elsif (($opt eq "-V") or ($opt eq "-v")) { $verbose = shift(@ARGV); }
   elsif (($opt eq "-A") or ($opt eq "-a")) { $A = 1; }
   elsif (($opt eq "-EOS") or ($opt eq "-eos")) { $EOS = 1; }
   else {
      if ($opt ne "") { $corpus = $opt; $ARGOK = 1; }
   }
   $i++;
}

if (!($ARGOK)) { get_out(); }

# ================================================================================================

  if ($verbose) {
     print STDERR "----------------------------------------------------------------------------------------\n$COMMON::appname v$COMMON::appversion\n(C) $COMMON::appyear TALP RESEARCH CENTER.\nWritten by Jesus Gimenez and Lluis Marquez.\n----------------------------------------------------------------------------------------\n";
     print STDERR "MODEL = $corpus\n";
     print STDERR "T = $T ";
     print STDERR (($T == $COMMON::st5) || ($T == $COMMON::st6))? "(Z = $Z, R = $R)": "";
     print STDERR ((($T == $COMMON::st5) || ($T == $COMMON::st6)) || ($S eq $COMMON::lrlmode))? "(F = $F) ": "";
     print STDERR ":: S = $S :: K = $epsilon :: U = $omega\n";
     if ($B ne "") { print STDERR "B = $B\n"; }
     if ($L ne "") { print STDERR "L = $L\n"; }
     print STDERR "----------------------------------------------------------------------------------------\n";
  }

  # ======================== LOADING SVMT MODEL ===============================================
  my $Stime1 = new Benchmark;
  my $M = SVMTAGGER::SVMT_load($corpus, $T, $S, $epsilon, $omega, $B, $verbose);
  my $Stime2 = new Benchmark;
  $Stime = COMMON::get_benchmark($Stime1,$Stime2);
  # ======================== LOADING LEMMATIZER ===============================================
  my $Ldict;
  if ($L ne "") {
     if ($verbose) { print STDERR "READING LEMMARY <$L>...\n"; }
     $Ldict = LEMMATIZER::LT_load($L, $verbose);
  }
  # =========================== POS-TAGGING ===================================================
  if ($verbose) {
     print STDERR "TAGGING < DIRECTION = ";
     if ($S eq $COMMON::lrmode) { print STDERR "left-to-right"; }
     elsif ($S eq $COMMON::rlmode) { print STDERR "right-to-left"; }
     elsif ($S eq $COMMON::lrlmode) { print STDERR "left-to-right then right-to-left"; }
     elsif ($S eq $COMMON::glrlmode) { print STDERR "left-to-right then right-to-left (global)"; }
     else { print STDERR "$S"; }
     print STDERR " >\n";
  }

  # -------------------------------------------------------------------------------------------
  my $time1 = new Benchmark;
  # -------------------------------------------------------------------------------------------
  my $s = 0;
  my $stop = 0;
  while (!$stop) {
     my $stdin;
     my $in;
     ($stdin, $in, $stop) = ENTRY::read_sentence_stdin($EOS);
     my ($out, $time) = SVMTAGGER::SVMT_tag($T, $Z, $R, $F, $S, $in, $M, $verbose);
     $Ftime += $time->[0];
     $Ctime += $time->[1];
     if (scalar(@{$stdin}) > 0) { $s++; }
     my $i = 0;
     my $iter = 0;
     while ($iter < scalar(@{$stdin})) {
        my @line = split($COMMON::in_valseparator, ${$stdin}[$iter]);
        if (($line[0] eq $COMMON::SMARK) and $EOS) {
	       print STDOUT $stdin->[$iter]."\n";
	    }
        elsif ((scalar(@line) == 0) or ($line[0] =~ /^$COMMON::IGNORE.*/)) {
	       print STDOUT $stdin->[$iter]."\n";
        }
        else {
           shift(@line);
           if ($A) {
	          my $pph = $out->[$i]->get_pp();
              foreach my $p (reverse sort {$a cmp $b} keys %{$pph}) {
                 unshift(@line, $p.$COMMON::innerseparator.$pph->{$p});
	          }
	       }
           unshift(@line, $out->[$i]->get_pos);
           if ($L ne "") {
	          unshift(@line, LEMMATIZER::LT_tag($Ldict, $in->[$i]->get_word, $out->[$i]->get_pos));
           }
           unshift(@line, $in->[$i]->get_word);
           print STDOUT join($COMMON::out_valseparator, @line)."\n";
           $i++;
        }
        $iter++;
     }
     if ($EOS and !$stop) { print STDOUT "$COMMON::SMARK\n"; }
     if ($verbose) { COMMON::show_progress($s, $COMMON::progress3, $COMMON::progress0); }
  }
  if ($verbose) { print STDERR ".", $s, " sentences [DONE]\n"; }
  # -------------------------------------------------------------------------------------------
  my $time2 = new Benchmark;
  # -------------------------------------------------------------------------------------------
  if ($verbose) {
     my $Ttime = COMMON::get_benchmark($time1, $time2);
     my $Ptime = $Ttime - $Ftime - $Ctime;
     my $Otime = $Stime + $Ttime;
     print STDERR "=============================================================================================\n";
     printf STDERR "      START-UP: %.4f secs\n", $Stime;
     print STDERR "=============================================================================================\n";
     printf STDERR "       TAGGING: %.4f secs\n", $Ttime;
     print STDERR "---------------------------------------------------------------------------------------------\n";
     printf STDERR "  F.EXTRACTION: %.4f secs\n", $Ftime;
     printf STDERR "           SVM: %.4f secs\n", $Ctime;
     printf STDERR "       PROCESS: %.4f secs\n", $Ptime;
     print STDERR "=============================================================================================\n";
     printf STDERR "OVERALL = START-UP + TAGGING = %.4f secs + %.4f secs = %.4f secs\n", $Stime, $Ttime, $Otime;
     print STDERR "=============================================================================================\n";
  }

# =================================================================================================

