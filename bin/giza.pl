#!/usr/bin/perl
#
# giza.pl: wrapper for Giza++
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
#----------------------------------------------------------------------------
#
# 

use strict;
use Cwd;
use FindBin qw($Bin);
use File::Copy;
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
my $combined=$IniData{parameter}{'symmetric alignment'};
if ($combined){$direction='both';}


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
mkdir $TmpDir,0755;
my $SrcFile=$TmpDir."/src";
my $TrgFile=$TmpDir."/trg";
my $BitextHeader;



&Bitext2Text($InputStream,$SrcFile,$TrgFile,$TokenParam);

if (($direction eq 'trg-src') or ($direction eq 'both')){
    chdir $TmpDir;
    &RunGiza($TmpDir,'trg','src');
    if ($combined){copy ('GIZA++.A3.final','trg-src.viterbi');}
    chdir $PWD;
    if ((ref($OutputStream) eq 'HASH') and (not $combined)){
	&Giza2Uplug($TmpDir,$InputStream,$TokenParam,$OutputStream,1);
    }
    if ($makeclue){
	&Giza2Clue($TmpDir,$TokenParam,1);
    }
}
if (($direction eq 'src-trg') or ($direction eq 'both')){
    chdir $TmpDir;
    &RunGiza($TmpDir,'src','trg');
    if ($combined){copy ('GIZA++.A3.final','src-trg.viterbi');}
    chdir $PWD;
    if ((ref($OutputStream) eq 'HASH') and (not $combined)){
#    if (ref($OutputStream) eq 'HASH'){
	&Giza2Uplug($TmpDir,$InputStream,$TokenParam,$OutputStream,0);
    }
    if ($makeclue){
	&Giza2Clue($TmpDir,$TokenParam,0);
    }
}

if ($combined){
    &Combined2Uplug($TmpDir.'/src-trg.viterbi',
		    $TmpDir.'/trg-src.viterbi',$combined,$InputStream,$TokenParam,$OutputStream);
}

#foreach my $d (@align){
#    chdir $TmpDir.$d;
#    if ($d){&RunGiza($TmpDir.$d,'trg','src');}
#    else{&RunGiza($TmpDir.$d,'src','trg');}
#    chdir $PWD;
#    if (ref($OutputStream) eq 'HASH'){
#	&Giza2Uplug($TmpDir,$InputStream,$TokenParam,$OutputStream,$d);
#    }
#    if ($makeclue){
#	&Giza2Clue($TmpDir,$TokenParam,$d);
#    }
#}


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
# Combined2Uplug: combine GIZA's Viterbi alignment and convert them to Uplug format (XML)
# (slow and risky: GIZA's output must be complete and must use a certain format)
#
# possible combinatins: union, intersection, refined
#

