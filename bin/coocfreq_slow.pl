#!/usr/bin/perl
#
# coocfreq.pl: count token frequencies
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
use Uplug::Data;
use Uplug::Data::Align;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='coocfreq.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=             # input data (only one!)
    each %{$IniData{'input'}};
my $SrcStream=$IniData{output}{'source freq'};  # source frequencies
my $TrgStream=$IniData{output}{'target freq'};  # target frequencies
my $CoocStream=$IniData{output}{'cooc freq'};   # co-occurrence frequencies

my $input=Uplug::IO::Any->new($InputStream);
my $srcfreq=Uplug::IO::Any->new($SrcStream);
my $trgfreq=Uplug::IO::Any->new($TrgStream);
my $coocfreq=Uplug::IO::Any->new($CoocStream);

#---------------------------------------------------------------------------

$input->open('read',$InputStream);
$srcfreq->open('write',$SrcStream);
$trgfreq->open('write',$TrgStream);
if (not $coocfreq->open('write',$CoocStream)){exit;}

#---------------------------------------------------------------------------

my $Param={};
$Param=$IniData{parameter};

my $MinPairFreq=$IniData{parameter}{token}{'minimal frequency'};
my %MinFreq;
$MinFreq{source}=$IniData{parameter}{token}{'minimal frequency (source)'};
$MinFreq{target}=$IniData{parameter}{token}{'minimal frequency (target)'};
my %lang;
$lang{source}=$IniData{parameter}{token}{'language (source)'};
$lang{target}=$IniData{parameter}{token}{'language (target)'};
my %ExclStop;
$ExclStop{source}=$IniData{parameter}{token}{'exclude stop words (source)'};
$ExclStop{target}=$IniData{parameter}{token}{'exclude stop words (target)'};
my $rmLinked=$IniData{parameter}{token}{'remove linked'};

my $PrintProgr=$IniData{'parameter'}{'runtime'}{'print progress'};
my $Buffer=$IniData{'parameter'}{'runtime'}{'buffer'};
my $SrcBuffer=$IniData{'parameter'}{'runtime'}{'source buffer'};
my $TrgBuffer=$IniData{'parameter'}{'runtime'}{'target buffer'};
my $MaxSegments=$IniData{'parameter'}{'runtime'}{'max nr of segments'};
my $CleanBuffer=$IniData{'parameter'}{'runtime'}{'clean buffer'};
# my $CleanBuffer=1;

my %First;

my $TmpBuffer;
my $BufferPuffer=$Buffer/10;      # keep at least 10% of the buffer size
                                  # flush the buffer otherwise!

#---------------------------------------------------------------------------

if ($PrintProgr){
    print STDERR "read alignments\n";
}

my %CoocFreq;      # token pair frequencies
my %SrcFreq;       # source token frequencies
my %TrgFreq;       # target token frequencies

my $AlignCount=0;                         # bitext segment counter
my ($CoocTypes,$SrcTypes,$TrgTypes);      # type counter
my ($CoocTokens,$SrcTokens,$TrgTokens);   # token counter
my $HashTypes;                            # type counter (buffer management)



#---------------------------------------------------------------------------
# now: read from input and count!

my $data=Uplug::Data::Align->new($lang{source},$lang{target});
# my $data=Uplug::Data->new('align',$lang{source},$lang{target});

