#!/usr/bin/perl
#
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
# $Id$
# 
#
# usage: 
#
#

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::Data::Align;
use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;
use Uplug::StrSim;


#---------------------------------------------------------------------------
# read config-file and check arguments

my %IniData=&GetDefaultIni;
my $IniFile='strsim.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------
# open input and output data streams

my ($InputStreamName,$InputStream)=                    # input stream
    each %{$IniData{'input'}};
my $SimStream=$IniData{output}{'string similarities'}; # output: string pairs

my $input=Uplug::IO::Any->new($InputStream);
my $strsim=Uplug::IO::Any->new($SimStream);

$input->open('read',$InputStream);
if (not $strsim->open('write',$SimStream)){exit;}

#---------------------------------------------------------------------------
# set script parameters

my $Param={};
$Param=$IniData{parameter};

my $freq=$IniData{parameter}{token}{'minimal frequency'};
my %MinFreq;
$MinFreq{source}=$IniData{parameter}{token}{'minimal frequency (source)'};
$MinFreq{target}=$IniData{parameter}{token}{'minimal frequency (target)'};
my %lang;
$lang{source}=$IniData{parameter}{token}{'language (source)'};
$lang{target}=$IniData{parameter}{token}{'language (target)'};
my %ExclStop;
$ExclStop{source}=$IniData{parameter}{token}{'exclude stop words (source)'};
$ExclStop{target}=$IniData{parameter}{token}{'exclude stop words (target)'};

my $PrintProgr=$IniData{parameter}{runtime}{'print progress'};
my $Buffer=$IniData{parameter}{runtime}{buffer};

my $sim_measure=$IniData{parameter}{'similarity measures'}{metrics};
my $precision=$IniData{parameter}{'similarity measures'}{precision};
my $use_weights=$IniData{parameter}{'similarity measures'}{'use weights'};
my $use_nm_weights=
    $IniData{parameter}{'similarity measures'}{'use not-matching-weights'};
my $use_Ngrams=1;
if (defined $IniData{parameter}{'similarity measures'}{'use N-grams'}){
    my $use_Ngrams=$IniData{parameter}{'similarity measures'}{'use N-grams'};
}
my $MinScore=$IniData{parameter}{'similarity measures'}{'minimal score'};
my $rmLinked=$IniData{parameter}{token}{'remove linked'};

my $delimiter='';

#---------------------------------------------------------------------------

if ($PrintProgr){
    print STDERR "read alignments\n";
}

#---------------------------------------------------------------------------
# main part
#   0) initialize some variables

my $count=0;
my $AlignCount=0;
my %SimScores;
my %SrcFreq;
my %TrgFreq;
my ($TotalCooc,$TotalSrc,$TotalTrg);
my %weights;
my (%SrcNMngrams,%TrgNMngrams);

my ($nrSrc,$nrTrg);
my $nrTotal=0;
my $nrPairs=0;

my $data=Uplug::Data::Align->new($lang{source},$lang{target});


#---------------------------------------------------------------------
# 1) loop: read all bitext segments and calculate similarities between
#          source and target language items (words and MWUs)

my $time=time();
while ($input->read($data)){
    $AlignCount++;
    if ($rmLinked){
	$data->rmLinkedToken($data);
    }

    #---------------------------------------------------------------------
    # verbose-mode:
    #
    if ($PrintProgr){
	if (not ($AlignCount % 100)){
	    #
	    # print info each 100 bitext segments:
	    #    nr-of-segments (time: processing-time in seconds,
	    #                    nr-of-source-items:nr-of-target-items ->
	    #                    nr-of-saved-pairs/nr-of-total-pairs)
	    #
	    # nr-of-saved-pairs: pairs that have been saved in the score-hash
	    # nr-of-total-pairs: nr of pairs in the last 100 bitext segments
	    #
	    $|=1;print STDERR "$AlignCount segments (time: ";
	    print STDERR time()-$time;
	    print STDERR " sec, $nrSrc:$nrTrg -> $nrPairs/$nrTotal)\n";
	    $|=0;
	    $nrSrc=0;$nrTrg=0;$nrTotal=0;$nrPairs=0;
	}
	if (not ($AlignCount % 10)){
	    $|=1;print STDERR '.';$|=0;
	}
    }
    #---------------------------------------------------------------------

    my (%Ngrams,%NgramPos);
    my @SrcNodes=();
    my @TrgNodes=();
    @{$Ngrams{source}}=$data->getSrcPhrases($$Param{token},\@SrcNodes);
    @{$Ngrams{target}}=$data->getTrgPhrases($$Param{token},\@TrgNodes);

    $nrSrc+=$#{$Ngrams{source}};
    $nrTrg+=$#{$Ngrams{target}};

    foreach my $src (@{$Ngrams{source}}){
	if ($ExclStop{source} and $data->{source}->isStopWord($src)){next;}
	foreach my $trg (@{$Ngrams{target}}){

	    $nrTotal++;
	    if (defined $SimScores{$src}{$trg}){next;}
	    if ($data->lengthQuotient($src,$trg)<$MinScore){next;}
	    if ($ExclStop{target} and $data->{target}->isStopWord($trg)){next;}
	    if (not $data->checkPairParameter($src,$trg,$$Param{token})){next;}

	    $count++;
	    if ($Buffer and ($count>$Buffer)){
		&WritePairs($strsim,\%SimScores,$MinScore,$PrintProgr);
		$count=0;
	    }

#-----------------------------------------------------------------------------
# everything's ok!
# --> calculate similarity scores!
#-----------------------------------------------------------------------------

	    my $score;
	    if ($use_weights){
		$score=&similar($src,$trg,$sim_measure,1,\%weights,$delimiter);
	    }
	    elsif($use_nm_weights){
		$score=&WeightedSimilarity($src,$trg,\%weights,
					   \%SrcNMngrams,\%TrgNMngrams);
	    }
	    else{
		$score=&similar($src,$trg,$sim_measure,1,undef,$delimiter);
	    }

	    if ($precision){                               # truncate scores
		$score=int($score*10**$precision+0.5)/     # (precision=
		    (10**$precision);                      #   number of dec)
	    }

	    $nrPairs++;
	    $SimScores{$src}{$trg}=$score;
	}
    }
}
$input->close;

