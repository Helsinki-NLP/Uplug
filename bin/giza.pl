#!/usr/bin/perl
#
# giza.pl: wrapper for Giza++
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
# 

use strict;
use Cwd;
use FindBin qw($Bin);
use lib "$Bin/..";
use strict;

use Uplug::Data;
use Uplug::Data::Align;
use Uplug::IO::Any;
use Uplug::Config;

my $UplugHome="$Bin/../";
$ENV{UPLUGHOME}=$UplugHome;
my $PWD=getcwd;
my $GIZADIR="$Bin/../ext/GIZA++";
if (not -d $GIZADIR){$GIZADIR="$ENV{HOME}/cvs/GIZA++-v2";}
if (not -d $GIZADIR){$GIZADIR="$ENV{HOME}/cvs/GIZA++";}
if (not -d $GIZADIR){$GIZADIR="/local/ling/GIZA++-v2";}
if (not -d $GIZADIR){$GIZADIR="/local/ling/GIZA++";}
if (not -d $GIZADIR){$GIZADIR="/home/staff/joerg/cvs/GIZA++-v2";}
if (not -d $GIZADIR){$GIZADIR="/home/staff/joerg/cvs/GIZA++";}
if (not -d $GIZADIR){warn "cannot find GIZA++\n!";exit;}

my %IniData=&GetDefaultIni;
my $IniFile='giza.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);
my $direction=$IniData{parameter}{'alignment direction'};
my $makeclue=$IniData{parameter}{'make clue'};
my $TokenParam=$IniData{parameter}{token};

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=
    each %{$IniData{'input'}};               # the first input stream;
my $ClueDB=$IniData{output}{clue};
delete $IniData{output}{clue};
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

#---------------------------------------------------------------------------


# my $TmpDir=Uplug::IO::Any::GetTempFileName;
my $TmpDir='/tmp/giza'.$$;
mkdir $TmpDir;
my $SrcFile=$TmpDir."/src";
my $TrgFile=$TmpDir."/trg";
my $BitextHeader;

my @align;
if ($direction eq 'trg-src'){@align=(1);}      # inverse alignment
elsif ($direction eq 'both'){@align=(0,1);}    # both directions
else{@align=(0);}                              # default

&Bitext2Text($InputStream,$SrcFile,$TrgFile,$TokenParam);
foreach my $d (@align){
    chdir $TmpDir;
    if ($d){&RunGiza($TmpDir,'trg','src');}
    else{&RunGiza($TmpDir,'src','trg');}
    chdir $PWD;
    if (ref($OutputStream) eq 'HASH'){
	&Giza2Uplug($TmpDir,$InputStream,$TokenParam,$OutputStream,$d);
    }
    if ($makeclue){
	&Giza2Clue($TmpDir,$TokenParam,$d);
    }
}

END{
    if ($TmpDir and (-d $TmpDir)){
	`rm -f $TmpDir/*`;
	`rmdir $TmpDir`;
    }
}




#----------------------------------------------------------------------------
# Giza2Clue (new version): no external calls
#  - looks for $dir/GIZA++.actual.ti.final (lexical prob's from GIZA)
#  - creates data/runtime/giza.dbm
#  - creates data/runtime/giza2.dbm (inverse alignments)

sub Giza2Clue{
    my $dir=shift;
    my $param=shift;
    my $inverse=shift;

    my %dic;
    if (ref($ClueDB) eq 'HASH'){
	%dic=%{$ClueDB};
    }
    else{
	%dic=('format' => 'dbm',
	      'write_mode' => 'overwrite',
	      'key' => ['source','target']);
	my $cluedir='data/runtime';
	if ($inverse){$dic{file}="$cluedir/giza2.dbm";}
	else{$dic{file}="$cluedir/giza.dbm";}
    }

    my %inStream=('file' => "$dir/GIZA++.actual.ti.final",
		  'format' => 'tab',
		  'field delimiter' => ' ');
    if ($inverse){
	$inStream{'columns'}=['source','target','value',],
    }
    else{
	$inStream{'columns'}=['target','source','value',],
    }


    my %lex=();
    my $data=Uplug::Data->new;

    my $in=Uplug::IO::Any->new(\%inStream);
    $in->open('read',\%inStream);
    while ($in->read($data)){
	my $src=$data->attribute('source');
	my $trg=$data->attribute('target');
	if ((not $src) or (not $trg)){next;}
	my $value=$data->attribute('value');
	if (not $value){$value=1;}
	$lex{$src}{$trg}=$value;
	if (($src=~s/\_/ /gs) or ($trg=~s/\_/ /gs)){ # (for giza-clue:)
	    $lex{$src}{$trg}=$value;                 #   '_' means ' '
	}
    }
    my $header=$in->header;

    my $out=Uplug::IO::Any->new(\%dic);
    $out->open('write',\%dic);
    $out->addheader($header);
    $out->addheader($param);
    $out->writeheader();

    foreach my $s (keys %lex){
	my $total;
	foreach my $t (keys %{$lex{$s}}){
	    my $score=$lex{$s}{$t};
	    my $data=Uplug::Data->new;
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('score',$score);
	    $out->write($data);
	}
    }

    $out->close;
    $in->close;
}