my $time=time();
while ($input->read($data)){
    $AlignCount++;

    if ($rmLinked){$data->rmLinkedToken($data);}

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

	foreach my $trg (keys %{$SentFreq{trg}}){
	    if ($ExclStop{target} and $data->{target}->isStopWord($trg)){next;}
	    if (not defined $TrgFreq{$trg}){$TrgTypes++;}
	    $TrgFreq{$trg}+=$SentFreq{trg}{$trg};
	    $TrgTokens+=$SentFreq{trg}{$trg};
	    if ($TrgBuffer and (not ($TrgTypes % $TrgBuffer))){
		&WriteFreq($trgfreq,\%TrgFreq,$MinFreq{target},$PrintProgr);
	    }
	}

	# source frequencies

	foreach my $s (keys %{$SentFreq{cooc}}){
	    if ($ExclStop{source} and $data->{source}->isStopWord($s)){next;}
	    if (not defined $SrcFreq{$s}){$SrcTypes++;}
	    $SrcFreq{$s}+=$SentFreq{src}{$s};
	    $SrcTokens+=$SentFreq{src}{$s};
	    if ($SrcBuffer and (not ($SrcTypes % $SrcBuffer))){
		&WriteFreq($srcfreq,\%SrcFreq,$MinFreq{source},$PrintProgr);
	    }

	    # co-occurrence frequencies

	    foreach my $t (keys %{$SentFreq{cooc}{$s}}){
		my $src=$s;
		my $trg=$t;

		#---------------------------
		# relative position feature is special!
		# count marginal frequencies for each pair!
		
		if ($$Param{token}{'relative position'}){
		    ($src,$trg)=&makeRelPosFeature($src,$trg);
		    if (not defined $TrgFreq{$trg}){$TrgTypes++;}
		    $TrgFreq{$trg}+=$SentFreq{trg}{$t};
		    $TrgTokens+=$SentFreq{trg}{$t};
		    if ($TrgBuffer and (not ($TrgTypes % $TrgBuffer))){
			&WriteFreq($trgfreq,\%TrgFreq,$MinFreq{target},
				   $PrintProgr);
		    }
		    if (not defined $SrcFreq{$src}){$SrcTypes++;}
		    $SrcFreq{$src}+=$SentFreq{src}{$s};
		    $SrcTokens+=$SentFreq{src}{$s};
		    if ($SrcBuffer and (not ($SrcTypes % $SrcBuffer))){
			&WriteFreq($srcfreq,\%SrcFreq,$MinFreq{source},
				   $PrintProgr);
		    }
		}
		#---------------------------

		if ($ExclStop{target} and $data->{target}->IsStopWord($trg)){
		    next;
		}

		if ($data->checkPairParameter($src,$trg,$$Param{token})){

		    if (not defined $CoocFreq{$src}){
			$CoocTypes++;$HashTypes++;
		    }
		    elsif (not defined $CoocFreq{$src}{$trg}){
			$CoocTypes++;$HashTypes++;
		    }
		    $CoocFreq{$src}{$trg}+=$SentFreq{cooc}{$s}{$t};
		    $CoocTokens+=$SentFreq{cooc}{$s}{$t};

		    #----------------------------------------------
		    # check the buffer! if overflow:
		    #    alt 1) clean the buffer from low frequency pairs
		    #    alt 2) write some pairs or flush the buffer

		    if ($Buffer and (not ($HashTypes % $Buffer))){
			if ($CleanBuffer){
			    &CleanBuffer(\%CoocFreq,$MinPairFreq,$PrintProgr);
			}
			else{
			    my $written=&WritePairs($coocfreq,\%CoocFreq,
						    $MinPairFreq,$PrintProgr);
			    if ($written<$BufferPuffer){
				&FlushBuffer(\%CoocFreq,$PrintProgr);
				$HashTypes=0;
			    }
			}
		    }
		    #----------------------------------------------
		}
	    }
	}
    }
}
$input->close;

# end of input file
#---------------------------------------------------------------------------
# write frequencies to files

&WritePairs($coocfreq,\%CoocFreq,$MinPairFreq,$PrintProgr);
&WriteFreq($srcfreq,\%SrcFreq,$MinFreq{source},$PrintProgr);
&WriteFreq($trgfreq,\%TrgFreq,$MinFreq{target},$PrintProgr);

if(-e $TmpBuffer){&FlushBuffer(\%CoocFreq,$PrintProgr);}
&RestoreFlushedBuffer($coocfreq,$MinPairFreq,
		      $srcfreq,$trgfreq,$PrintProgr);

#-----------------------------------------
# write headers to frequency-files

$input->close;
my %header = ('align count' => $AlignCount,
	      'token pair count' => $CoocTokens,
	      'type pair count' => $CoocTypes);
