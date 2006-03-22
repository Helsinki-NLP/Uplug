#!/usr/bin/perl
# -*-perl-*-
#
# split.pl: split text into segments/tokens
#
#---------------------------------------------------------------------------
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---------------------------------------------------------------------------
#
# $Id$
#
# usage: split.pl <infile >outfile
#        split.pl [-i configfile] [-in infile] [-out outfile] [-s system]
#        split.pl [-i configfile] [-s system] <infile >outfile
#
# configfile  : configuration file
# infile      : input file
# outfile     : output file
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
# 
# 
#

use strict;

use FindBin qw($Bin);
use lib "$Bin/..";
# use utf8;

use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='Tokenize.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=           # take only 
    each %{$IniData{'input'}};                # the first input stream
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $input=Uplug::IO::Any->new($InputStream);
my $output=Uplug::IO::Any->new($OutputStream);

#---------------------------------------------------------------------------

$input->open('read',$InputStream);
my $header=$input->header;
$output->addheader($header);
#$output->addheader($InputStream);
$output->open('write',$OutputStream);

#---------------------------------------------------------------------------

my $DefDel=$IniData{parameter}{segments}{delimiter};
if (not defined $DefDel){$DefDel="\x00b\xx";}
my $SegTag=$IniData{parameter}{segments}{tag};
my $AddId=$IniData{parameter}{segments}{'add IDs'};
my $AddSpans=$IniData{parameter}{segments}{'add spans'};
my $KeepSpaces=$IniData{parameter}{segments}{'keep spaces'};
my $AddParId=$IniData{parameter}{segments}{'add parent id'};
my $verbose=$IniData{parameter}{runtime}{verbose};

my $ExcWordDel=qr/$IniData{parameter}{'word delimiter'}{'exceptions'}/;

my @SplitRE;
if (ref($IniData{parameter}{'split pattern'}) eq 'ARRAY'){
    @SplitRE=@{$IniData{parameter}{'split pattern'}};
}
elsif (ref($IniData{parameter}{'split pattern'}) eq 'HASH'){
    foreach (sort {$a <=> $b} keys %{$IniData{parameter}{'split pattern'}}){
	push (@SplitRE,$IniData{parameter}{'split pattern'}{$_});
    }
}
else{
    @SplitRE=($IniData{parameter}{'split pattern'});
}

my @ExcRE;
my %ExcVar;
# $ExcVar{'\x00\x000\x00\x00'}='\x00';

my $count=0;
if (ref($IniData{parameter}{exceptions}) eq 'HASH'){
    foreach (keys %{$IniData{parameter}{exceptions}}){
	my $pat=quotemeta($_);
	$ExcRE[$count]=$pat;
	$ExcVar{$count}=$_;
	$count++;
    }
}

my @InitialRE;
my @InitialSubst;

if (ref($IniData{parameter}{substitutions}) eq 'HASH'){
    foreach (keys %{$IniData{parameter}{substitutions}}){
	push (@InitialRE,$_);
	push (@InitialSubst,$IniData{parameter}{substitutions}{$_});
    }
}

my @FinalRE;
my @FinalSubst;

if (ref($IniData{parameter}{'final substitutions'}) eq 'HASH'){
    foreach (keys %{$IniData{parameter}{'final substitutions'}}){
	push (@FinalRE,$_);
	push (@FinalSubst,$IniData{parameter}{'final substitutions'}{$_});
    }
}

map ($_=qr/$_/,@SplitRE);            # compile regular expressions
map ($_=qr/$_/,@InitialRE);          # --> makes it faster (hopefully)
# map ($_=qr/$_/,@FinalRE);          # don't compile to enable '\1' (tokenize)
map ($_=qr/$_/,@ExcRE);


#---------------------------------------------------------------------------

if ($KeepSpaces){$input->keepSpaces();}
my $data=Uplug::Data->new();
my $count=0;

while ($input->read($data)){
    $count++;
    if ($verbose){
	if (not ($count % 1000)){
	    print STDERR "$count\n";
	}
	if (not ($count % 100)){
	    print STDERR '.';
	}
    }
    &split($data);
    $output->write($data);
}
# $output->write(\%data);

