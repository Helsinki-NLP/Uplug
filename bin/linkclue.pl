#!/usr/bin/perl
# -*-perl-*-
# 
# linkclue.pl
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
# usage:  
#

BEGIN{
    use strict;
    use FindBin qw($Bin);
    use lib "$Bin/../lib";
    $ENV{UPLUGHOME}="$Bin/../" unless (defined $ENV{UPLUGHOME});
}

use Uplug::Data::Align;
use Uplug::Data;
# use Uplug::Data::DOM;
use Uplug::IO::Any;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='linkclue.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=           # take only 
    each %{$IniData{'input'}};                # the first input stream
my $OutDbm=$IniData{output};

if (not $InputStreamName){die "# LinkClue: no input stream!\n";}
if (ref($InputStream) ne 'HASH'){die "# LinkClue: no input stream!\n";}
if (ref($OutDbm) ne 'HASH'){die "# LinkClue: cannot find output streams";}

#---------------------------------------------------------------------------
# open input data stream

my $input=Uplug::IO::Any->new($InputStream);
if (not $input->open('read',$InputStream)){exit;}
my $header=$input->header;

#---------------------------------------------------------------------------
# open clue dbm's and set feature parameter

my $param=$IniData{parameter};
my %output;
my %feature=();
foreach (keys %{$OutDbm}){
    if (ref($$param{clues}) eq 'HASH'){
	if (not $$param{clues}{$_}){next;}
    }
    if (defined $IniData{parameter}{$_}){
	$feature{$_}=$IniData{parameter}{$_};
    }
    else{
	$feature{$_}=$IniData{parameter}{token};
    }
    if (not defined $feature{$_}{'pair frequency'}){ 
	if (defined $$param{general}{'pair frequency'}){ 
	    $feature{$_}{'pair frequency'}=$$param{general}{'pair frequency'};
	}
    }
    if (not defined $feature{$_}{'min score'}){ 
	if (defined $$param{general}{'min score'}){ 
	    $feature{$_}{'min score'}=$$param{general}{'min score'};
	}
    }
    $output{$_}=Uplug::IO::Any->new($$OutDbm{$_});
    if (not ref($output{$_})){delete $output{$_};next;}
#    print STDERR "new $_\n";
    $output{$_}->addheader($header);
    if (not $output{$_}->open('write',$$OutDbm{$_})){delete $output{$_};}
}
if (not keys %output){die "# LinkClue: no output found!\n";}

#---------------------------------------------------------------------------
# main ....

my $in=Uplug::Data::Align->new;
my $count=0;
my %FeatPair=();
my $PrintProgr=1;

while ($input->read($in)){

    $count++;
    if ($PrintProgr){
	if (not ($count % 500)){$|=1;print STDERR "$count segments\n";$|=0;}
	if (not ($count % 50)){$|=1;print STDERR '.';$|=0;}
    }

#    my $link=$in->{link};
    my $link=$in->linkData();
    my @ids=$link->findNodes('wordLink');

    foreach my $n (0..$#ids){

	my $xtrg=$link->attribute($ids[$n],'xtargets');
	my ($srcID,$trgID)=split(/\;/,$xtrg);

#	$in->subData($in->{source},'source');
	my @srcPhrNodes=&GetPhraseNodes($in->{source},$srcID);
#	$in->subData($in->{target},'target');
	my @trgPhrNodes=&GetPhraseNodes($in->{target},$trgID);

	foreach my $o (keys %output){

	    my $SrcFeat=$in->getSrcPhraseFeature(\@srcPhrNodes,$feature{$o});
	    my $TrgFeat=$in->getTrgPhraseFeature(\@trgPhrNodes,$feature{$o});

	    if (defined $feature{$o}{'relative position'}){
		my $pos=$in->getRelativePosition(\@srcPhrNodes,\@trgPhrNodes);
		if ($TrgFeat=~/\S/){
		    $TrgFeat.=":$pos";
		}
		else{$TrgFeat=$pos;}
		if ($SrcFeat=~/\S/){
		    $SrcFeat.=":x";
		}
		else{$SrcFeat='x';}
	    }

	    $FeatPair{$o}{$SrcFeat}{$TrgFeat}++;
	    $FeatPair{$o}{$SrcFeat}{'__all'}++;
	    $FeatPair{$o}{$TrgFeat}{'__all'}++;
	}
    }
}

$input->close;

foreach my $o (keys %output){
    &SaveFeatDice($FeatPair{$o},$output{$o},$feature{$o});
    $output{$o}->close;
}


#---------------------------------------------------------------------------


sub AddRelPosFeature{
    my ($data,$src,$trg)=@_;
    if (ref($src) and ref($trg)){
	my $srcID=$data->attribute($src,'id');
	my $trgID=$data->attribute($trg,'id');
	if ($srcID=~/(\A|[^0-9])([0-9]+)$/){
	    my $pos=$2;
	    if ($trgID=~/(\A|[^0-9])([0-9]+)$/){
		return $2-$pos;
	    }
	}
    }
    return 0;
}