$coocfreq->addheader(\%header);
$coocfreq->addheader($$Param{token});
$coocfreq->writeheader;
$coocfreq->close;
my %header = ('type count' => $SrcTypes,
	      'token count' => $SrcTokens);
foreach (keys %{$$Param{token}}){
    if (/source/){
	my $attr=$_;
	$attr=~s/ (source)//;
	$header{$attr}=$$Param{token}{$_};
    }
}
$srcfreq->addheader(\%header);
$srcfreq->writeheader;
$srcfreq->close;
my %header = ('type count' => $TrgTypes,
	      'token count' => $TrgTokens);
foreach (keys %{$$Param{token}}){
    if (/target/){
	my $attr=$_;
	$attr=~s/ (target)//;
	$header{$attr}=$$Param{token}{$_};
    }
}

$trgfreq->addheader(\%header);
$trgfreq->writeheader;
$trgfreq->close;

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



#---------------------------------------------------------------------------
# WritePairs: save co-occurrence frequencies

sub WritePairs{
    my ($coocfreq,$CoocFreq,$MinPairFreq,$PrintProgr)=@_;
    my ($src,$trg);
    if ($PrintProgr){
	my $nrSRC=scalar keys %{$CoocFreq};
	print STDERR "write pairs ($nrSRC source items)\n";
    }
    my $written=0;
    my $nrSRC=0;
    foreach $src (keys %{$CoocFreq}){
	$nrSRC++;
	foreach $trg (keys %{$$CoocFreq{$src}}){
	    my $total=$$CoocFreq{$src}{$trg};
	    my $freq=$total;
	    if ($total<$MinPairFreq){next;}

#	    my $data=Uplug::Data::Tree->new;
	    my $data=Uplug::Data->new();
	    $data->setData({source => $src,
			    target => $trg,
			    freq => $freq});
#	    $data->setAttribute('source',$src);
#	    $data->setAttribute('target',$trg);
#	    $data->setAttribute('freq',$freq);      # DBM adds up frequencies!
	    $written++;
	    if ($PrintProgr){
		if (not ($written % 1000)){
		    $|=1;print STDERR '.';$|=0;
		}
		if (not ($written % 50000)){
		    $|=1;print STDERR "$written saved ($nrSRC)\n";$|=0;
		}
	    }
	    $coocfreq->write($data);
	    $HashTypes--;
	    delete $$CoocFreq{$src}{$trg};
	}
	if (not keys %{$$CoocFreq{$src}}){
	    delete $$CoocFreq{$src};
	}
    }
    if ($PrintProgr){
	$|=1;print STDERR "$written saved ($nrSRC)\n";$|=0;
    }
    return $written;
    if ($written<$BufferPuffer){
	&FlushBuffer($CoocFreq,$PrintProgr);
	$HashTypes=0;
    }
    $First{$coocfreq}=1;
}

#---------------------------------------------------------------
# CleanBuffer: take away all pairs with the lowest frequencies
# (assuming that they don't occur very much in the future either)

sub CleanBuffer{
    my ($CoocFreq,$minfreq,$verbose)=@_;
    my $nr=0;
    my $freq=1;
    if ($verbose){print STDERR "clean buffer ... ";}
    while (($freq<$minfreq) and ($nr<$BufferPuffer) and (keys %{$CoocFreq})){
	foreach my $src (keys %{$CoocFreq}){
	    foreach my $trg (keys %{$$CoocFreq{$src}}){
		if ($$CoocFreq{$src}{$trg}==$freq){
		    $HashTypes--;
		    delete $$CoocFreq{$src}{$trg};
		    $nr++;
		}
	    }
	    if (not keys %{$$CoocFreq{$src}}){
		delete $$CoocFreq{$src};
	    }
	}
	$freq++;
    }
    $freq--;
    if ($verbose){print STDERR "$nr pairs deleted (freq $freq)!\n";}
    if ($nr<$BufferPuffer){&FlushBuffer($CoocFreq,$verbose);}
}

#---------------------------------------------------------------
# flush buffer to temp file