$input->close;
$output->close;

my $parId;
my $id;
my $idhead;
sub split{
    my $data=shift;
    my %subst=();

    my @text=();
    my @attr=();
    my @nodes=$data->findNodes($SegTag);
    if (@nodes){return;}                     # data are already segmented!!!!

    my @spans=();
    my $text=$data->content();
    my @seg=&SplitText($text,\@spans);
    @seg=&SplitText($text,\@spans);
    if (not @seg){return;}

    &RemoveEmptyNodes(\@seg,\@spans);
    my $root=$data->root();
    my @children=$data->splitContent($root,$SegTag,\@seg);

    #-------------------------------------------------------
    if ($AddParId){                        # add parent id's
	$idhead=$data->attribute('id');
	if ($idhead=~/^[^0-9]([0-9].*)$/){
	    $idhead=$1;
	}
	if (not defined $idhead){
	    $parId++;
	    $idhead=$parId;
	    $data->setAttribute('id',$parId);
	}
	$idhead.='.';
	$id=0;
    }
    #-------------------------------------------------------
    if ($AddId or $AddSpans){              # add id's and spans
	foreach my $c (0..$#children){
		if (not ref($children[$c])){next;}
	    if ($AddId){
		$id++;
		$data->setAttribute($children[$c],
				    'id',"$SegTag$idhead$id");
	    }
	    if ($AddSpans){
		$data->setAttribute($children[$c],'span',$spans[$c]);
	    }
	}
    }
}



sub RemoveEmptyNodes{
    my ($string,$span)=@_;
    my $i=0;
    while ($i<=$#{$string}){
	if ($string->[$i]=~/\S/){$i++;}
	else{
	    splice (@{$string},$i,1);
	    splice (@{$span},$i,1);
	}
    }
}

#----------------------------------------------------------------
# SplitText: split a text into segments!

sub SplitText{
    my $text=shift;
    my $spans=shift;

    $text=~s/^\s*//;                        # remove initial whitespaces (hack)
    my $OriginalText=$text;

    #------------------------
    # \x00 is used as a special character!
    # --> escape \x00-characters

    $text=~s/\x00/\x00v\x00/gs;

    #------------------------
    # make initial replacements

    foreach (0..$#InitialRE){
	eval "\$text=~s/\$InitialRE[$_]/$InitialSubst[$_]/gs";
    }

    #------------------------
    # exclude certain strings
    # --> replace with place-holder

    foreach (0..$#ExcRE){
	$text=~s/($ExcWordDel)$ExcRE[$_]/$1\x00$_\x00/gs;   # exclude these!
    }

    #------------------------
    # apply split pattersn
    # --> split positions are marked with parameter->segments->delimiter

    foreach (@SplitRE){
	$text=~s/$_/$1$DefDel$2/gs;
#	eval { $text=~s/$_/$1\x00b~$2/gs; };
#	if ($@){print STDERR $@;}
    }
    foreach (0..$#FinalRE){
	eval "\$text=~s/\$FinalRE[$_]/$FinalSubst[$_]/gs";
    }

    #------------------------
    # replace place-holders with original strings

    $text=~s/\x00([0-9]+)\x00/$ExcVar{$1}/gs;

    my @chunks;
    my @chunks=split(/$DefDel/,$text);     # split at marked places
    map (s/\x00v\x00/\x00/gs,@chunks);     # restore escaped \x00-characters

    #------------------------
    # compute byte-spans for splitted segments in the string

    if (ref($spans) eq 'ARRAY'){
	my $offset=0;
	foreach (0..$#chunks){
	    $offset=index $OriginalText,$chunks[$_],$offset;
	    $$spans[$_]=$offset.':'.length($chunks[$_]);
	}
    }
    return @chunks;
}


############################################################################


