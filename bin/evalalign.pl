#!/usr/bin/perl
#
# -*-perl-*-
#
# Copyright (C) 2004 J�rg Tiedemann  <joerg@stp.ling.uu.se>
# $Id$
#----------------------------------------------------------------------------
#
# 


use strict;
use FindBin qw($Bin);
use lib "$Bin/..";

use Uplug::IO::Any;
use Uplug::Data;
use Uplug::Config;


#---------------------------------------------------------------------------
# 0) get input parameter

my %IniData=&GetDefaultIni;
my $IniFile='evalalign.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

my $GoldStream;my $AlignStream;
foreach (keys %{$IniData{input}}){
    if (/(gold|reference)/){
	$GoldStream=$IniData{input}{$_};
    }
    else{
	$AlignStream=$IniData{input}{$_};
    }
}
my $minscore=$IniData{parameter}{'minimal score'};

#---------------------------------------------------------------------------
# 1) read links from the gold standard

my $gold=Uplug::IO::Any->new($GoldStream);
$gold->open('read',$GoldStream);
my %GoldLinks=();
&ReadGoldStandard($gold,\%GoldLinks);
$gold->close();

#---------------------------------------------------------------------------
# 2) go through the alignment file and compare links with the gold standard

my $align=Uplug::IO::Any->new($AlignStream);
$align->open('read',$AlignStream);
my $data=Uplug::Data->new();
my %counts=();

while ($align->read($data)){
    my $id=$data->attribute('id','sentLink');
    if (not $id){$id=$data->attribute('id','link');}
    if (not defined $GoldLinks{$id}){next;}
    &CheckLinks($data,$GoldLinks{$id},\%counts,$id,$minscore);
}
$align->close();

#---------------------------------------------------------------------------
# 3) calculate some evaluation measures and print them

my %precision_pwa;
my %recall_pwa;
my %F_pwa;

my %precision;
my %recall;
my %F;

$counts{regular}{correctness}=
    $counts{regular}{Q}+$counts{regular}{null}+$counts{regular}{correct};
$counts{fuzzy}{correctness}=
    $counts{fuzzy}{Q}+$counts{fuzzy}{null}+$counts{fuzzy}{correct};

$counts{regular}{recall}=
    $counts{regular}{QR}+$counts{regular}{null}+$counts{regular}{correct};
$counts{fuzzy}{recall}=
    $counts{fuzzy}{QR}+$counts{fuzzy}{null}+$counts{fuzzy}{correct};

$counts{regular}{precision}=
    $counts{regular}{QP}+$counts{regular}{null}+$counts{regular}{correct};
$counts{fuzzy}{precision}=
    $counts{fuzzy}{QP}+$counts{fuzzy}{null}+$counts{fuzzy}{correct};


foreach (keys %{$counts{regular}}){
    $counts{all}{$_}=$counts{regular}{$_}+$counts{fuzzy}{$_};
}
# just in case some keys don't exist for regular:
foreach (keys %{$counts{fuzzy}}){ 
    $counts{all}{$_}=$counts{regular}{$_}+$counts{fuzzy}{$_};
}

foreach ('regular','fuzzy','all'){
    if ($counts{$_}{goldsize}){
	$recall_pwa{$_}=$counts{$_}{correctness}/$counts{$_}{goldsize};
	$recall{$_}=$counts{$_}{recall}/$counts{$_}{goldsize};
	my $aligned=$counts{$_}{goldsize}-$counts{$_}{missing};
	if ($aligned){
	    $precision_pwa{$_}=$counts{$_}{correctness}/$aligned;
	    $precision{$_}=$counts{$_}{precision}/$aligned;
	}
	if ($precision_pwa{$_}+$recall_pwa{$_}){
	    $F_pwa{$_}=(2*$precision_pwa{$_}*$recall_pwa{$_})/
		($precision_pwa{$_}+$recall_pwa{$_});
	}
	if ($precision{$_}+$recall{$_}){
	    $F{$_}=(2*$precision{$_}*$recall{$_})/
		($precision{$_}+$recall{$_});
	}
    }
}

print "------------------------------------------------------\n";

if ($counts{all}{correct}){
    print "          average score for correct links: ",
    $counts{all}{correctscore}/$counts{all}{correct},"\n";
}
if ($counts{all}{nrpartial}){
    print "average score for partially correct links: ",
    $counts{all}{partialscore}/$counts{all}{nrpartial},"\n";
}
if ($counts{all}{nrwrong}){
    print "        average score for incorrect links: ",
    $counts{all}{wrongscore}/$counts{all}{nrwrong},"\n";
}

print "------------------------------------------------------\n";

