#!/usr/bin/perl
# -*-perl-*-
#
# hunalign.pl:
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
#
# $Id$
#
# usage: hunalign.pl <infile >outfile
#        hunalign.pl [-i config] [-src file1] [-trg file2] [-out out] [-s sys]
#
# config      : configuration file
# file1       : input file (source language)
# file2       : input file (target language)
# out         : output file
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
# 
# 

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;

my $UplugHome="$Bin/../";

use strict;

my %IniData=&GetDefaultIni;
my $IniFile='hunalign.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my $SrcStream=$IniData{input}{'source text'};
my $TrgStream=$IniData{input}{'target text'};
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $source=Uplug::IO::Any->new($SrcStream);
my $target=Uplug::IO::Any->new($TrgStream);
my $output=Uplug::IO::Any->new($OutputStream);

if (not -e $SrcStream->{file}){
    die "# sentalign.pl: need a source language file!";
}
if (not -e $TrgStream->{file}){
    die "# sentalign.pl: need a target language file!";
}

#---------------------------------------------------------------------------

my $ParBreak=$IniData{parameter}{'paragraph boundary'};
my $DicFile=$IniData{parameter}{'dictionary'};

my $AlignDir=$UplugHome.'ext/hunalign/hunalign/';
my $TmpSrc=Uplug::IO::Any::GetTempFileName;
my $TmpTrg=Uplug::IO::Any::GetTempFileName;
my $AlignPrg=$AlignDir.'hunalign';
if (not -e $DicFile){                            # if there is no dictionary:
    $DicFile=$AlignDir.'data/null.dic';          # - use an empty file
    $AlignPrg=$AlignDir.'hunalign -realign';     # - ... and the realign flag
}

#---------------------------------------------------------------------------
# open data streams!
#

if (not $source->open('read',$SrcStream)){exit;}
if (not $target->open('read',$TrgStream)){exit;}
$OutputStream->{DocRoot}->{version}='1.0';
$OutputStream->{DocRoot}->{fromDoc}=$SrcStream->{file},;
$OutputStream->{DocRoot}->{toDoc}=$TrgStream->{file},;

if (not $output->open('write',$OutputStream)){exit;}
#---------------------------------------------------------------------------

my @SrcSent=();
my @TrgSent=();

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;
open F,">$TmpSrc";
binmode(F,':encoding(utf-8)') if ($]>=5.008);

while ($source->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	my @tok=$data->content;
	map(s/^\s*//,@tok);                    # remove initial white-spaces
	map(s/\s*$//,@tok);                    # remove final white-spaces
	@tok=grep(/\S/,@tok);                  # take only non-empty tokens
	if (@tok){                             # print them if any left

	    my $before=$data->header;
	    if ($before=~/\<$ParBreak[\s\/\>]/s){
		print F '<p>'."\n";
		push(@SrcSent,'p');
	    }
	    push (@SrcSent,$id);
	    print F join " ",@tok;
	    print F "\n";
	}
    }
}
close F;
$source->close;

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;    # use a new data-object (new XML parser!)
open F,">$TmpTrg";
binmode(F,':encoding(utf-8)') if ($]>=5.008);

while ($target->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	my @tok=$data->content;
	map(s/^\s*//,@tok);                    # remove initial white-spaces
	map(s/\s*$//,@tok);                    # remove final white-spaces
	@tok=grep(/\S/,@tok);                  # take only non-empty tokens
	if (@tok){                             # print them if any left

	    my $before=$data->header;
	    if ($before=~/\<$ParBreak[\s\/\>]/s){
		print F '<p>'."\n";
		push(@TrgSent,'p');
	    }
	    push (@TrgSent,$id);
	    print F join " ",@tok;
	    print F "\n";
	}
    }
}
close F;
$target->close;




#---------------------------------------------------------------------------

print STDERR "$AlignPrg $DicFile $TmpSrc $TmpTrg\n";
my @alignments = `$AlignPrg $DicFile $TmpSrc $TmpTrg`;

#---------------------------------------------------------------------------

my ($lastSrc,$lastTrg,$lastScore)=(0,0,0);

my $id=0;
foreach (@alignments){
    chomp;
    my ($sid,$tid,$score)=split(/\s+/);
    if (! /^[1-9]/){            # skip (0,0) and dictionary output (realign)
	$lastScore=$score;
	next;              
    }

    if ($SrcSent[$sid-1] eq 'p'){
	if ($TrgSent[$tid-1] eq 'p'){
	    $lastSrc=$sid;
	    $lastTrg=$tid;
	    $lastScore=$score;
	    next;
	}
	else{
	    print STDERR "strange! non corresponding par boundaries!\n";
	    $lastSrc=$sid;
	    $lastScore=$score;
	    next;
	}
    }
    if ($TrgSent[$tid-1] eq 'p'){
	print STDERR "strange! non corresponding par boundaries!\n";
	$lastTrg=$tid;
	$lastScore=$score;
	next;
    }

    $id++;
    my @LinkSrc=();
    my @LinkTrg=();
#    foreach ($lastSrc+1 .. $sid){
    foreach ($lastSrc .. $sid-1){
	push(@LinkSrc,$SrcSent[$_]);
    }
#    foreach ($lastTrg+1 .. $tid){
    foreach ($lastTrg .. $tid-1){
	push(@LinkTrg,$TrgSent[$_]);
    }

    my $link = join(' ',@LinkSrc);
    $link .= ';';
    $link .= join(' ',@LinkTrg);

    my $out=Uplug::Data->new;
    $out->setContent(undef,$output->option('root'));
    $out->setAttribute('id','SL'.$id);
    $out->setAttribute('xtargets',$link);
    $out->setAttribute('certainty',$lastScore);
    $output->write($out);

    $lastSrc=$sid;
    $lastTrg=$tid;
    $lastScore=$score;
}

#---------------------------------------------------------------------------

$output->close;

unlink $TmpSrc;
unlink $TmpTrg;





############################################################################


sub GetDefaultIni{

    my $DefaultIni = {
  'input' => {
    'source text' => {
      'format' => 'XML',
      'file' => 'data/source.xml',
      'root' => 's',
    },
    'target text' => {
      'format' => 'XML',
      'file' => 'data/target.xml',
      'root' => 's',
    }
  },
  'output' => {
    'bitext' => {
      'format' => 'xces align',
      'write_mode' => 'overwrite',
    }
  },
  'parameter' => {
      'paragraph boundary' => '(p|head)',
  },
  'arguments' => {
    'shortcuts' => {
       'src' => 'input:source text:file',
       'trg' => 'input:target text:file',
       'out' => 'output:bitext:file',
    }
  },
};
    return %{$DefaultIni};
}