sub Combined2Uplug{
    my $giza0=shift;
    my $giza1=shift;
    my $combine=shift;
    my $bitext=shift;
    my $param=shift;
    my $links=shift;

    if (ref($links) ne 'HASH'){return 0;}
    my $input=Uplug::IO::Any->new($bitext);
    if (not ref($input)){return 0;}
    if (not $input->open('read',$bitext)){return 0;}
    my $output=Uplug::IO::Any->new($links);
    if (not ref($output)){return 0;}
    $output->addheader($BitextHeader);
    if (not $output->open('write',$links)){return 0;}

    #------------------------------------------------------------------------
    open F0,"<$giza0";
    open F1,"<$giza1";
    #------------------------------------------------------------------------

    my $TokenLabel='w';
    my $data=Uplug::Data::Align->new();
    print STDERR "combine GIZA's Viterbi alignments and convert to XML!\n";
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

#	my @SrcNodes=$SrcData->findNodes($TokenLabel);
	my @SrcIds=$data->attribute(\@SrcNodes,'id');
	my @SrcSpans=$data->attribute(\@SrcNodes,'span');
	my @SrcTokens=$data->content(\@SrcNodes);

#	my @TrgNodes=$TrgData->findNodes($TokenLabel);
	my @TrgIds=$data->attribute(\@TrgNodes,'id');
	my @TrgSpans=$data->attribute(\@TrgNodes,'span');
	my @TrgTokens=$data->content(\@TrgNodes);

	if ((not @SrcNodes) or (not @TrgNodes)){next;}

	$_=<F1>;$_=<F1>;chomp;    # read source->target viterbi alignment
	my @src=split(/ /);
	$_=<F1>;chomp;
	my %srclinks=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    my @s=split(/\s/,$2);
	    foreach (@s){$srclinks{$_}{$count}=1;}
	    $count++;
	}


	$_=<F0>;$_=<F0>;chomp;    # read source->target viterbi alignment
	my @trg=split(/ /);
	$_=<F0>;chomp;
	my %trglinks=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    my @t=split(/\s/,$2);
	    foreach (@t){$trglinks{$_}{$count}=1;}
	    $count++;
	}

	my (%CombinedSrc,%CombinedTrg);
	&CombineLinks(\%srclinks,\%trglinks,$combine,\%CombinedSrc,\%CombinedTrg);
	my @cluster=&LinkClusters(\%CombinedSrc,\%CombinedTrg);

	foreach my $c (@cluster){
#	    my @s=sort {$a <=> $b} keys %{$cluster[$_]{src}};
#	    my @t=sort {$a <=> $b} keys %{$cluster[$_]{trg}};

	    my @s=@{$$c{src}};
	    my @t=@{$$c{trg}};

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


sub LinkClusters{
    my ($src,$trg)=@_;
    my @cluster=();
    while (keys %{$src}){
	my ($s,$links)=each %{$src};            # get the next source token
	if ((ref($$src{$s}) ne 'HASH') or
	    (not keys %{$$src{$s}})){           # if no links exist:
	    delete $$src{$s};                   # delete and next!
	    next;
	}
	push (@cluster,{src=>[],trg=>[]});      # create a new link cluster
	push (@{$cluster[-1]{src}},$s);         #  and save it in the cluster
	&AddLinks($cluster[-1],$src,$trg,$s,    # add all tokens aligned to the
		  'src','trg');                 #  source token to the cluster
    }                                           #  (and recursively the ones

    foreach my $c (@cluster){
	@{$$c{src}}=sort {$a <=> $b} @{$$c{src}};
	@{$$c{trg}}=sort {$a <=> $b} @{$$c{trg}};
    }
    return @cluster;
}                                               #   linked to them, see AddLinks)

sub AddLinks{
    my ($cluster,$src,$trg,$s,$key1,$key2)=@_;
    foreach my $t (keys %{$$src{$s}}){          # add all linked tokens to the
	delete $$src{$s}{$t};                   # cluster and delete the links
	delete $$trg{$t}{$s};                   # in the link-hashs
	push (@{$$cluster{$key2}},$t);
	&AddLinks($cluster,$trg,$src,$t,$key2,$key1); # add tokens aligned to the
    }                                                 # linked token to the cluster
    delete $$src{$s};                           # delete the source token link hash
}



sub CombineLinks{
    my ($src,$trg,$method,$srclinks,$trglinks)=@_;
#    my %srclinks;
#    my %trglinks;
    if ($method eq 'union'){
	foreach my $s (keys %{$src}){
	    foreach my $t (keys %{$$src{$s}}){
		$$srclinks{$s}{$t}=1;
		$$trglinks{$t}{$s}=1;
	    }
	}
	foreach my $t (keys %{$trg}){
	    foreach my $s (keys %{$$trg{$t}}){
		$$srclinks{$s}{$t}=1;
		$$trglinks{$t}{$s}=1;
	    }
	}
    }
    elsif (($method eq 'intersection') or ($method eq 'refined')){
	foreach my $s (keys %{$src}){
	    foreach my $t (keys %{$$src{$s}}){
		if ($$trg{$t}{$s}){
		    $$srclinks{$s}{$t}=1;
		    $$trglinks{$t}{$s}=1;
		}
	    }
	}
    }
    if ($method eq 'refined'){                   # refined combination:
	foreach my $s (keys %{$src}){            # * start with the intersection
	    foreach my $t (keys %{$$src{$s}}){   # * go iteratively through other links
		if ((not defined $$srclinks{$s}) and
		    (not defined $$trglinks{$t})){       #   - if both are not aligned yet:
		    $$srclinks{$s}{$t}=1;                #     add the link
		    $$trglinks{$t}{$s}=1;
		}
		elsif ((defined $$srclinks{$s-1}) or
		       (defined $$srclinks{$s+1})){
		    if (($$srclinks{$s-1}{$t}) or         # if the link is adjacent to
			   ($$srclinks{$s+1}{$t})){       # another one horizontally:
			if ($$srclinks{$s}{$t+1}){next;}  # do not accept if it is also
			if ($$srclinks{$s}{$t-1}){next;}  # adjacent to other links vertically
			if ($$srclinks{$s-1}{$t}){              # do not accept if the adjacent
			    if ($$srclinks{$s-1}{$t-1}){next;}  # link is also adjacent to other
			    if ($$srclinks{$s-1}{$t+1}){next;}  # links vertically
			}
			if ($$srclinks{$s+1}{$t}){              # the same for the other
			    if ($$srclinks{$s+1}{$t-1}){next;}  # adjacency direction
			    if ($$srclinks{$s+1}{$t+1}){next;}
			}
			$$srclinks{$s}{$t}=1;        # everything ok: add the link
			$$trglinks{$t}{$s}=1;
		    }
		}
		elsif ((defined $$trglinks{$t-1}) or
		       (defined $$trglinks{$t+1})){
		    if (($$srclinks{$s}{$t-1}) or         # if the link is adjacent to
			($$srclinks{$s}{$t+1})){          # another one vertically:
			if ($$srclinks{$s+1}{$t}){next;}  # do not accept if it is also
			if ($$srclinks{$s-1}{$t}){next;}  # adjacent to other links horizontally
			if ($$srclinks{$s}{$t-1}){              # do not accept if the adjacent
			    if ($$srclinks{$s-1}{$t-1}){next;}  # link is also adjacent to other
			    if ($$srclinks{$s+1}{$t-1}){next;}  # links horizontally
			}
			if ($$srclinks{$s}{$t+1}){              # the same for the other
			    if ($$srclinks{$s-1}{$t+1}){next;}  # adjacency direction
			    if ($$srclinks{$s+1}{$t+1}){next;}
			}
			$$srclinks{$s}{$t}=1;        # everything ok: add the link
			$$trglinks{$t}{$s}=1;
		    }
		}
	    }
	}
    }
#    $src=\%srclinks;
#    $trg=\%trglinks;
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
       'd' => 'parameter:alignment direction',
       'c' => 'parameter:symmetric alignment'
    }
  },
};
    return %{$DefaultIni};
}
