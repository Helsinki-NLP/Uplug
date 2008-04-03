#!/usr/bin/perl
#-*-perl-*-
#
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
#
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
# chunk.pl: a simple UPLUG wrapper for a "chunk-tagger"
#
# usage: chunk.pl <infile >outfile
#        chunk.pl [-i config] [-in in] [-out out] [-l language] [-s system]
#
# config      : configuration file
# in          : input file (source language)
# out         : output file
# l           : language (requires a startup script in './chunker/')
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
#
#
# $Author$
# $Id$
#----------------------------------------------------------------------------
#
#            * requires a startup script for an external chunk
#              in the directory 'chunker/' 
#              (relative to the UPLUG home directory)
#            * default startup-script: chunker_$language
#            * default language: english
#            * default POS attribute: pos
#            * default input format for the chunker:
#                   1 sentence per line, 
#                   each token separated by <SPACE>,
#                   each token is tagged with POS tags
#            * default chunker output:
#                   1 sentence per line, chunk-tags are appended to each token
#                   (token1/pos1/tag1 token2/pos2/tag2 token3/pos3/tag3 ...)
#            * default chunk-tag-name: 'chunk'
#
# 

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;
use Encode;

my $UplugHome="$Bin/../";
$ENV{UPLUGHOME}=$UplugHome;

my %IniData=&GetDefaultIni;
my $IniFile='chunk.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=
    each %{$IniData{'input'}};               # the first input stream;
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $input=Uplug::IO::Any->new($InputStream);
my $output=Uplug::IO::Any->new($OutputStream);

#---------------------------------------------------------------------------

my $lang=$IniData{parameter}{chunker}{language};
my $prg=$IniData{parameter}{chunker}{'startup base'};
my $POSattr=$IniData{parameter}{input}{'POS attribute'};
my $InTokDel=$IniData{parameter}{input}{'token delimiter'};
my $OutTokDel=$IniData{parameter}{output}{'token delimiter'};
my $InSentDel=$IniData{parameter}{input}{'sentence delimiter'};
my $OutSentDel=$IniData{parameter}{output}{'sentence delimiter'};
my $InTagDel=$IniData{parameter}{input}{'POS tag delimiter'};
my $OutTagDel=$IniData{parameter}{output}{'POS tag delimiter'};
my $ChunkTagDel=$IniData{parameter}{output}{'chunk tag delimiter'};
my $ChunkTag=$IniData{parameter}{output}{'chunk tag'};
my %TokReplace=();
if (ref($IniData{parameter}{'input token replacements'}) eq 'HASH'){
    %TokReplace=%{$IniData{parameter}{'input token replacements'}};
}
my %TagReplace=();
if (ref($IniData{parameter}{'input tag replacements'}) eq 'HASH'){
    %TagReplace=%{$IniData{parameter}{'input tag replacements'}};
}
my %InputReplace=();
if (ref($IniData{parameter}{'input replacements'}) eq 'HASH'){
    %InputReplace=%{$IniData{parameter}{'input replacements'}};
}
my %OutputReplace=();
if (ref($IniData{parameter}{'output replacements'}) eq 'HASH'){
    %OutputReplace=%{$IniData{parameter}{'output replacements'}};
}

#---------------------------------------------------------------------------



if ($UplugHome!~/^[\\\/]/){
    use Cwd;
    $UplugHome=getcwd.'/'.$UplugHome;
}

my $ChunkerDir=$UplugHome.'ext/chunker/';
#my $TmpUntagged=$ChunkerDir.'untagged.'.$$;
#my $TmpTagged=$ChunkerDir.'tagged.'.$$;
my $TmpUntagged=Uplug::IO::Any::GetTempFileName;
my $TmpTagged=Uplug::IO::Any::GetTempFileName;

my $ChunkerPrg=$ChunkerDir.$prg.$lang;

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;

$input->open('read',$InputStream);
my $UplugEncoding=$input->getInternalEncoding();
my $OutEncoding=$IniData{parameter}{output}{encoding};
if (not defined $OutEncoding){$OutEncoding=$UplugEncoding;}