sub FlushBuffer{
    my ($CoocFreq,$PrintProgr)=@_;
    if (not defined $TmpBuffer){
	$TmpBuffer=Uplug::IO::Any::GetTempFileName;
	open F,"| gzip -c >$TmpBuffer.gz";
    }
    else{
	open F,"| gzip -c >>$TmpBuffer.gz";
    }
    if ($PrintProgr){
	$|=1;print STDERR "flushing buffer to $TmpBuffer.gz!\n";$|=0;
    }
    my $nr=0;
    foreach my $src (keys %{$CoocFreq}){
	$nr++;
	foreach my $trg (keys %{$$CoocFreq{$src}}){
	    print F "$src\x00$trg\x00$$CoocFreq{$src}{$trg}\n";
	    delete $$CoocFreq{$src}{$trg};
	}
	delete $$CoocFreq{$src};
    }
    close F;
}


#----------------------------------------------------------------------
# read data from the flushed buffer and write data to DB
#----------------------------------------------------------------------


sub RestoreFlushedBuffer{
    my ($coocfreq,$minfreq,$srcfreq,$trgfreq,$progress)=@_;
    if (not -e $TmpBuffer){return;}

    my %src=();
    my %trg=();

    my %skipsrc=();
    my %skiptrg=();

    my $nrSrc=0;
    my $nrTrg=0;
    my $skipped=0;
    my $written;
    my $count=0;

    #----------------------------------------------------------------------
    if ($progress){
	$|=1;print STDERR "read buffer\n";$|=0;
    }
    #----------------------------------------------------------------------

    open F,"gzip -cd <$TmpBuffer.gz |";
    while (<F>){
	$count++;

	if ($progress){
	    if (not ($count % 5000)){
		$|=1;print STDERR '.';$|=0;
	    }
	    if (not ($count % 100000)){
		$|=1;print STDERR "$written saved, $skipped skipped ($count)\n";$|=0;
	    }
	}

	chomp;
	my ($s,$t,$f)=split(/\x00/);

	if (($nrSrc<$SrcBuffer) and (not defined $src{$s})){
	    $src{$s}=&GetTokFreq($srcfreq,$s);
	    $nrSrc++;
	}
	if (($nrTrg<$TrgBuffer) and (not defined $trg{$t})){
	    $trg{$t}=&GetTokFreq($trgfreq,$t);
	    $nrTrg++;
	}
	my ($sf,$tf);
	if (defined $src{$s}){$sf=$src{$s};}
	else{$sf=&GetTokFreq($srcfreq,$s);}
	if (defined $trg{$t}){$tf=$trg{$t};}
	else{$tf=&GetTokFreq($trgfreq,$t);}

	if ($sf<$minfreq){$skipped++;next;}
	if ($tf<$minfreq){$skipped++;next;}

	my $total=$f+&GetPairFreq($coocfreq,$s,$t);
	if ($total<$minfreq){
	    $skipsrc{$s}+=$f;
	    $skiptrg{$t}+=$f;
	    next;
	}
	else{
#	    my $data=Uplug::Data::Tree->new;
	    my $data=Uplug::Data->new();
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('freq',$f);      # DBM adds up frequencies!
	    $written++;
	    $coocfreq->write($data);
	}
    }
    close F;

    #----------------------------------------------------------------------
    if ($progress){
	$|=1;print STDERR "\nread remaining buffer\n";$|=0;
    }
    #----------------------------------------------------------------------

    my %freq=();
    my $count=0;
    open F,"gzip -cd <$TmpBuffer.gz |";
    while (<F>){
	chomp;
	my ($s,$t,$f)=split(/\x00/);
	if (not defined $skipsrc{$s}){next;}
	if (not defined $skiptrg{$t}){next;}

	$count++;
	if ($progress){
	    if (not ($count % 5000)){
		$|=1;print STDERR '.';$|=0;
	    }
	    if (not ($count % 100000)){
		$|=1;print STDERR "$skipped skipped ($count)\n";$|=0;
	    }
	}

	my $total=&GetPairFreq($coocfreq,$s,$t);
	if (($total+$skipsrc{$s})<$minfreq){$skipped++;next;}
	if (($total+$skiptrg{$t})<$minfreq){$skipped++;next;}
	$freq{$s}{$t}++;
    }
    close F;

    #----------------------------------------------------------------------
    if ($progress){
	$|=1;print STDERR "\nwrite remaining buffer\n";$|=0;
    }
    #----------------------------------------------------------------------

    my $count=0;
    my $written=0;
    foreach my $s (keys %freq){
	foreach my $t (keys %{$freq{$s}}){
	    $count++;
	    if ($progress){
		if (not ($count % 5000)){
		    $|=1;print STDERR '.';$|=0;
		}
		if (not ($count % 100000)){
		    $|=1;print STDERR "$written saved ($count)\n";$|=0;
		}
	    }
	    my $total=$freq{$s}{$t}+&GetPairFreq($coocfreq,$s,$t);
	    if ($total<$minfreq){next;}
#	    my $data=Uplug::Data::Tree->new;
	    my $data=Uplug::Data->new();
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('freq',$freq{$s}{$t});
	    $coocfreq->write($data);
	    $written++;
	}
    }
}