printf "%25s: %4d, regular:%4d,fuzzy:%4d,null:%4d\n",
    "size of gold standard",$counts{all}{goldsize},
    $counts{regular}{goldsize},$counts{fuzzy}{goldsize},$counts{all}{nrnull};
printf "%25s: %4d, regular:%4d,fuzzy:%4d,null:%4d\n",
    "correct links",$counts{all}{correct}+$counts{all}{null},
    $counts{regular}{correct},$counts{fuzzy}{correct},$counts{all}{null};
printf "%25s: %4d, regular:%4d,fuzzy:%4d\n",
    "partially correct links",$counts{all}{partial},
    $counts{regular}{partial},$counts{fuzzy}{partial};
printf "%25s: %4d, regular:%4d,fuzzy:%4d,null:%4d\n",
    "incorrect links",$counts{all}{incorrect},$counts{regular}{incorrect},
    $counts{fuzzy}{incorrect},$counts{all}{incorrectnull};
printf "%25s: %4d, regular:%4d,fuzzy:%4d\n",
    "missing links",$counts{all}{missing},
    $counts{regular}{missing},$counts{fuzzy}{missing};

print "------------------------------------------------------\n";

printf "%10s: %3.2f\%","recall",$recall{all}*100;
printf " (regular: %3.2f\%",$recall{regular}*100;
printf ",fuzzy: %3.2f\%",$recall{fuzzy}*100;
printf ",pwa: %3.2f\%)\n",$recall_pwa{all}*100;

printf "%10s: %3.2f\%","precision",$precision{all}*100;
printf " (regular: %3.2f\%",$precision{regular}*100;
printf ",fuzzy: %3.2f\%", $precision{fuzzy}*100;
printf ",pwa: %3.2f\%)\n",$precision_pwa{all}*100;

printf "%10s: %3.2f\%","F",$F{all}*100;
printf " (regular: %3.2f\%",$F{regular}*100;
printf ",fuzzy: %3.2f\%",$F{fuzzy}*100;
printf ",pwa: %3.2f\%)\n",$F_pwa{all}*100;


#---------------------------------------------------------------------------
# CheckLinks: compare alignments with links from the gold standard


sub CheckLinks{
    my ($data,$gold,$counts,$id,$score)=@_;

    my @n=$data->findNodes('wordLink');
#    if (not @n){return;}
    my %links=();
    foreach (0..$#n){
	&SplitLink($data,$n[$_],\%links,$score);
    }
    foreach my $l (keys %{$gold}){
	if ($l eq 'src'){next;}
	if ($l eq 'trg'){next;}
	my $type=$$gold{$l}{type};
	if ($type eq 'null'){$type='fuzzy';}
	my $srclex=join ' ',@{$$gold{$l}{srclex}};
	my $trglex=join ' ',@{$$gold{$l}{trglex}};
	printf "%15s: %25s - %-25s ",$id,$srclex,$trglex;
	$$counts{$type}{goldsize}++;

	if (not @{$$gold{$l}{trg}}){         # check for null links:
	    $$counts{$type}{nrnull}++;       # count null links
	    if (defined $links{src}{$$gold{$l}{src}[0]}){ # aligned null links:
		$$counts{$type}{incorrectnull}++;         # -> incorrect
	    }
	    else{
		$$counts{$type}{null}++;     # count not aligned null links
		print "null\n";              # (= correct)
		next;
	    }
	}

	if (defined $links{$l}){           # link exists exactely like in the
	    $$counts{$type}{correct}++;    # gold standard
	    $$counts{$type}{correctscore}+=$links{$l}{type};
	    print "correct\n";
	    next;
	}

        #----------------------------------------------------------------------
	# check partialially correct links

	my %PartialLinks=();
	foreach my $s (@{$$gold{$l}{src}}){
	    if (defined $links{src}{$s}){
		$PartialLinks{$links{src}{$s}}=1;
	    }
	}
	foreach my $t (@{$$gold{$l}{trg}}){
	    if (defined $links{trg}{$t}){
		$PartialLinks{$links{trg}{$t}}=1;
	    }
	}

	my $NrCorrSrc=0;
	my $NrCorrTrg=0;
	my $NrLinkSrc=0;
	my $NrLinkTrg=0;

	my $LinkedSrc='';                      # links proposed by the system
	my $LinkedTrg='';

	my $NrGoldSrc=$#{$$gold{$l}{src}}+1;
	my $NrGoldTrg=$#{$$gold{$l}{trg}}+1;

	foreach (keys %PartialLinks){
	    $NrLinkSrc+=$#{$links{$_}{src}}+1;
	    $NrLinkTrg+=$#{$links{$_}{trg}}+1;
	    my $corrSrc=&NrIdentical($links{$_}{src},$$gold{$l}{src});
	    my $corrTrg=&NrIdentical($links{$_}{trg},$$gold{$l}{trg});
	    if ($corrSrc and $corrTrg){
		$NrCorrSrc+=$corrSrc;
		$NrCorrTrg+=$corrTrg;
		$$counts{$type}{partialscore}+=$links{$_}{type};
		$$counts{$type}{nrpartial}++;
	    }
	    elsif ($corrSrc or $corrTrg){
		$$counts{$type}{wrongscore}+=$links{$_}{type};
		$$counts{$type}{nrwrong}++;
	    }
	    $LinkedSrc.='|';
	    $LinkedTrg.='|';
	    $LinkedSrc.=join ' ',@{$links{$_}{srclex}};
	    $LinkedTrg.=join ' ',@{$links{$_}{trglex}};
	}
	if (not keys %PartialLinks){
	    $$counts{$type}{missing}++;
	    print "missing\n";
	    next;
	}
	my $NrSrc=$NrGoldSrc;
	my $NrTrg=$NrGoldTrg;
	if ($NrLinkSrc>$NrGoldSrc){$NrSrc=$NrLinkSrc;}
	if ($NrLinkTrg>$NrGoldTrg){$NrTrg=$NrLinkTrg;}
	my $NrCorr=($NrCorrSrc+$NrCorrTrg);
	my $NrTok=($NrSrc+$NrTrg);
	if ($NrCorr and $NrTok){
	    $$counts{$type}{Q}+=($NrCorrSrc+$NrCorrTrg)/($NrSrc+$NrTrg);
	    $$counts{$type}{QR}+=
		($NrCorrSrc+$NrCorrTrg)/($NrGoldSrc+$NrGoldTrg);
	    $$counts{$type}{QP}+=
		($NrCorrSrc+$NrCorrTrg)/($NrLinkSrc+$NrLinkTrg);
	    $$counts{$type}{partial}++;
	    print "$NrCorr($NrTok)\n";
	}
	elsif(not $NrCorr){
	    $$counts{$type}{incorrect}++;
	    print "wrong\n";
	}
	$LinkedSrc.='|';
	$LinkedTrg.='|';
	printf "%42s - %-30s\n",$LinkedSrc,$LinkedTrg;
    }
}

