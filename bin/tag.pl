#!/usr/bin/perl
#
# tag.pl: a simple UPLUG wrapper for a (POS) tagger
#
# usage: tag.pl <infile >outfile
#        tag.pl [-i config] [-in in] [-out out] [-l language] [-s system]
#
# config      : configuration file
# in          : input file (source language)
# out         : output file
# l           : language (requires a startup script in './tagger/')
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
#
#
#---------------------------------------------------------------------------
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
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
#----------------------------------------------------------------------------
#
#            * requires a startup script for an external POS tagger
#              in the directory 'tagger/' (relative to UPLUG home directory)
#            * default startup-script: tagger_$language
#            * default language: swedish
#            * default input format for the tagger:
#                   1 sentence per line, each token separated by <SPACE>
#            * default tagger output:
#                   1 sentence per line, tags are appended to each token
#                   (token1/tag1 token2/tag2 token3/tag3 ...)
#            * default attribute name: pos
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


my %IniData=&GetDefaultIni;
my $IniFile='tag.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=
    each %{$IniData{'input'}};               # the first input stream;
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $input=Uplug::IO::Any->new($InputStream);
my $output=Uplug::IO::Any->new($OutputStream);

#---------------------------------------------------------------------------

my $lang=$IniData{parameter}{tagger}{language};
my $prg=$IniData{parameter}{tagger}{'startup base'};
my $attr=$IniData{parameter}{output}{attribute};
my $OutAttr=$IniData{parameter}{output}{attributes};
my $OutPattern=$IniData{parameter}{output}{pattern};
my $InTokDel=$IniData{parameter}{input}{'token delimiter'};
my $OutTokDel=$IniData{parameter}{output}{'token delimiter'};
my $InSentDel=$IniData{parameter}{input}{'sentence delimiter'};
my $OutSentDel=$IniData{parameter}{output}{'sentence delimiter'};
my $TagDel=$IniData{parameter}{output}{'tag delimiter'};
my %InputReplace=();
if (ref($IniData{parameter}{'input replacements'}) eq 'HASH'){
    %InputReplace=%{$IniData{parameter}{'input replacements'}};
}
my %OutputReplace=();
if (ref($IniData{parameter}{'output replacements'}) eq 'HASH'){
    %OutputReplace=%{$IniData{parameter}{'output replacements'}};
}
# my $OutputComments=$IniData{parameter}{output}{comments};

my @Attr=split(/:/,$OutAttr);
#---------------------------------------------------------------------------



if ($UplugHome!~/^[\\\/]/){
    use Cwd;
    $UplugHome=getcwd.'/'.$UplugHome;
}

my $TaggerDir=$UplugHome.'ext/tagger/';
#my $TmpUntagged=$TaggerDir.'untagged.'.$$;
#my $TmpTagged=$TaggerDir.'tagged.'.$$;
my $TmpUntagged=Uplug::IO::Any::GetTempFileName;
my $TmpTagged=Uplug::IO::Any::GetTempFileName;

my $TaggerPrg=$TaggerDir.$prg.$lang;
if (not -e $TaggerPrg){
    if (-e "$TaggerDir$prg\_$lang"){           # add '_' to startup script
	$TaggerPrg=$TaggerDir.$prg.'_'.$lang;  # if necessary
    }
}

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;

print STDERR "tag.pl: create temporary text file!\n";

$input->open('read',$InputStream);
my $UplugEncoding=$input->getInternalEncoding();
my $OutEncoding=$IniData{parameter}{output}{encoding};
if (not defined $OutEncoding){$OutEncoding=$UplugEncoding;}
my $InEncoding=$IniData{parameter}{input}{encoding};
if (not defined $InEncoding){$InEncoding=$OutEncoding;}

open F,">$TmpUntagged";

