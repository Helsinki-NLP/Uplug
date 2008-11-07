#!/usr/bin/perl
#-*-perl-*-
#
# tokext.pl: a simple UPLUG wrapper for a tokenizer
#
# usage: tokext.pl <infile >outfile
#        tokext.pl [-i config] [-in in] [-out out] [-l language] [-s syst]
#
# config      : configuration file
# in          : input file (source language)
# out         : output file
# syst        : Uplug system (subdirectory of UPLUGSYSTEM)
#
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
# $Id $
#----------------------------------------------------------------------------
#
#            * requires a startup script for an external tokenizer
#              in the directory 'tokenizer/' (relative to UPLUG home directory)
#            * default startup-script: tok_$language
#            * default language: dutch
#
# 
use strict;

use FindBin qw($Bin);
use lib "$Bin/..";

my $UplugHome="$Bin/../";
$ENV{UPLUGHOME}=$UplugHome;

use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;
use Uplug::Encoding;
use Encode;

my %IniData=&GetDefaultIni;
my $IniFile='toktag.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=
    each %{$IniData{'input'}};               # the first input stream;
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $input=Uplug::IO::Any->new($InputStream);
my $output=Uplug::IO::Any->new($OutputStream);

#---------------------------------------------------------------------------
# general options (for the external program)

my $lang=$IniData{parameter}{tokenizer}{language};
my $prg=$IniData{parameter}{tokenizer}{'startup base'};

#---------------------------------------------------------------------------
# tokenizer options:

my $SegTag=$IniData{parameter}{segments}{tag};
my $AddId=$IniData{parameter}{segments}{'add IDs'};
my $KeepSpaces=$IniData{parameter}{segments}{'keep spaces'};
my $AddParId=$IniData{parameter}{segments}{'add parent id'};

#---------------------------------------------------------------------------
# tokenizer options

my $OutTokDel=$IniData{parameter}{output}{'token delimiter'};
my $InSentDel=$IniData{parameter}{input}{'sentence delimiter'};
my $OutSentDel=$IniData{parameter}{output}{'sentence delimiter'};

#---------------------------------------------------------------------------



if ($UplugHome!~/^[\\\/]/){
    use Cwd;
    $UplugHome=getcwd.'/'.$UplugHome;
}



my $TmpUntokenized=Uplug::IO::Any::GetTempFileName;
my $TmpTokenized=Uplug::IO::Any::GetTempFileName;

my $TokenizerDir=$UplugHome.'ext/tokenizer/';
my $Tokenizer=$TokenizerDir.$prg.$lang;

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;

print STDERR "tokext.pl: create temporary text file!\n";

$input->open('read',$InputStream);
my $UplugEncoding=$input->getInternalEncoding();
my $OutEncoding=$IniData{parameter}{output}{encoding};
if (not defined $OutEncoding){$OutEncoding=$UplugEncoding;}

my $untokenized=Uplug::IO::Any->new('text');
$untokenized->open('write',{file=>$TmpUntokenized,encoding=>$OutEncoding});

while ($input->read($data)){

    my $txt=$data->content;
    if ($txt){

	## handle malformed data by converting to octets and back
	## the sub in encode ensures that malformed characters are ignored!
	## (see http://perldoc.perl.org/Encode.html#Handling-Malformed-Data)
	if ($OutEncoding ne $UplugEncoding){
	    my $octets = encode($OutEncoding, $txt,sub{ return ' ' });
	    $txt = decode($OutEncoding, $octets);
	}
	$untokenized->write($txt.$InSentDel);
    }
}

# $untokenized->write($txt.$InSentDel);
$untokenized->close;
$input->close;


#---------------------------------------------------------------------------
print STDERR "tokext.pl: call external tokenizer!\n";
print STDERR "   $Tokenizer < $TmpUntokenized >$TmpTokenized\n";

eval { system "$Tokenizer < $TmpUntokenized > $TmpTokenized" };
print $@ if $@;

#---------------------------------------------------------------------------

my $InputSeperator=$/;

print STDERR "tokext.pl: read tokenized file and create output data!\n";

$input->open('read',$InputStream);
$output->open('write',$OutputStream);
open F,"<$TmpTokenized";
binmode(F,':encoding('.$OutEncoding.')');

