#!/usr/bin/perl
#
# markup.pl: convert a plain text file to XML with basic markup
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
# $Id$
#
# usage: markup.pl <infile >outfile
#        markup.pl [-i configfile] [-in infile] [-out outfile] [-s system]
#        markup.pl [-i configfile] [-s system] <infile >outfile
#
# configfile  : configuration file
# infile      : input file in plain text
# outfile     : output file in simple XML
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
# 
# 
# information from the configfile will override other parameters
# (e.g. parameters [-in ...] and [-out ...] are discarded 
#       if input/output files are given in the configfile)
# default parameters are given in the &GetDefaultIni subfunction
#    at the end of the script!
#

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::Config;
use Uplug::Data;
use Uplug::IO::Any;


my %IniData=&GetDefaultIni;
my $IniFile='markup.ini';
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

my $HeaderSize=$IniData{parameter}{header}{'max nr of characters'};
my $HeaderStarter=$IniData{parameter}{header}{'start character'};
my $LbLimit=$IniData{parameter}{'paragraph break'}{'nr of empty lines'};
my $PageBreak=$IniData{parameter}{'page break'}{'nr of empty lines'};
my $PageBreakTag='pb';
my $HeaderTag='head';
my $ParagraphTag='p';

#---------------------------------------------------------------------------

# my %data;
my $data=Uplug::Data->new('hash');
my $paragraph='';
my $CountLb=0;
my $CountPb=0;

# while ($input->read(\%data)){
while ($input->read($data)){

#    $paragraph.=$data{'content'}.' ';
    my $content=$data->content;
#    my @content=$data->content;
    $paragraph.=$content.' ';

    if ($content=~/^\s*$/){$CountLb++;$CountPb++;}
    else{$CountLb=0;}
    if ($paragraph=~/^\s*$/){next}

    if (&ParagraphBoundary($paragraph,$CountLb,\$CountPb)){
	$paragraph='';
	$CountLb=0;
    }
}

if ($paragraph){
    &MakeOutData($paragraph,\$CountPb);
}


#---------------------------------------------------------------------------

$input->close;
$output->close;

sub MakeOutData{
    my ($paragraph,$CountPb)=@_;
    $paragraph=~s/\s*$//;                    # delete final whitespaces
    if ($$CountPb>$PageBreak){
	my $PbData=Uplug::Data->new();
	$PbData->setContent(undef,$PageBreakTag);
	$output->write($PbData);
	$$CountPb=0;
    }
    if ($paragraph){
	my $tag=&BestTag($paragraph);
	my $OutData=Uplug::Data->new();
	$OutData->setContent($paragraph,$tag);
	$output->write($OutData);
    }
}

sub BestTag{
    my ($paragraph)=@_;
    if ((length($paragraph)<=$HeaderSize) and
	($paragraph=~/^[$HeaderStarter]/)){
	return $HeaderTag;
    }
    return $ParagraphTag;
}


sub ParagraphBoundary{
    my ($paragraph,$CountLb,$CountPb)=@_;
    if ($CountLb>=$LbLimit){
	if ((length($paragraph)<=$HeaderSize) and
	    ($paragraph=~/^[$HeaderStarter]/)){
	    &MakeOutData($paragraph,$CountPb);
	    return 1;
	}
	&MakeOutData($paragraph,$CountPb);
	return 1;
    }
    return 0;
}


sub GetDefaultIni{

    my $DefaultIni = {
	'encoding' => 'iso-8859-1',
	'module' => {
	    'name' => 'XML markup',
	    'program' => 'markup.pl',
	    'location' => '\$UplugBin',
	    'stdin' => 'text',
	    'stdout' => 'text',
	},
	'description' => 
'This module converts plain text files into XML
using some basic markup. It adds XML tags for headers, paragraph
tags and page break tags. Header tags are added to short text lines
which are separated from surrounding text. Paragraph and page break
tags are added wherever a certain amount of empty lines are found in
the text.',
        'input' => {
	    'text' => {
		'format' => 'text',
	    }
	},
	'output' => {
	    'text' => {
		'format' => 'xml',
		'DocRootTag' => 'cesDoc',
#		'DocHeaderTag' => 'cesHeader',
		'DocBodyTag' => 'text',
		'write_mode' => 'overwrite',
		'status' => 'markup',
	    }
	},
	'parameter' => {
	    'header' => {
		'max nr of characters' => 40,
		'start character' => 'A-Z�����������������������������0-9',
	    },
	    'paragraph break' => {
		'nr of empty lines' => 1,
	    },
	    'page break' => {
		'nr of empty lines' => 2,
	    },
	},
	'arguments' => {
	    'shortcuts' => {
		'is' => 'input:text:stream name',
		'os' => 'output:text:stream name',
		'o' => 'output:text:file',
		'in' => 'input:text:file',
		'o' => 'output:text:file',
		'ci' => 'input:text:encoding',
		'co' => 'output:text:encoding',
		'pb' => 'parameter:page break:nr of empty lines',
		'p' => 'parameter:paragraph break:nr of empty lines',
	    }
	},
	'help' => {
	    'shortcuts' => {
		'ci' => 'character encoding (input),       default=iso-8859-1',
		'co' => 'character encoding (output),      default=utf-8',
		'in' => 'input text file                   default=STDIN',
		'o' => 'output file                       default=STDOUT',
		'pb' => 'nr empty lines == page break      default=2',
		'p' => 'nr empty lines == paragraph break default=1',
	    },
	},
	'widgets' => {
	    'input' => {
		'text' => {
		    'stream name' => 'stream(format=text,status=text)',
		},
	    },
	    'parameter' => {
		'header' => {
		    'max nr of characters' => 'scale (1,100,1,10)',
		},
		'paragraph break' => {
		    'nr of empty lines' => 'scale (1,10,1,1)',
		},
		'page break' => {
		    'nr of empty lines' => 'scale (1,10,1,1)',
		},
	    }
	}
    };
    return %{$DefaultIni};
}
