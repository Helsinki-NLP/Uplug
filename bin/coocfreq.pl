#!/usr/bin/perl
#
# coocfreq.pl: count token frequencies
#
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
#
# $Id$
#
# usage: 
#
#

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;
$Data::Dumper::Purity=1;

use Uplug::IO::Any;
use Uplug::Data;
use Uplug::Data::Align;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='coocfreq.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=             # input data (only one!)
    each %{$IniData{'input'}};

my $SrcVocFile=$IniData{output}{'source vocabulary'}{file};# source vocabulary
my $TrgVocFile=$IniData{output}{'target vocabulary'}{file};# target vocabulary
my $SrcFreqFile=$IniData{output}{'source freq'}{file};     # source freq
my $TrgFreqFile=$IniData{output}{'target freq'}{file};     # target freq
my $CoocFreqFile=$IniData{output}{'cooc freq'}{file};      # co-occurrence freq

#---------------------------------------------------------------------------
# open input/output files

my $input=Uplug::IO::Any->new($InputStream);
$input->open('read',$InputStream);

open SRC,">$SrcVocFile";
open TRG,">$TrgVocFile";
if ($]>=5.008){
    binmode(SRC,':encoding(utf-8)');
    binmode(TRG,':encoding(utf-8)');
}

#---------------------------------------------------------------------------
# check parameters

my $Param={};
$Param=$IniData{parameter};

my $MinPairFreq=$IniData{parameter}{token}{'minimal frequency'};
my %MinFreq=
    (source => $IniData{parameter}{token}{'minimal frequency (source)'},
     target => $IniData{parameter}{token}{'minimal frequency (target)'});
my %lang=
    (source => $IniData{parameter}{token}{'language (source)'},
     target => $IniData{parameter}{token}{'language (target)'});
my %ExclStop=
    (source => $IniData{parameter}{token}{'exclude stop words (source)'},
     target => $IniData{parameter}{token}{'exclude stop words (target)'});
my $rmLinked=$IniData{parameter}{token}{'remove linked'};

my $PrintProgr=$IniData{'parameter'}{'runtime'}{'print progress'};
my $MaxSegments=$IniData{'parameter'}{'runtime'}{'max nr of segments'};


#---------------------------------------------------------------------------

if ($PrintProgr){print STDERR "read alignments\n";}

my %SrcVoc;        # source token hash
my %TrgVoc;        # target token hash

my %CoocFreq;      # token pair frequencies
my %SrcFreq;       # source token frequencies
my %TrgFreq;       # target token frequencies

my $AlignCount=0;                         # bitext segment counter
my ($CoocTypes,$SrcTypes,$TrgTypes);      # type counter
my ($CoocTokens,$SrcTokens,$TrgTokens);   # token counter

#---------------------------------------------------------------------------
# now: read from input and count!

my $time=time();
my $data=Uplug::Data::Align->new($lang{source},$lang{target});

while ($input->read($data)){
    $AlignCount++;

    if ($rmLinked){$data->rmLinkedToken($data);}

    #------------------------------------------------------------
    # print some progress-info

    if ($PrintProgr){
	if (not ($AlignCount % 100)){
	    $|=1;
	    print STDERR "$AlignCount segments (";
	    print STDERR time()-$time;
	    print STDERR " sec, $SrcTypes/$SrcTokens:$TrgTypes/$TrgTokens:$CoocTypes/$CoocTokens)\n";
	    $|=0;
	    if ($MaxSegments){
		if ($AlignCount>$MaxSegments){last;}
	    }
	}
    }
    #------------------------------------------------------------

    my %SrcNgrams=();my %TrgNgrams=();
    $data->getAlignPhrases($$Param{token},\%SrcNgrams,\%TrgNgrams);

    #---------------------------------------
    # count frequencies
    #  0) frequencies in the bigram segment
    #  1) add bigram segment frequencies to the total counts

    {
	my %SentFreq;
	&CountSentFreq(\%SentFreq,\%SrcNgrams,\%TrgNgrams);

	# target token frequencies

	foreach my $t (keys %{$SentFreq{trg}}){
	    if ($ExclStop{target} and $data->{target}->isStopWord($t)){
		next;
	    }
	    if (not defined $TrgVoc{$t}){
		$TrgVoc{$t}=$TrgTypes++;
		print TRG $t,"\n";
	    }
	    $TrgFreq{$TrgVoc{$t}}+=$SentFreq{trg}{$t};    # add frequency
	    $TrgTokens+=$SentFreq{trg}{$t};               # is this correct?
	}

	# source frequencies

	foreach my $s (keys %{$SentFreq{cooc}}){
	    if ($ExclStop{source} and $data->{source}->isStopWord($s)){next;}
	    if (not defined $SrcVoc{$s}){
		$SrcVoc{$s}=$SrcTypes++;
		print SRC $s,"\n";
	    }
	    $SrcFreq{$SrcVoc{$s}}+=$SentFreq{src}{$s};    # add frequency
	    $SrcTokens+=$SentFreq{src}{$s};               # is this correct?

	    # co-occurrence frequencies

	    foreach my $t (keys %{$SentFreq{cooc}{$s}}){
		my $src=$s;my $trg=$t;


		#---------------------------
		# relative position feature is special!
		# count marginal frequencies for each pair!
		
		if ($$Param{token}{'relative position'}){
		    ($src,$trg)=&makeRelPosFeature($src,$trg);
		    if (not defined $TrgFreq{$trg}){
			$TrgVoc{$trg}=$TrgTypes++;
			print TRG $t,"\n";
		    }
		    $TrgFreq{$TrgVoc{$trg}}+=$SentFreq{trg}{$t};
		    $TrgTokens+=$SentFreq{trg}{$t};
		    if (not defined $SrcFreq{$src}){
			$SrcVoc{$src}=$SrcTypes++;
			print SRC $s,"\n";
		    }
		    $SrcFreq{$SrcVoc{$src}}+=$SentFreq{src}{$s};
		    $SrcTokens+=$SentFreq{src}{$s};
		}
		#---------------------------

		if ($ExclStop{target} and $data->{target}->isStopWord($trg)){
		    next;
		}
		if ($data->checkPairParameter($src,$trg,$$Param{token})){

		    $src=$SrcVoc{$src};
		    $trg=$TrgVoc{$trg};
		    if (not defined $CoocFreq{$src}){$CoocTypes++;}
		    elsif (not defined $CoocFreq{$src}{$trg}){$CoocTypes++;}

		    $CoocFreq{$src}{$trg}+=$SentFreq{cooc}{$s}{$t};
		    $CoocTokens+=$SentFreq{cooc}{$s}{$t};
		}
	    }
	}
    }
}
$input->close;