sub GetDefaultIni{

    my $DefaultIni = {
	'encoding' => 'iso-8859-1',
	'module' => {
	    'name' => 'tokenizer',
	    'program' => 'split.pl',
	    'location' => '$UplugBin',
	    'stdin' => 'text',
	    'stdout' => 'text',
	},
	'description' => 
'This module is a simple tokenizer which splits
sentences into tokens. It uses simple regular expressions for
matching common word boundaries. Do not expect this to work
correctly in all cases and for all languages.',
        'input' => {
	    'text' => {
		'format' => 'xml',
	    }
	},
	'output' => {
	    'text' => {
		'format' => 'xml',
		'write_mode' => 'overwrite',
#		'encoding' => 'iso-8859-1',
		'status' => 'tok',
	    }
	},
	'parameter' => {
	    'segments' => {
		'tag' => 'w',
		'add IDs' => 1,
#		'add spans' => 1,
		'add parent id' => 1,
#		'keep spaces' => 1,
		'delimiter' => ' ',    # default delimiter used when splitting
	    },
	    'split pattern' => {

        # \\p{P} ==> punctuations
        # \\P{P} ==> non-punctuations

        10 => '(\P{P})(\p{P}[\p{P}\s]|\p{P}\Z)',# non-P + P + (P or \s or \Z)
	20 => '(\A\p{P}|[\p{P}\s]\p{P})(\P{P})',# (\A or P or \s) + P + non-P
	40 => '(``)(\S)',                       # special treatment for ``

	# the following split punctuations that are surrounded by \s
	# (\A or \s) + P + P + (\s or \Z)
	# do it 4 times (quite arbitrary ... should be changed ...)

	50 => '(\A[\p{P}]+|\s[\p{P}]+)([\p{P}]+\s|[\p{P}]+\Z)',
	60 => '(\A[\p{P}]+|\s[\p{P}]+)([\p{P}]+\s|[\p{P}]+\Z)',
	70 => '(\A[\p{P}]+|\s[\p{P}]+)([\p{P}]+\s|[\p{P}]+\Z)',
	80 => '(\A[\p{P}]+|\s[\p{P}]+)([\p{P}]+\s|[\p{P}]+\Z)',

	100 => '  +',                            # delete multiple spaces
    },
	'substitutions' => {
	    '([0-9]) ([0-9])' => '$1\x00sp\x00$2',   # keep numbers together
	},
	    'final substitutions' => {
		'\x00sp\x00' => ' ',       # restore number-spaces
		'(\p{P}) (\1)' => '$1$2',  # put identical punct marks together
		'(\p{P}) +(\1)' => '$1$2', # (do it again! (quite a hack ...))
	    },
	    'exceptions' => {
#		't.ex.' => 'abbr',           # put a list of exceptions here
	    },
	    'runtime' => {
		'verbose' => 0,
	    },
	},
	'arguments' => {
	    'shortcuts' => {
		'in' => 'input:text:file',
		'informat' => 'input:text:format',
		'r' => 'input:text:root',
		'b' => 'input:text:DocBodyTag',
		'o' => 'output:text:file',
		'outformat' => 'output:text:format',
		'ci' => 'input:text:encoding',
		'co' => 'output:text:encoding',
		't' => 'parameter:segments:tag',
		'a' => 'parameter:segments:add spans',
		'id' => 'parameter:segments:add IDs',
		'k' => 'parameter:segments:keep spaces',
		'v' => 'parameter:runtime:verbose'
		}
	},
	'help' => {
	    'shortcuts' => {
		'r' => 'root tag of sub-trees, reg. expr.',
		'b' => 'skip everything before this tag (body)',
		'in' => 'input file                        (default: STDOUT)',
		'o' => 'output file                        (default: STDOUT)',
		'ci' => 'character encoding, input         (default: utf-8)',
		'co' => 'character encoding, output        (default: utf-8)',
		't' => "word tag                           (default: 'w')",
		'k' => 'keep spaces (between xml tags)     (default: no)',
		'a' => 'add byte span attributes           (default: no)',
#		'm' => "modify the input file              (default: don't)",
	    },
	},
	'widgets' => {
	    'input' => {
		'text' => {
		    'stream name' => 'stream(format=xml,status=sent)'
		    },
		    },
		    }
    };
    return %{$DefaultIni};
}