sub GetPhraseNodes{
    my $data=shift;
    my $idStr=shift;
    my @ids=split(/[\:\+]/,$idStr);
    my @nodes=();
    foreach (@ids){
	my ($node)=$data->findNodes('.*',{id => $_});
	if (ref($node)){
	    push (@nodes,$node);
	}
    }
    if ((not @nodes) and (@ids)){        # in case the nodes haven't been found
	my @n=$data->contentElements();  # (e.g. no IDs in the XML-file)
	foreach (@ids){
	    push (@nodes,$n[$_]);
	}
    }
    return @nodes;
}


sub SaveCondProb{
    my ($pairs,$out,$param)=@_;
    my $minFreq=$param->{'pair frequency'};
    my $minScore=$param->{'min score'};

    &WriteFeatureHeader($out,$param);

    foreach my $s (keys %{$pairs}){
	foreach my $t (keys %{$pairs->{$s}}){
	    if ($t eq '__all'){next;}
	    if ($FeatPair{$s}{'__all'}<$minFreq){next;}
	    $FeatPair{$s}{$t}/=$FeatPair{$s}{'__all'};
	    if ($FeatPair{$s}{$t}<$minScore){next;}
	    my $data=Uplug::Data->new;
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('score',$pairs->{$s}->{$t});
	    $out->write($data);
	}
    }
}

sub SaveFeatDice{
    my ($pairs,$out,$param)=@_;
    my $minFreq=$param->{'pair frequency'};
    my $minScore=$param->{'min score'};

    &WriteFeatureHeader($out,$param);

    foreach my $s (keys %{$pairs}){
	foreach my $t (keys %{$pairs->{$s}}){
	    if ($t eq '__all'){next;}
	    if ($$pairs{$s}{'__all'}<$minFreq){next;}
	    if ($$pairs{$t}{'__all'}<$minFreq){next;}
	    my $score=2*$$pairs{$s}{$t}/
		($$pairs{$s}{'__all'}+$$pairs{$t}{'__all'});
	    if ($score<$minScore){next;}
	    my $data=Uplug::Data->new;
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('score',$score);
	    $out->write($data);
	}
    }
}

sub WriteFeatureHeader{
    my ($out,$param)=@_;
    $out->addheader($param);
    $out->writeheader;
}


sub GetSrcFeature{
    return &GetFeature(@_,'source');
}
sub GetTrgFeature{
    return &GetFeature(@_,'target');
}



sub GetFeature{
    my ($data,$id,$param,$subtree)=@_;

    if (defined $$param{parameter}{"$subtree feature"}{attribute}){
	my $attr=$$param{parameter}{"$subtree feature"}{attribute};
	return &GetAttrFeature($data,$id,$attr);
    }
    if (defined $$param{parameter}{"$subtree feature"}{'relative position'}){
	return &GetRelPos($data,$id,$subtree);
    }
}


sub GetAttrFeature{
    my ($data,$id,$attr)=@_;

    my @features=();
    my @ids=split(/\:/,$id);

    foreach my $i (@ids){
	push (@features,$data->attribute($attr,'.*',{id => $i}));
    }
    return join ' ',@features;
}


my $SrcPos;

sub GetRelPos{
    my ($data,$id,$subtree)=@_;

    my @features=();
    my @ids=split(/\:/,$id);

    foreach my $i (@ids){
	my $pos=-1;
	if ($i=~/(\A|[^0-9])([0-9]+)$/){
	    $pos=$2;
	}
	if ($subtree eq 'source'){
	    $SrcPos=$pos;
	}
	else{
	    $pos-=$SrcPos;
	    push (@features,$pos);
	}
    }
    if ($subtree eq 'source'){return 'x';}
    return join ' ',@features;
}


sub GetDefaultIni{

    my $DefaultIni = {
  'input' => {
    'text' => {
      'format' => 'align',
      'write_mode' => 'write',
      'file' => 'data/align.xml',
    }
  },
  'output' => {
    'feature' => {
      'format' => 'DBM',
      'write_mode' => 'overwrite',
      'file' => 'data/pos.dbm',
      'key' => ['source','target']
    },
  },
  'parameter' => {
    'token' => {
      'relative position' => 1,
       'features (source)' => {
           'pos' => undef,
       },
       'features (target)' => {
           'pos' => undef,
       },
    },
    'general' => {
      'pair frequency' => 4,
#       'min score' => 0.2,
    },
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:text:format',
       'infile' => 'input:text:file',
       'informat' => 'input:text:format',
       'out' => 'output:feature:file',
    }
  },
};
    return %{$DefaultIni};
}