#---------------------------------------------------------------------
# write pairs with scores to the database

&WritePairs($strsim,\%SimScores,$MinScore,$PrintProgr);

$input->close;
my %header = ('align count' => $AlignCount,             # save some counts
	      'token pair count' => $TotalCooc);        # in the header
$strsim->addheader(\%header);
$strsim->addheader($$Param{token});
$strsim->writeheader;
$strsim->close;


# end of main
#---------------------------------------------------------------------




sub WeightedSimilarity{
    my ($src,$trg,$weights,$SrcNMngrams,$TrgNMngrams)=@_;
    my %non;
    my ($score)=&GetNonMatches($src,$trg,\%non);

    my ($s,$t);
    my $oldsc=$score;
    foreach $s (keys %non){
	foreach $t (keys %{$non{$s}}){
	    my $pat='';
	    if ((ref($SrcNMngrams) eq 'HASH')and(ref($TrgNMngrams) eq 'HASH')){
		$pat='#';
		my @NonSrc=&GetSubStrings($s,$SrcNMngrams,
					  undef,20,'');
		$s=join('#',@NonSrc);
		my @NonTrg=&GetSubStrings($t,$TrgNMngrams,
					  undef,20,'');
		$t=join('#',@NonTrg);
	    }
	    $score+=&LCS($s,$t,$weights,$pat);
#	  if ($score>$oldsc){
#	      print "-($s|$t)-";
#	  }
	}
    }
#	  if ($score>$oldsc){
#	     print "\t\t$oldsc -> $score ($SrcNgram[$src]|$TrgNgram[$trg])\n";
#	  }
    if (length($src)>
	length($trg)){
	$score/=length($src);
    }
    else{
	$score/=length($trg);
    }
    return $score;
}

sub WritePairs{
    my ($stream,$SimScore,$MinScore,$PrintProgr)=@_;
    if ($PrintProgr){
	print STDERR "write scores\n";
    }
    my ($src,$trg);
    my $data=Uplug::Data->new;
    foreach $src (keys %{$SimScore}){
	foreach $trg (keys %{$$SimScore{$src}}){
	    if ($MinScore){
		if ($$SimScore{$src}{$trg}<$MinScore){next;}
	    }
	    $data->init();
	    $data->setAttribute('source',$src);
	    $data->setAttribute('target',$trg);
	    $data->setAttribute('score',$$SimScore{$src}{$trg});
	    $stream->write($data);
	    delete $$SimScore{$src}{$trg};
	}
	if (not keys %{$$SimScore{$src}}){
	    delete $$SimScore{$src};
	}
    }
}


sub GetDefaultIni{

    my $DefaultIni = {
  'module' => {
    'program' => 'strsim.pl',
    'location' => '$UplugBin',
    'name' => 'LCSR - the longest common sub-sequence ratio',
#    'stdin' => 'bitext',
  },
  'description' => 'The longest common sub-sequence ratio is
  calculated for co-occurring words and chunks.',
  'input' => {
    'bitext' => {
	'format' => 'xces align',
    }
  },
  'output' => {
    'string similarities' => {
      'stream name' => 'string similarities',
    },
  },
  'parameter' => {
    'token' => {
      'chunks (source)' => 'c.*',            # use chunks
      'chunks (target)' => 'c.*',            # use chunks
#      'minimal length diff' => 0.3,
#     'matching word class' => 'same',       # don't mix content and stop words
      'minimal frequency' => 1,
      'minimal frequency (source)' => 1,
      'minimal frequency (target)' => 1,
      'minimal length (source)' => 3,
      'minimal length (target)' => 3,
      'maximal ngram length (source)' => 1,  # >1 --> use N-grams
      'maximal ngram length (target)' => 1,  # >1 --> use N-grams
#      'use attribute (source)' => 'none',
#      'use attribute (target)' => 'none',
#      'grep token (source)' => 'contains alphabetic',
#      'grep token (target)' => 'contains alphabetic',
      'lower case (source)' => 1,
      'lower case (target)' => 1,
      'exclude stop words (source)' => 1,
      'exclude stop words (target)' => 1,
#      'language (source)' => 'english',
#      'language (target)' => 'swedish',
      'language (source)' => 'default',
      'language (target)' => 'default',
      'delimiter' => '\\s+',
      'token label' => 'w',
      'remove linked' => 0,
    },
    'similarity measures' => {
      'minimal score' => 0.4,
      'use not-matching-weights' => 0,
      'use N-grams' => 0,
      'metrics' => 'lcsr',
#      'precision' => 4,
      'use weights' => 0,
    },
    'runtime' => {
      'print progress' => 1,
      'buffer' => 2000000,
    },
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:bitext:format',
       'infile' => 'input:intext:file',
       'informat' => 'input:intext:format',
       'out' => 'output:string similarities:file',
       'outformat' => 'output:string similarities:format',
       'srclang' => 'parameter:token:language (source)',
       'trglang' => 'parameter:token:language (target)',
    }
  },
  'widgets' => {
  }
};

    return %{$DefaultIni};
}