#---------------------------------------------------------------------------
# NrIdentical: compare 2 sets and return the number of identical elements

sub NrIdentical{
    my ($set1,$set2)=@_;
    my $nr=0;
    foreach my $i (@{$set1}){
	if (grep ($_ eq $i,@{$set2})){$nr++;}
    }
    return $nr;
}

sub ReadGoldStandard{
    my ($stream,$links)=@_;
    my $data=Uplug::Data->new();
    while ($stream->read($data)){
	my $id=$data->attribute('id','sentLink');
	if (not $id){$id=$data->attribute('id','link');}
	my @n=$data->findNodes('wordLink');
	if (not @n){next;}
	print STDERR '.';
	$$links{$id}={};
	foreach (0..$#n){
	    &SplitLink($data,$n[$_],$$links{$id});
	}
    }
}

#---------------------------------------------------------------------------
# get link-information from the XML data-object

sub SplitLink{
    my ($data,$node,$link,$score)=@_;
    my $xtrg=$data->attribute($node,'xtargets');
    my $lex=$data->attribute($node,'lexPair');
    my $type=$data->attribute($node,'certainty');
    if (defined $score){
	if ($type<$score){return;}
    }
    $$link{$xtrg}{type}=$type;
    my ($src,$trg)=split(/\;/,$xtrg);
    @{$$link{$xtrg}{src}}=split(/\+/,$src);
    @{$$link{$xtrg}{trg}}=split(/\+/,$trg);
    my ($src,$trg)=split(/\;/,$lex);
    @{$$link{$xtrg}{srclex}}=split(/\s/,$src);
    @{$$link{$xtrg}{trglex}}=split(/\s/,$trg);
    foreach (@{$$link{$xtrg}{src}}){$$link{src}{$_}=$xtrg;}
    foreach (@{$$link{$xtrg}{trg}}){$$link{trg}{$_}=$xtrg;}
}

#---------------------------------------------------------------------------

sub GetDefaultIni{

    my $DefaultIni = {
  'input' => {
    'gold standard' => {
      'format' => 'xml',
      'root' => '(link|sentLink)',
    },
    'alignments' => {
      'format' => 'xml',
      'root' => '(link|sentLink)',
    }
  },
  'parameter' => {
  },
  'arguments' => {
    'shortcuts' => {
       'in' => 'input:alignments:file',
       'gold' => 'input:gold standard:file',
       'min' => 'parameter:minimal score',
    }
  },
  'widgets' => {
  }
};
    return %{$DefaultIni};
}




