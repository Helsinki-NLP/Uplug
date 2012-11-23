#!/usr/bin/perl
# Author      : Jesus Gimenez
# Date        : November 30, 2009
# Description : SVMTagger HTTP server.
#
# Usage: SVMTagger_http_server [options]
#
# ------------------------------------------------------------------------
# ------------------------------------------------------------------------

#Copyright (C) 2009 Jesus Gimenez and Lluis Marquez

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
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Headers::Util qw(split_header_words);
use URI;
#use URI::Split qw(uri_split uri_join);
use URI::QueryParam;
use Data::Dumper;
#use TOK::engtok; 
#use TOK::Tokenizer;
use SVMTool::SVMTAGGER;
use SVMTool::COMMON;
use Getopt::Long;

my $URL = 'localhost';
my $PORT = 26080;
my $MODE = 0;            #mode (tagging strategy)
my $DIRECTION = 'LR';    #direction

sub svmtool_start($$$$) {
    #description _ initializes the SVMTool with the model in the given location
    #param1  _ model location
    #param2  _ mode      [0..6]
    #param3  _ direction [LR|RL|LRL]
    #param4  _ verbosity (0/1)
    #@return _ SVMTool model structure (hash reference)

    my $model_path = shift;
    my $mode = shift;
    my $direction = shift;
    my $verbose = shift;

    my $model = undef;

    if ($verbose) { print STDERR "<[SVMT] initializating PoS-tagger [$model_path] ...>\n"; }

    return SVMTAGGER::SVMT_load($model_path, $mode, $direction, 0, 0, '', $verbose);
}

sub svmtool_tag($$$$$) {
    #description _ tags a given sentence
    #param1  _ SVMTool models (hash ref)
    #param2  _ mode      [0..6]
    #param3  _ direction [LR|RL|LRL]
    #param4  _ input sentence
    #param5  _ verbosity (0/1)

    my $SVMTool = shift;
    my $mode = shift;
    my $direction = shift;
    my $input = shift;
    my $verbose = shift;

    my $NBEAMS = -1;         #beam count cutoff (only applicable under strategy 3)
    my $BRATIO = 0;          #beam count cutoff (only applicable under strategy 3)
    my $SOFTMAX = 1;         #softmax function
    
    my @tokens = split(" ", $input);
    my $in = SVMTAGGER::SVMT_prepare_input(\@tokens);
    my ($out, $time) = SVMTAGGER::SVMT_tag($mode, $NBEAMS, $BRATIO, $SOFTMAX, $direction, $in, $SVMTool, $verbose);

    my $i = 0;
    my @in;
    my @out;
    while ($i < scalar(@{$in})) {
        my $token = $in->[$i]->get_word();
        my $pos = $out->[$i]->get_pos();
        push(@in, $token);
        push(@out, $pos);
        $i++;
    }

    return (\@in, \@out);
}

sub svmtool_respond($$$$$) {
    #description _ buils HTTP response
    #param1  _ SVMTool models (hash ref)
    #param2  _ mode      [0..6]
    #param3  _ direction [LR|RL|LRL]
    #param4  _ input sentence
    #param5  _ verbosity (0/1)

    my $SVMTool = shift;
    my $mode = shift;
    my $direction = shift;
    my $input = shift;
    my $verbose = shift;

    my ($in, $out) = svmtool_tag($SVMTool, $mode, $direction, $input, $verbose);
 
    if ($verbose) {
       my $i = 0;
       while (($i < scalar(@{$in})) and ($i < scalar(@{$out})))  {
          print STDOUT $in->[$i], "\t", $out->[$i], "\n";
          $i++;
       }
    }
   
    return join(" ", @{$out});
}