#----------------------------------------------------------------------------
# (old old old)
# Giza2Clue: convert GIZA's lexical translation parameters to a Uplug clue DB
# (creates giza.dbm or giza2.dbm (inverse direction))
# 
# this procedure simply calls external scripts in the tools directory!
#      and moves dbm-files to the clue directory using the UNIX 'mv' command
# --> does not work on all platforms!

sub Giza2ClueOld{
    my $dir=shift;
    my $param=shift;
    my $inverse=shift;

    my $dbm='giza.dbm';
    if ($inverse){$dbm='giza2.dbm';}
    my $convert="$Bin/../tools/declclue -p -o $dbm -d ' '";
    if ($inverse){$convert.=" -c 'source,target,value'";}
    else{$convert.=" -c 'target,source,value'";}
    my $giza="$dir/GIZA++.actual.ti.final";
    my $cluedir='data/runtime';

    if (-f $giza){
	system "$convert <$giza";
	system "mkdir -p $cluedir";
	system "mv $dbm  $cluedir/";
	system "mv $dbm\.head  $cluedir/";
    }
}


#----------------------------------------------------------------------------
# Giza2Uplug: convert GIZA's Viterbi alignment to Uplug format (XML)
# (slow and risky: GIZA's output must be complete and use a certain format)

sub Giza2Uplug{
    my $dir=shift;
    my $bitext=shift;
    my $param=shift;
    my $links=shift;
    my $inverse=shift;

    if (ref($links) ne 'HASH'){return 0;}
    my $input=Uplug::IO::Any->new($bitext);
    if (not ref($input)){return 0;}
    if (not $input->open('read',$bitext)){return 0;}
    my $output=Uplug::IO::Any->new($links);
    if (not ref($output)){return 0;}
    $output->addheader($BitextHeader);
    if (not $output->open('write',$links)){return 0;}

    #------------------------------------------------------------------------
    my $giza=$dir.'/GIZA++.A3.final';
    open F,"<$giza";
    #------------------------------------------------------------------------

    my $TokenLabel='w';
    my $data=Uplug::Data::Align->new();
    print STDERR "convert GIZA's Viterbi alignment to XML!\n";
    my $count=0;

    while ($input->read($data)){

	$count++;
	if (not ($count % 100)){
	    $|=1;print STDERR '.';$|=0;
	}
	if (not ($count % 1000)){
	    $|=1;print STDERR "$count\n";$|=0;
	}

	#----------------------------------
	# do the same as for Bitext2Text!!
	# (to check for empty strings ...)
	#
	my @SrcNodes=();
	my @TrgNodes=();
	my ($srctxt,$trgtxt)=
	    &BitextStrings($data,$param,\@SrcNodes,\@TrgNodes);
	if (($srctxt!~/\S/) or ($trgtxt!~/\S/)){next;}
	#----------------------------------

#	my $SrcData=$data->sourceData();
#	my $TrgData=$data->targetData();
#
#	my @SrcNodes=$SrcData->findNodes($TokenLabel);
	my @SrcIds=$data->attribute(\@SrcNodes,'id');
	my @SrcSpans=$data->attribute(\@SrcNodes,'span');
	my @SrcTokens=$data->content(\@SrcNodes);

#	my @TrgNodes=$TrgData->findNodes($TokenLabel);
	my @TrgIds=$data->attribute(\@TrgNodes,'id');
	my @TrgSpans=$data->attribute(\@TrgNodes,'span');
	my @TrgTokens=$data->content(\@TrgNodes);

	if ((not @SrcNodes) or (not @TrgNodes)){next;}

	$_=<F>;
	$_=<F>;
	chomp;
	my @src=split(/ /);
	$_=<F>;
	chomp;

	my %align=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    if ($2){push (@{$align{$2}},$count);}
	    $count++;
	}
	foreach (sort keys %align){
	    my @s;my @t;
	    if ($inverse){
		@t=@{$align{$_}};
		@s=split(/\s/);
	    }
	    else{
		@s=@{$align{$_}};
		@t=split(/\s/);
	    }

	    my @src=();my @trg=();
	    foreach (@s){push (@src,$SrcTokens[$_-1]);}
	    foreach (@t){push (@trg,$TrgTokens[$_-1]);}
	    my @srcId=();my @trgId=();
	    foreach (@s){push (@srcId,$SrcIds[$_-1]);}
	    foreach (@t){push (@trgId,$TrgIds[$_-1]);}
	    my @srcSpan=();my @trgSpan=();
	    foreach (@s){push (@srcSpan,$SrcSpans[$_-1]);}
	    foreach (@t){push (@trgSpan,$TrgSpans[$_-1]);}

	    my %link=();
	    $link{link}=join ' ',@src;
	    $link{link}.=';';
	    $link{link}.=join ' ',@trg;
	    $link{source}=join '+',@srcId;
	    $link{target}=join '+',@trgId;
	    $link{src}=join '&',@srcSpan;
	    $link{trg}=join '&',@trgSpan;

	    $data->addWordLink(\%link);
	}

	$output->write($data);
    }
    $input->close;
    $output->close;
}

