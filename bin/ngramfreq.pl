#!/usr/bin/perl
#
# ngramfreq.pl: count n-gram frequencies
#
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
# $Id$
#
# usage: 
#
#

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::IO::Any;
use Uplug::Data::Lang;
use Uplug::Data;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='ngramfreq.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=             # input stream
    each %{$IniData{'input'}};
my ($OutputStreamName,$OutputStream)=             # output stream
    each %{$IniData{'output'}};

my $input=Uplug::IO::Any->new($InputStream);
my $ngramfreq=Uplug::IO::Any->new($OutputStream);

#---------------------------------------------------------------------------

$input->open('read',$InputStream);
$ngramfreq->open('write',$OutputStream);

#---------------------------------------------------------------------------

my $Param={};
$Param=$IniData{parameter};

my $MinFreq=$IniData{parameter}{token}{'minimal frequency'};
my $lang=$IniData{parameter}{token}{'language'};
my $ExclStop=$IniData{parameter}{token}{'exclude stop words'};

my $MinLen=$IniData{parameter}{token}{'minimal ngram length'};
my $MaxLen=$IniData{parameter}{token}{'maximal ngram length'};

my $PrintProgr=$IniData{'parameter'}{'runtime'}{'print progress'};
my $Buffer=$IniData{'parameter'}{'runtime'}{'buffer'};
my $MaxSegments=$IniData{'parameter'}{'runtime'}{'max nr of segments'};

my %First;

#---------------------------------------------------------------------------

if ($PrintProgr){
    print STDERR "read sentences\n";
}

my $count=0;
my $SegCount=0;
my %NgramFreq;
my %LenFreq;
my %LenTypeFreq;
my $TotalFreq;

my $data=Uplug::Data::Lang->new($lang);

my $time=time();
while ($input->read($data)){
    $count++;
    $SegCount++;

    if ($PrintProgr){
	if (not ($SegCount % 100)){
	    $|=1;
	    print STDERR "$SegCount segments (";
	    print STDERR time()-$time;
	    print STDERR " sec, $TotalFreq)\n";
	    $|=0;
	    if ($MaxSegments){
		if ($SegCount>$MaxSegments){last;}
	    }
	}
    }

    my @Nodes=();
    my @Ngrams=$data->getPhrases($$Param{token},\@Nodes);

    foreach my $t (0..$#Ngrams){
	if ($ExclStop and $data->isStopWord($Ngrams[$t])){next;}
	my $len=$#{$Nodes[$t]};
	if (($len==0) or (($len>$MinLen-3) and ($len<$MaxLen))){
	    if (not defined $NgramFreq{$Ngrams[$t]}){
		$TotalFreq++;
		$LenTypeFreq{$len+1}++;
	    }
	    $NgramFreq{$Ngrams[$t]}++;
	    $LenFreq{$len+1}++;
	}
	if ($Buffer and (not ($TotalFreq % $Buffer))){
	    &WriteFreq($ngramfreq,\%NgramFreq,$MinFreq,$PrintProgr);
	}
    }
}
$input->close;

#---------------------------------------------------------------------------

&WriteFreq($ngramfreq,\%NgramFreq,$MinFreq,$PrintProgr);

my %header=%{$$Param{token}};
$header{'ngram type freq'}=$TotalFreq;
foreach (keys %LenFreq){
    $header{"$_-gram freq"}=$LenFreq{$_};
    $header{"$_-gram type freq"}=$LenTypeFreq{$_};
}
$ngramfreq->addheader(\%header);
$ngramfreq->writeheader;
$ngramfreq->close;


#---------------------------------------------------------------------------

sub WriteFreq{
    my ($stream,$TokFreq,$MinFreq,$PrintProgr)=@_;
    my $src;
    if ($PrintProgr){
	print STDERR "write frequencies\n";
    }
    foreach (keys %{$TokFreq}){


	my $total=$$TokFreq{$_};
	my $freq=$total;
	if ($First{$stream}){
	    if ($total<$MinFreq){                   # if freq < MinPairFreq
		my $sel=Uplug::Data->new;         #   query the database
		my %pattern=('token' => $_);        #   and get the total freq
		if ($stream->select($sel,\%pattern)){
		    $total+=$sel->attribute('freq');
		}
	    }
	}
	if ($total<$MinFreq){next;}

	my $data=Uplug::Data->new;
	$data->setAttribute('token',$_);
	$data->setAttribute('freq',$freq);
	$stream->write($data);
	delete $$TokFreq{$_};
    }
    $First{$stream}=1;
}











#---------------------------------------------------------------------------

sub GetDefaultIni{

    my $DefaultIni = {
  'module' => {
    'name' => 'N-gram frequencies',
    'program' => 'ngramfreq.pl',
    'location' => '$UplugBin',
    'stin' => 'text',
    'stdout' => 'text',
  },
  'input' => {
    'text' => {
      'write_mode' => 'write',
      'format' => 'xml',
      'root' => 's',
    }
  },
  'output' => {
    'ngram freq' => {
      'format' => 'DBM',
      'key' => ['token'],
      'write_mode' => 'overwrite',
    },
  },
  'parameter' => {
    'token' => {
      'minimal frequency' => 2,
      'minimal length' => 1,
      'minimal ngram length' => 2,
      'maximal ngram length' => 3,
      'use attribute' => 'stem',
#      'grep token' => 'contains alphabetic',
      'lower case' => 1,
      'exclude stop words' => 0,
      'language' => 'default',
      'token label' => 'w',
    },
    'runtime' => {
      'print progress' => 1,
      'max nr of segments' => 0,
      'buffer' => 10000000,
    },
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:text:file',
       'infile' => 'input:text:file',
       'informat' => 'input:text:format',
       'max' => 'parameter:runtime:max nr of segments',
       'out' => 'output:ngram freq:file',
       'freq' => 'output:ngram freq:file',
       'ngram' => 'output:ngram freq:file',
       'lang' => 'parameter:token:language',
    }
  },
};
    return %{$DefaultIni};
}