my $ret;
my $id=0;
my $parId=0;
my $idhead='';
my $data=Uplug::Data->new;    # use a new data-object (new XML parser!)

my $tokenized=undef;
my @tok=();
my $pat;

while ($ret=$input->read($data)){
    my $txt=$data->content;
    my $txt_nospaces=$txt;     # in case the external tokenizer tokens together
    $txt_nospaces=~s/\s//gs;   # --> take away all spaces in original string
#    print STDERR "$txt ...";
    if (not $txt){
	$output->write($data);
	next;
    }
    $/=$OutSentDel;
    my @seg = ();
    while (1){
	if (not @tok){
	    $tokenized=<F>;
		if ($tokenized=~/Om een afbeelding direct vanaf de scanner/){
		    print '';
		}
	    chomp $tokenized;
	    last if (not defined $tokenized);
	    my @newtok=split(/$OutTokDel/,$tokenized);
	    push (@tok,@newtok);
	}
	my $t=$tok[0];
	$pat=quotemeta($t);
#	print STDERR "test if $txt=~\/--$pat--\/\n";
	if ($txt=~s/$pat// || ($txt_nospaces=~s/$pat//)){
	    push(@seg,shift(@tok));
	    ## read more to see if there is more to match ....
	    if (not @tok){
		$tokenized=<F>;
		chomp $tokenized;
		if ($tokenized=~/Om een afbeelding direct vanaf de scanner/){
		    print '';
		}
		last if (not defined $tokenized);
		my @newtok=split(/$OutTokDel/,$tokenized);
		push (@tok,@newtok);

		$pat=quotemeta($tok[0]);
		if ($txt=~/$pat/){
		    print '';
		    if ($tokenized=~/Color , Gray en Binary/){
			print '';
		    }
		}
	    }
	}
	else{
	    last;
	}
    }

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
    my $root=$data->getRootNode();
    my @children=$data->splitContent($root,$SegTag,\@seg);
    #-------------------------------------------------------
    if ($AddId){
	foreach my $c (0..$#children){
	    if (not ref($children[$c])){next;}
	    if ($AddId){
		$id++;
		$data->setAttribute($children[$c],
				    'id',"$SegTag$idhead$id");
	    }
	}
    }

    $output->write($data);
    $/=$InputSeperator;
#    print STDERR "ok\n";
}
close F;

$input->close;
$output->close;

$/=$InputSeperator;

END {
    unlink $TmpUntokenized;
    unlink $TmpTokenized;
}

############################################################################


sub GetDefaultIni{

    my $DefaultIni = 
{
  'input' => {
    'text' => {
      'format' => 'xml',
      'root' => 's',
    }
  },
  'output' => {
    'text' => {
      'format' => 'xml',
      'root' => 's',
      'write_mode' => 'overwrite',
	'encoding' => 'iso-8859-1',
	'status' => 'tok',
    }
  },
  'required' => {
    'text' => {
      'words' => undef,
    }
  },
  'parameter' => {
     'segments' => {
	 'add IDs' => 1,
	 'add parent id' => 1,
	 'tag' => 'w',
     },
     'tokenizer' => {
	 'language' => 'dutch',
	 'startup base' => 'tok_',
     },
     'output' => {
        'token delimiter' => ' ',
        'sentence delimiter' => "\n",
	'encoding' => 'iso-8859-1',
     },
     'input' => {
        'token delimiter' => " ",
        'sentence delimiter' => "\n",
     },
  },
  'module' => {
    'program' => 'tokext.pl',
    'location' => '$UplugBin',
    'name' => 'tokenizer (dutch)',
    'stdout' => 'text'
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:text:file',
       'out' => 'output:text:file',
      'lang' => 'parameter:tokenizer:language',
       'attr' => 'parameter:output:attribute',
       'char' => 'output:text:encoding',
       'co' => 'output:text:encoding',
       'ci' => 'input:text:encoding',
       'r' => 'input:text:root',
    }
  },
  'widgets' => {
       'input' => {
	  'text' => {
	    'stream name' => 'stream(format=xml,status=sent,language=en)'
	  },
       },
  }
};
    return %{$DefaultIni};
}