#----------------------------------------------------------------------------
# RunGiza: run GIZA++ using external scripts
# (GIZA must be installed in the given directory)

sub RunGiza{
    my $dir=shift;
    my $src=shift;
    my $trg=shift;

    if (my $sig=system "$GIZADIR/plain2snt.out $src $trg"){
	die "got signal $? from plain2snt!\n";
    }
    my $command="PATH=\$\{PATH\}:$GIZADIR;";
    my $snt="$src$trg\.snt";
    if (not -e $snt){$snt="$src\_$trg\.snt";}
    if (not -e $snt){die "cannot find alignment-file: $snt!\n";}
    $command.="$GIZADIR/trainGIZA++.sh $src\.vcb $trg\.vcb $snt";
    if (my $sig=system $command){
	die "got signal $? from trainGIZA++.sh!\n";
    }
}

#----------------------------------------------------------------------------
# Bitext2Text: convert bitexts from Uplug format (XML) to GIZA's format
# (this is much too slow ....)

sub Bitext2Text{
    my $bitext=shift;
    my $srcfile=shift;
    my $trgfile=shift;
    my $param=shift;

    my %SrcStream=('format'=>'text','file'=>$srcfile);
    my %TrgStream=('format'=>'text','file'=>$trgfile);

    my $input=Uplug::IO::Any->new($bitext);
    my $source=Uplug::IO::Any->new(\%SrcStream);
    my $target=Uplug::IO::Any->new(\%TrgStream);
    $input->open('read',$bitext);
    $source->open('write',\%SrcStream);
    $target->open('write',\%TrgStream);

    #-------------------------------------------------------------------------

    my $data=Uplug::Data::Align->new();

    print STDERR "convert bitext to plain text!\n";
    my $count=0;
    while ($input->read($data)){
	$count++;
	if (not ($count % 100)){
	    $|=1;print STDERR '.';$|=0;
	}
	if (not ($count % 1000)){
	    $|=1;print STDERR "$count\n";$|=0;
	}

	my ($srctxt,$trgtxt)=&BitextStrings($data,$param);

	if (($srctxt=~/\S/) and ($trgtxt=~/\S/)){
	    $source->write($srctxt);
	    $target->write($trgtxt);
	}
    }
    $BitextHeader=$input->header;
    $input->close;
    $source->close;
    $target->close;
}

#----------------------------------------------------------------------------
# get the actual strings from the bitext (using feature-parameters)
# (feature specifications as in coocfreq.pl)

sub BitextStrings{
    my $data=shift;
    my $param=shift;
    my ($srcnodes,$trgnodes)=@_;

    my @srctok=$data->getSrcTokenFeatures($param,$srcnodes);
    my @trgtok=$data->getTrgTokenFeatures($param,$trgnodes);

    map($_=~s/^\s+//sg,@srctok);         # delete initial white-space
    map($_=~s/^\s+//sg,@trgtok);
    map($_=~s/(\S)\s+$/$1/sg,@srctok);   # delete final white-space
    map($_=~s/(\S)\s+$/$1/sg,@trgtok);

    map($_=~s/\n/ /sg,@srctok);          # otherwise: convert to space
    map($_=~s/\n/ /sg,@trgtok);
    map($_=~s/\s/\_/sg,@srctok);         # and replace space with underline
    map($_=~s/\s/\_/sg,@trgtok);         # (to avoid extra tokens)
	
    my $srctxt=join(' ',@srctok);
    my $trgtxt=join(' ',@trgtok);

    $srctxt=~tr/\n/ /;
    $trgtxt=~tr/\n/ /;
    return ($srctxt,$trgtxt);
}

#----------------------------------------------------------------------------

sub GetDefaultIni{

    my $DefaultIni = {
  'module' => {
    'name' => 'run giza',
    'program' => 'giza.pl',
    'location' => '$UplugBin',
    'stdout' => 'bitext',
  },
  'input' => {
    'bitext' => {
      'format' => 'xces align',
    },
  },
  'output' => {
    'bitext' => {
      'format' => 'xces align',
      'write_mode' => 'overwrite',
    }
  },
  'parameter' => {
     'alignment direction' => 'src-trg',  # alt.: 'trg-src' or 'both'
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:bitext:file',
       'out' => 'output:bitext:file',
    }
  },
};
    return %{$DefaultIni};
}