sub get_out {
   $0 =~ /\/([^\/]*$)/;
   print STDERR "Usage : ", $1, " [options] <model>\n\n";
   print STDERR "options:\n";
   print STDERR "  - url        URL (default $URL)\n";
   print STDERR "  - port       port number (default $PORT)\n";
   print STDERR "  - s  <strategy>\n";
   print STDERR "            $COMMON::st0: one-pass   (default - requires model $COMMON::mode0)\n";
   print STDERR "            $COMMON::st1: two-passes [revisiting results and relabeling - requires model $COMMON::mode2 and model $COMMON::mode1]\n";
   print STDERR "            $COMMON::st2: one-pass   [robust against unknown words - requires model $COMMON::mode0 and model $COMMON::mode2]\n";
   print STDERR "            $COMMON::st3: one-pass   [unsupervised learning models - requires model $COMMON::mode3]\n";
   print STDERR "            $COMMON::st4: one-pass   [very robust against unknown words - requires model $COMMON::mode4]\n";
   print STDERR "            $COMMON::st5: one-pass   [sentence-level likelihood - requires model $COMMON::mode0]\n";
   print STDERR "            $COMMON::st6: one-pass   [robust sentence-level likelihood - requires model $COMMON::mode4]\n";
   print STDERR "  - d  <direction>\n";
   print STDERR "            $COMMON::lrmode: left-to-right (default)\n";
   print STDERR "            $COMMON::rlmode: right-to-left\n";
   print STDERR "           $COMMON::lrlmode: both left-to-right and right-to-left\n";
   print STDERR "          $COMMON::glrlmode: both left-to-right and right-to-left (global assignment, only applicable under a sentence level tagging strategy)\n";
   print STDERR "  - v          verbose\n";
   print STDERR "  - help!      this help\n";
   print STDERR "\nmodel:     model location (path/name) (name as declared in the config-file NAME)\n";
   print STDERR "\nExample : $1 -v -url $URL -port $PORT /home/me/svmtool/eng/WSJTP\n\n";
   exit(1)
}

# --------------------------------------------------------------------------------------------------------
# -- main program
# --------------------------------------------------------------------------------------------------------

# read options ------------------------------------------------------------------
my %options = ();
GetOptions(\%options, "url=s", "port=i", "s=s", "d=s", "v!", "help!");
if ($options{"help"}) { get_out(); }
my $verbose = $options{"v"};
my $url = $URL;
my $port = $PORT;
my $mode = $MODE;
my $direction = $DIRECTION;
if (defined($options{"url"})) { $url = $options{"url"}; }
if (defined($options{"port"})) { $port = $options{"port"}; }
if (defined($options{"s"})) { $mode = $options{"s"}; }
if (defined($options{"d"})) { $direction = $options{"d"}; }

# -- check number of argments
my $NARG = 1;
my $ARGLEN = scalar(@ARGV);
if ($ARGLEN < $NARG) { get_out(); }

my $svmt_dir = shift(@ARGV);
print "SVMT_DIR = $svmt_dir\n";

# start SVMTool -----------------------------------------------------------------
my $SVMTool = svmtool_start($svmt_dir, $mode, $direction, $verbose);

# start Daemon ------------------------------------------------------------------
my $d = new HTTP::Daemon(LocalAddr => $url, LocalPort => $port);
#print "Please contact me at: <URL:", $d->url, ">\n";
if ($verbose) { print STDERR "READY FOR TAGGING [http://$url:$port]\n"; }

# serve requests (forever) ------------------------------------------------------
while (my $c = $d->accept) {
   while (my $r = $c->get_request) {
      if ($r->method eq 'GET') {
         my $path = $r->url->path;
         my $uri = URI->new($r->uri);
         my $input = $uri->query_param('input');

         if ($input ne '') {
            chomp($input);
            if ($verbose) { print "TAGGING <$input>\n"; }
            my $response = svmtool_respond($SVMTool, $mode, $direction, $input, $verbose);
            $c->send_response($response);
         }
      }
      else { $c->send_error(RC_FORBIDDEN); }
   }
   $c->close;
   undef($c);
}