open F,">$TmpUntagged";

while ($input->read($data)){

#    my @nodes=$data->contentElements;
    my @nodes=$data->findNodes('w');
    my @tok=$data->content(\@nodes);
    my @attr=$data->attribute(\@nodes);

    map(s/^\s*//,@tok);                    # remove initial white-spaces
    map(s/\s*$//,@tok);                    # remove final white-spaces

    map($tok[$_]=&FixChunkerData($tok[$_],\%TokReplace),0..$#tok);

    foreach (0..$#tok){
	if ($tok[$_]!~/\S/){next;}
	if (defined $attr[$_]{$POSattr}){
	    $attr[$_]{$POSattr}=&FixChunkerData($attr[$_]{$POSattr},
						\%TagReplace);
	    $tok[$_].=$InTagDel.$attr[$_]{$POSattr};
	}
    }
    map($tok[$_]=&FixChunkerData($tok[$_],\%InputReplace),0..$#tok);
#    if ($OutEncoding ne $UplugEncoding){
#	map($tok[$_]=&Uplug::Encoding::convert($tok[$_],
#					       $UplugEncoding,
#					       $OutEncoding),
#	    0..$#tok);
#    }

#	## handle malformed data by converting to octets and back
#	## the sub in encode ensures that malformed characters are ignored!
#	## (see http://perldoc.perl.org/Encode.html#Handling-Malformed-Data)
    if ($OutEncoding ne $UplugEncoding){
	foreach my $t (0..$#tok){
	    my $octets = encode($OutEncoding, $tok[$t],sub{ return '' });
	    $tok[$t] = decode($OutEncoding, $octets);
	}
    }
    @tok=grep(/\S/,@tok);                  # take only non-empty tokens
    if (@tok){                             # print them if any left
	print F join $InTokDel,@tok;
	print F $InSentDel;
    }
}

close F;
$input->close;

#---------------------------------------------------------------------------

if (my $sig=system "$ChunkerPrg $TmpUntagged >$TmpTagged"){
    die "# chunk: Got signal $? from $ChunkerPrg!\n";
}

#---------------------------------------------------------------------------

my $InputSeperator=$/;
$/=$OutSentDel;

$input->open('read',$InputStream);
$output->open('write',$OutputStream);
open F,"<$TmpTagged";

# $data->initXmlParser();

my $data=Uplug::Data->new;    # use a new data-object (new XML parser!)
while ($input->read($data)){
    my $tagged=undef;
#    my @cont=$data->contentElements;
    my @cont=$data->findNodes('w');
    if (not @cont){$output->write($data);next;}
    my @tok=();
    $/=$OutSentDel;
    $tagged=<F>;
    $tagged=&FixChunkerData($tagged,\%OutputReplace);
    chomp $tagged;
    @tok=split(/$OutTokDel/,$tagged);
    if (@cont != @tok){
	print STDERR "# chunk.pl - warning: ";
	print STDERR scalar @cont," tokens but ",scalar @tok," tags!!\n";
	$output->write($data);
	next;
    }
#    while ($tagged=<F>){
#	$tagged=&FixChunkerData($tagged,\%OutputReplace);
#	chomp $tagged;
#	@tok=split(/$OutTokDel/,$tagged);
#	if (@cont == @tok){last;}
#    }

    $/=$InputSeperator;
#    chomp $tagged;
#    my @tok=split(/$OutTokDel/,$tagged);
    my @label=@tok;
    map(s/^.*$InTagDel//,@label);
    map(s/^(.*)$InTagDel.*$/$1/,@tok);
    my @tag=@tok;
    map(s/^.*$ChunkTagDel//,@tag);
    map(s/^(.*)$ChunkTagDel.*$/$1/,@tok);

    my $id=$data->attribute('id');
    $id=~s/^./c/;

    &AddChunks($data,\@tok,\@tag,\@label,$id);
    $output->write($data);
}
close F;
$input->close;
$output->close;

$/=$InputSeperator;

END {
    unlink $TmpUntagged;
    unlink $TmpTagged;
}

############################################################################

sub AddChunks{
    my ($data,$tokens,$tags,$labels,$id)=@_;

    my @words=();
    my @attr=();
    my $count=0;

    my @nodes=$data->contentElements;

    my ($type,$length);
    while (($type,$length)=&GetNextChunk($labels)){
	$count++;
	my @children=();
	foreach (0..$length){
	    $children[$_]=shift @nodes;
	}
	if (not $type){next;}              # no type --> no chunk!!
	my %ParentAttr=();
	$ParentAttr{type}=$type;
	$ParentAttr{id}=$id."-$count";
	$data->addParent(\@children,'chunk',\%ParentAttr);
    }
}

sub GetNextChunk{
    my ($labels)=@_;
    my $length=1;

    if (not @{$labels}){return ();}
    my $l=shift(@{$labels});

    my $PrevPos;
    my $PrevChunk=undef;
    my $length=0;

    if ($l=~/^(.)/){$PrevPos=$1;}
    if ($l=~/\-(.*)$/){$PrevChunk=$1;}

    while (@{$labels}){

	my $CurrentPos=undef;
	my $CurrentChunk=undef;
	if ($labels->[0]=~/^(.)/){$CurrentPos=$1;}
	if ($labels->[0]=~/\-(.*)$/){$CurrentChunk=$1;}

	if (($PrevPos eq 'O') or
	    ($CurrentPos=~/[B|O]/) or
	    ($PrevChunk ne $CurrentChunk)){
	    return ($PrevChunk,$length);
	}
	$length++;
	shift(@{$labels});
	$PrevPos=$CurrentPos;
	$PrevChunk=$CurrentChunk;
    }
    return ($PrevChunk,$length);
}



sub FixChunkerData{
    my ($string,$subst)=@_;
    foreach (keys %{$subst}){
	$string=~s/$_/$subst->{$_}/sg;
    }
    return $string;
}


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
#	'encoding' => 'iso-8859-1',
	'status' => 'chunk',
    }
  },
  'parameter' => {
    'input' => {
      'token delimiter' => ' ',
      'sentence delimiter' => '
',
      'POS tag delimiter' => '/',
      'POS attribute' => 'pos'
    },
    'chunker' => {
      'language' => 'english',
      'startup base' => 'chunker_'
    },
    'output' => {
      'token delimiter' => '\\s+',
      'chunk tag delimiter' => '\\/',
      'sentence delimiter' => '
',
      'chunk tag' => 'chunk',
      'POS tag delimiter' => '\\/',
	'encoding' => 'iso-8859-1',
    },
    'input token replacements' => {
      '\\,' => 'COMMA',
        ' ' => '_',
    },
    'input tag replacements' => {
      '\\,' => 'COMMA'
    }
  },
  'module' => {
    'program' => 'chunk.pl',
    'location' => '$UplugBin',
    'name' => 'chunker (english)',
    'stdout' => 'text'
  },
  'arguments' => {
    'shortcuts' => {
      'in' => 'input:text:file',
      'out' => 'output:text:file',
      'lang' => 'parameter:chunker:language',
      'in' => 'input:text:file',
      'pos' => 'parameter:input:POS attribute',
       'char' => 'output:text:encoding',
       'inchar' => 'input:text:encoding',
       'outchar' => 'output:text:encoding',
       'tag' => 'parameter:output:chunk tag',
    }
  },
  'widgets' => {
       'input' => {
	  'text' => {
	    'stream name' => 'stream(format=xml,status=tag,language=en)'
	  },
       },
       'parameter' => {
          'output' => {
	     'chunk tag' => 'optionmenu (chunk,c)',
	  },
          'input' => {
	     'POS attribute' => 'optionmenu (pos,grok,tnt)',
	  }
       }
  }
};

    return %{$DefaultIni};
}