# end of input file
#-----------------------------------------

close SRC;
close TRG;

#---------------------------------------------------------------------------
# write frequencies to files

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;
$Data::Dumper::Purity=1;


if (defined $SrcFreqFile){                        # source token frequencies
    if ($PrintProgr){print STDERR "write source token frequencies\n";}
    open F,">$SrcFreqFile";
    print F '# columns: ["token","freq"]',"\n";
    print F '# type count: ',$SrcTypes,"\n";
    print F '# token count: ',$SrcTokens,"\n";
    foreach (keys %{$$Param{token}}){
	my $a=$_;$a=~s/ (source)//;
	print F '# ',$a,': ',Dumper($$Param{token}{$_}),"\n";
    }
    foreach (keys %SrcFreq){
	if ($SrcFreq{$_}<$MinFreq{source}){next;}
	print F $_,"\t",$SrcFreq{$_},"\n";
	delete $SrcFreq{$_};
    }
    close F;
}


if (defined $TrgFreqFile){                        # target token frequencies
    if ($PrintProgr){print STDERR "write target token frequencies\n";}
    open F,">$TrgFreqFile";
    print F '# columns: ["token","freq"]',"\n";
    print F '# type count: ',$SrcTypes,"\n";
    print F '# token count: ',$SrcTokens,"\n";
    foreach (keys %{$$Param{token}}){
	my $a=$_;$a=~s/ (target)//;
	print F '# ',$a,': ',Dumper($$Param{token}{$_}),"\n";
    }
    foreach (keys %TrgFreq){
	if ($TrgFreq{$_}<$MinFreq{target}){next;}
	print F $_,"\t",$TrgFreq{$_},"\n";
	delete $TrgFreq{$_};
    }
    close F;
}


if (defined $CoocFreqFile){                        # token pair frequencies
    if ($PrintProgr){print STDERR "write pair frequencies\n";}
    open F,">$CoocFreqFile";
    print F '# columns: ["source","target","freq"]',"\n";
    print F '# type pair count: ',$CoocTypes,"\n";
    print F '# token pair count: ',$CoocTokens,"\n";
    print F '# align count: ',$AlignCount,"\n";
    foreach (keys %{$$Param{token}}){
	print F '# ',$_,': ',Dumper($$Param{token}{$_}),"\n";
    }

    foreach my $s (keys %CoocFreq){
	foreach my $t (keys %{$CoocFreq{$s}}){
	    if ($CoocFreq{$s}{$t}<$MinPairFreq){next;}
	    print F $s,"\t",$t,"\t",$CoocFreq{$s}{$t},"\n";
	    delete $CoocFreq{$s}{$t};
	}
	delete $CoocFreq{$s};
    }
    close F;
}


# end of main
#---------------------------------------------------------------------------








#---------------------------------------------------------------------------
# CountSentFreq
#
# count tokens and token pairs in a sentence pair
#     - one type / sentence pair OR
#     - all tokens/token pairs