while ($input->read($data)){
    my @nodes=$data->contentElements;
    my @tok=$data->content(\@nodes);
#     my @tok=$data->content('w');
    map(s/^\s*//,@tok);                    # remove initial white-spaces
    map(s/\s*$//,@tok);                    # remove final white-spaces

    map($tok[$_]=&FixTaggerData($tok[$_],\%InputReplace),0..$#tok);
    if ($OutEncoding ne $UplugEncoding){
	map($tok[$_]=&Uplug::Encoding::convert($tok[$_],
					     $UplugEncoding,
					     $OutEncoding),
	    0..$#tok);
#	map($tok[$_]=&Uplug::Data::encode($tok[$_],$UplugEncoding,$OutEncoding),
#	    0..$#tok);
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
print STDERR "tag.pl: call external tagger!\n";
print STDERR "   $TaggerPrg $TmpUntagged >$TmpTagged\n";

if (my $sig=system "$TaggerPrg $TmpUntagged >$TmpTagged"){
    die "# tag: Got signal $? from tagger $TaggerPrg!\n";
}

#---------------------------------------------------------------------------

my $InputSeperator=$/;

print STDERR "tag.pl: read tagged file and create output data!\n";

$input->open('read',$InputStream);
$output->open('write',$OutputStream);
open F,"<$TmpTagged";

my $data=Uplug::Data->new;    # use a new data-object (new XML parser!)
my $ret;
while ($ret=$input->read($data)){
    $/=$OutSentDel;
    my $tagged=undef;
    my @cont=$data->contentElements;
    if (not @cont){
	$output->write($data);
	$/=$InputSeperator;
	next;
    }
    my @tok=();
    $tagged=<F>;
    $tagged=&FixTaggerData($tagged,\%OutputReplace);
    chomp $tagged;
    if ($InEncoding ne $UplugEncoding){
	$tagged=&Uplug::Encoding::encode($tagged,$InEncoding,$UplugEncoding);
#	$tagged=&Uplug::Data::encode($tagged,$InEncoding,$UplugEncoding);
    }
    @tok=split(/$OutTokDel/,$tagged);
    if (@cont != @tok){
	print STDERR "# tag.pl - warning: ";
	print STDERR scalar @cont," tokens but ",scalar @tok," tags!!\n";
	$output->write($data);
	$/=$InputSeperator;
	next;
    }
    my $WordAttr;
    foreach my $j (0..$#Attr){
	if ($Attr[$j] eq 'word'){
	    $WordAttr=$j;
	}
    }
    if (@Attr and (defined $OutPattern)){
	foreach my $i (0..$#tok){
	    if (not ref($cont[$i])){next;}
	    if ($tok[$i]=~/$OutPattern/s){
		my @Val=($1,$2,$3,$4,$5,$6,$7,$8,$9);
		if ((@cont != @tok) and (defined $WordAttr)){
		    if ($data->content($cont[$i]) ne $Val[$WordAttr]){
			if (@cont>@tok){shift @cont;}
			else{shift @tok;}
			$i--;
			next;
		    }
		}
		foreach my $j (0..$#Attr){
		    if ($Attr[$j] eq 'word'){next;}
		    if ($Attr[$j] eq 'text'){next;}
		    if ($Val[$j]=~/\S/){
			$data->setAttribute($cont[$i],$Attr[$j],$Val[$j]);
		    }
		}
	    }
	}
    }
    else{
	my @tag=@tok;
	map(s/^.*$TagDel//,@tag);
	map(s/^(.*)$TagDel[^$TagDel].*$/$1/,@tok);
	$data->setContentAttribute($attr,\@tag);
    }
    $output->write($data);
    $/=$InputSeperator;
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

sub FixTaggerData{
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
	'status' => 'tagGrok',
    }
  },
  'required' => {
    'text' => {
      'words' => undef
    }
  },
  'parameter' => {
    'input' => {
      'token delimiter' => ' ',
      'sentence delimiter' => '
'
    },
    'output' => {
      'token delimiter' => '\\s+',
      'tag delimiter' => '\\/',
      'sentence delimiter' => '
',
      'attribute' => 'pos',
	'encoding' => 'iso-8859-1',
    },
    'tagger' => {
      'language' => 'english',
      'startup base' => 'tagger_'
    },
     'input replacements' => {
        ' ' => '_',
     },
  },
  'module' => {
    'program' => 'tag.pl',
    'location' => '$UplugBin',
    'name' => 'tagger (english)',
    'stdout' => 'text'
  },
  'arguments' => {
    'shortcuts' => {
      'in' => 'input:text:file',
      'out' => 'output:text:file',
      'lang' => 'parameter:tagger:language',
      'in' => 'input:text:file',
       'attr' => 'parameter:output:attribute',
       'char' => 'output:text:encoding',
       't' => 'parameter:tagger:startup base',
    }
  },
  'widgets' => {
       'input' => {
	  'text' => {
	    'stream name' => 'stream(format=xml,status=(tok|tag|chunk),language=en)'
	  },
       },
       'parameter' => {
          'output' => {
	     'attribute' => 'optionmenu (pos,tnt)',
	  }
       }
  }
};

return %{$DefaultIni};
}