END{
    if (-e $TmpBuffer){
	unlink $TmpBuffer;
    }
}



sub GetPairFreq{
    my ($db,$src,$trg)=@_;
#    my $sel=Uplug::Data::Tree->new;
    my $sel=Uplug::Data->new();
    my %pattern=('source' => $src,
		 'target' => $trg);
    if ($db->select($sel,\%pattern)){
	return $sel->attribute('freq');
    }
    return undef;
}

sub GetTokFreq{
    my ($db,$tok)=@_;
#    my $sel=Uplug::Data::Tree->new;
    my $sel=Uplug::Data->new();
    my %pattern=('token' => $tok);
    if ($db->select($sel,\%pattern)){
	return $sel->attribute('freq');
    }
    return undef;
}


#---------------------------------------------------
# WriteFreq: save token frequencies

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
#		my $sel=Uplug::Data::Tree->new;     #   query the database
		my $sel=Uplug::Data->new();
		my %pattern=('token' => $_);        #   and get the total freq
		if ($stream->select($sel,\%pattern)){
		    $total+=$sel->attribute('freq');
		}
	    }
	}
	if ($total<$MinFreq){next;}

#	my $data=Uplug::Data::Tree->new;
	my $data=Uplug::Data->new();
	$data->setData({token => $_,
			freq => $freq});
#	$data->setAttribute('token',$_);
#	$data->setAttribute('freq',$freq);
	$stream->write($data);
	delete $$TokFreq{$_};
    }
    $First{$stream}=1;
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

    my $DefaultIni = 
{
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
      'stream name' => 'cooc freq',
    },
    'source freq' => {
      'stream name' => 'source freq',
    },
    'target freq' => {
      'stream name' => 'target freq',
    }
  },
  'parameter' => {
    'token' => {
      'chunks (source)' => 'c.*',            # use marked chunks
      'chunks (target)' => 'c.*',            # use marked chunks
#      'minimal length diff' => 0.1,
#      'matching word class' => 'same',       # don't mix content and stop words
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
#      'language (source)' => 'english',
#      'language (target)' => 'swedish',
      'language (source)' => 'default',
      'language (target)' => 'default',
      'delimiter' => '\\s+',
      'token label' => 'w',
      'remove linked' => 1,
    },
    'runtime' => {
      'print progress' => 1,       # verbose output
      'buffer' => 2000000,         # number of token pairs buffered in a hash
      'source buffer' => 2000000,  # source token buffer
      'target buffer' => 2000000,  # target token buffer
      #------------------------------------------------------------
      # clean buffer: 
      # if set to 1: remove low-frequency-pairs from the buffer in
      #              cases of buffer overflows
      'clean buffer' => 1,
      #------------------------------------------------------------
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
       'buf' => 'parameter:runtime:buffer',
       'clean' => 'parameter:runtime:clean buffer',
    }
  },
  'widgets' => {
  }
};

    return %{$DefaultIni};
}