sub CountSentFreq{
    my ($freq,$src,$trg)=@_;
    foreach my $t (values %{$trg}){
#	$$freq{trg}{$t}=1;                # count trg only once/sentence
	$$freq{trg}{$t}++;                # OR count all trg-tokens
    }
    foreach my $s (values %{$src}){
#	$$freq{src}{$s}=1;                # count src only once/sentence
	$$freq{src}{$s}++;                # OR count all src-tokens
	foreach my $t (values %{$trg}){
#	    $$freq{cooc}{$s}{$t}=1;       # count all src-trg pairs only once
	    $$freq{cooc}{$s}{$t}++;       # OR count all src-trg pairs

#-------------------------------------
# coocfreq <= min (srcfreq,trgfreq)

	    if ($$freq{cooc}{$s}{$t}>$$freq{src}{$s}){
		$$freq{cooc}{$s}{$t}=$$freq{src}{$s};
	    }
	    if ($$freq{cooc}{$s}{$t}>$$freq{trg}{$t}){
		$$freq{cooc}{$s}{$t}=$$freq{trg}{$t};
	    }

#-------------------------------------
# coocfreq <= max (srcfreq,trgfreq)
#
#	    if (($$freq{cooc}{$s}{$t}>$$freq{src}{$s}) and
#		($$freq{cooc}{$s}{$t}>$$freq{trg}{$t})){
#		if ($$freq{trg}{$t}>$$freq{src}{$s}){
#		    $$freq{cooc}{$s}{$t}=$$freq{trg}{$t};
#		}
#		else{
#		    $$freq{cooc}{$s}{$t}=$$freq{src}{$s};
#		}
#	    }
	}
    }
}




sub makeRelPosFeature{
    my ($src,$trg)=@_;
    if ($src=~/pos\((\-?[0-9]+)\)/){
	my $srcPos=$1;
	$src=~s/pos\((\-?[0-9]+)\)/x/;
	if ($trg=~/pos\((\-?[0-9]+)\)/){
	    my $relPos=$1-$srcPos;
	    $trg=~s/pos\((\-?[0-9]+)\)/$relPos/;
	}
    }
    return ($src,$trg);
}


#---------------------------------------------------------------------------

sub GetDefaultIni{

    my $DefaultIni = {
  'module' => {
    'program' => 'coocfreq.pl',
    'location' => '$UplugBin',
    'name' => 'co-occurrence frequency counter',
#    'stdin' => 'bitext',
  },
  'description' => 'This modules counts co-occurrence frequencies of
  words and phrases.',
  'input' => {
    'bitext' => {
	'format' => 'xces align',
    },
  },
  'output' => {
    'cooc freq' => {
	'file' => 'data/runtime/cooc.tab',
	'format' => 'tab',
	'write_mode' => 'overwrite',
    },
    'source freq' => {
	'file' => 'data/runtime/src.tab',
	'format' => 'tab',
	'write_mode' => 'overwrite',
    },
    'target freq' => {
	'file' => 'data/runtime/trg.tab',
	'format' => 'tab',
	'write_mode' => 'overwrite',
    },
    'source vocabulary' => {
	'file' => 'data/runtime/src.voc',
	'format' => 'tab',
	'write_mode' => 'overwrite',
    },
    'target vocabulary' => {
	'file' => 'data/runtime/trg.voc',
	'format' => 'tab',
	'write_mode' => 'overwrite',
    }
  },
  'parameter' => {
    'token' => {
      'chunks (source)' => 'c.*',            # use marked chunks
      'chunks (target)' => 'c.*',            # use marked chunks
#      'minimal length diff' => 0.1,
#      'matching word class' => 'same',      # don't mix content and stop words
      'minimal frequency' => 2,
      'minimal frequency (source)' => 2,
      'minimal frequency (target)' => 2,
#      'minimal length (source)' => 2,
#      'minimal length (target)' => 2,
      'maximal ngram length (source)' => 1,  # >1 --> use N-grams
      'maximal ngram length (target)' => 1,  # >1 --> use N-grams
#      'use attribute (source)' => 'stem',
#      'use attribute (target)' => 'stem',
#      'grep token (source)' => 'alphabetic',
#      'grep token (target)' => 'alphabetic',
      'lower case (source)' => 1,
      'lower case (target)' => 1,
      'exclude stop words (source)' => 0,
      'exclude stop words (target)' => 0,
      'language (source)' => 'swedish',
      'language (target)' => 'english',
#      'language (source)' => 'default',
#      'language (target)' => 'default',
      'delimiter' => '\\s+',
      'token label' => 'w',
      'remove linked' => 1,
    },
    'runtime' => {
      'print progress' => 1,       # verbose output
    },
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:bitext:file',
       'infile' => 'input:bitext:file',
       'informat' => 'input:bitext:format',
       'src' => 'output:source freq:file',
       'trg' => 'output:target freq:file',
       'cooc' => 'output:cooc freq:file',
       'freq' => 'parameter:token:minimal frequency',
       'srclang' => 'parameter:token:language (source)',
       'trglang' => 'parameter:token:language (target)',
       'max' => 'parameter:runtime:max nr of segments',
    }
  },
  'widgets' => {
  }
};

    return %{$DefaultIni};
}
