####################################################################
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
#
# $Author$
# $Id$
#
###########################################################################
# Uplug::Align::Word::Clue
#
#
#
###########################################################################


package Uplug::Align::Word::Clue;

use strict;
use Time::HiRes qw(time);

use vars qw(@ISA $VERSION $DEBUG);
use vars qw($INPHRASESONLY $ADJACENTONLY $ADJACENTSCORE $FILLPHRASES);
use vars qw($ALLOWMULTIOVERLAP $PRINTHTML);
# use utf8;
use Uplug::Data;
use Uplug::Align::Word;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;
$Data::Dumper::Purity=1;

@ISA = qw( Uplug::Align::Word );

$VERSION = '$Id$ ';
$DEBUG = 0;

#---------------------------------
# parameters for add2LinkCluster

$INPHRASESONLY = 0;          # if = 1 --> no links outside of chunks
$ADJACENTONLY = 1;           # if = 1 --> allow only adjacent links
$ADJACENTSCORE = 0;          # if > 0 --> $score >= $neighbor * $ADJACENTSCORE
# $ALLOWMULTIOVERLAP = 0;      # allow overlap with more than 1 link cluster!
# $ADJACENTSCORE = 0.4;
$ADJACENTSCORE = 0;

$FILLPHRASES = 0;            #  ... doesn't work ....



sub new{
    my $class=shift;
    my $self=$class->SUPER::new(@_);
    if (not defined $self->parameter('adjacent_only')){
	$self->setParameter('adjacent_only',$ADJACENTONLY);
    }
    if (not defined $self->parameter('adjacent_score')){
	$self->setParameter('adjacent_score',$ADJACENTSCORE);
    }
    if (not defined $self->parameter('in_phrases_only')){
	$self->setParameter('in_phrases_only',$INPHRASESONLY);
    }
    if (not defined $self->parameter('fill_phrase')){
	$self->setParameter('fill_phrases',$FILLPHRASES);
    }
    if (not defined $self->parameter('allow_multiple_overalps')){
	$self->setParameter('allow_multiple_overlaps',$ALLOWMULTIOVERLAP);
    }
    if (not defined $self->parameter('verbose')){
	$self->setParameter('verbose',$DEBUG);
    }
    else{$DEBUG=$self->parameter('verbose');}

    return $self;
}

sub DESTROY {
    my $self = shift;
}



#===========================================================================
#
# get all link scores and fill the clue matrix
#
#===========================================================================

sub getLinkScores{
    my $self=shift;

    $self->{matrix}=[];
    $self->{links}={};
    my $LinkProb=$self->{matrix};
    my $links=$self->{linkStreams};
    my $SrcTok=$self->{srcToken};
    my $TrgTok=$self->{trgToken};
    my $Param=$self->{param};
    my $data=$self->{data};

    ## prepare clue param hash (reduce checks in the loop below)
    my %ClueParam=%{$Param};
    if (exists $ClueParam{general}){delete $ClueParam{general};}
    if (exists $ClueParam{original}){delete $ClueParam{original};}
    foreach (keys %ClueParam){
	if (ref($ClueParam{$_}) ne 'HASH'){$ClueParam{$_}={};}
	if (not defined $ClueParam{$_}{'score weight'}){
	    $ClueParam{$_}{'score weight'}=$self->defaultClueWeight();
	}
    }

    ## define some variables used in the loop
    my $weight;           # clue combination weight
    my ($src,$trg);       # source and target language tokens
    my $score;            # clue score found for the current pair
    my $time;             # time (for debugging)
    my %search;           # hash of patterns for searching clues
    my $found=Uplug::Data->new;  # clues found
    my @SrcTok;           # positions of the current source
    my @TrgTok;           # and target tokens in the sentence
    my ($s,$t,$x,$y,$p);  # variables for iteration
    my $ScoreComb=$self->parameter('score combination');
    if (not $ScoreComb){$ScoreComb='probabilistic';}


    ## the following loop takes most of the time!

    foreach $s (sort {$a <=> $b} keys %{$SrcTok}){
	foreach $t (keys %{$TrgTok}){

	    $time=time();

	    ($src,$trg)=($$SrcTok{$s}{general},$$TrgTok{$t}{general});
	    $self->alignIdentical($src,$trg,$s,$t,$LinkProb);

	    ### DEBUG: store search time
	    $self->{identical_score_time}+=time()-$time;

	    foreach (keys %ClueParam){

		$time=time();

		$weight=$ClueParam{$_}{'score weight'};
		if ($ClueParam{$_}{'relative position'}){
		    ($src,$trg)=$self->makeRelPosFeature($$SrcTok{$s}{$_},
							 $$TrgTok{$t}{$_});
		}
		else{($src,$trg)=($$SrcTok{$s}{$_},$$TrgTok{$t}{$_});}

		### DEBUG: store search time
		$self->{before_score_time}+=time()-$time;

		$score=0;

		#---------------------------------------
		# length difference as  scores ...
		#---------------------------------------

		if ($ClueParam{$_}{'string length difference'}){
		    $score=$data->lengthQuotient($src,$trg);
		}

		#---------------------------------------
		# otherwise: search scores in link-DB
		#---------------------------------------

		else{
		    if (not defined $links->{$_}){next;}
		    if (defined($src) and defined($trg)){
			%search=('source' => $src,
				 'target' => $trg);
			$time=time();
			if ($links->{$_}->select($found,\%search)){
			    $score=$found->attribute('score');
			}
			### DEBUG: store search time
			$self->{search_score_time}+=time()-$time;
		    }
		}

		$time=time();

		#---------------------------------------
		# set weighted score in score matrix
		#---------------------------------------

		if (not $score){next;}
		if (not $data->checkPairParameter($src,$trg,$ClueParam{$_})){
		    ### DEBUG: store search time
		    $self->{after_score_time}+=time()-$time;
		    next;
		}

		if (exists $ClueParam{$_}{'minimal score'}){
		    if ($score<$ClueParam{$_}{'minimal score'}){
			### DEBUG: store search time
			$self->{after_score_time}+=time()-$time;
			next;
		    }
		}

		$score*=$weight;

		# shouldn't be >1, but in case ...
		#--------------------------------
		if ($score>=1){$score=0.999999999999;}
		#--------------------------------

		if ($self->parameter('verbose')){
		    printf STDERR "[%5s - %-5s] {%20s - %-20s} %f\n",
		    $s,$t,$src,$trg,$score;
		}

		@SrcTok=split(/:/,$s);
		@TrgTok=split(/:/,$t);

		foreach $x (@SrcTok){
		    foreach $y (@TrgTok){
			if ($ScoreComb eq 'addition'){
			    $$LinkProb[$x][$y]+=$score;
			}
#
# log-linear and multiplication are useless!
# * there's not always a positive score for each possible pair! 
#   --> multiplications with one factor = 0 --> score = 0
#   --> leaving out zero-factors -> implicit penalty for pairs with multiple
#                                   clue scores
#
#			elsif ($ScoreComb eq 'log-linear'){
#			    $$LinkProb[$x][$y]+=log($score);
#			}
#			elsif ($ScoreComb eq 'multiplication'){
#			    $$LinkProb[$x][$y]+=log($score);
#			}
			else{
			    $p=$$LinkProb[$x][$y];
			    $$LinkProb[$x][$y]=$p+$score-$p*$score;
			}
		    }
		}

		### DEBUG: store search time
		$self->{after_score_time}+=time()-$time;

	    }
	}
    }

    $time=time();
    $self->align1x($LinkProb);

#    if ($ScoreComb eq 'log-linear'){              # special for log-linear:
#	foreach $x (0..$#{$LinkProb}){            # reverse log (make positiv
#	    foreach $y (0..$#{$$LinkProb[$x]}){   # score values)
#		$$LinkProb[$x][$y]=exp($$LinkProb[$x][$y]);
#	    }
#	}
#    }

    if ($self->parameter('verbose')){
	$self->printClueMatrix($self->{token}->{source},
			       $self->{token}->{target},
			       $self->{matrix});

	$self->printBitextToken($self->{token}->{source},
				$self->{token}->{target});
    }
    ### DEBUG: store search time
    $self->{'1x_score_time'}+=time()-$time;
}


#===========================================================================
#
# search for the best alignment using the clue matrix scores
#
#   topLinkSearch ........ iteratively add top links to link clusters
#   nextBestSearch ....... score = distance to next best link (+topLinkSearch)
#   oneOneFirstSearch .... non-overlapping first, overlapping then
#   competitiveSearch .... competitive linking (1:1 links only!)
#   bidirectionalRefineSearch  intersection of directional links + overlapping
#   directionalSrcSearch ..... best alignment source --> target
#   directionalTrgSearch ..... best alignment target --> source
#   bidirectionalUnion ....... union of directionalSrc & directionalTrg
#   bidirectionalIntersection  intersection of directionalSrc & directionalTrg
#
# parameter search: nextbest ........ nextBestSearch
#                   oneone....... ... oneOneFirstSearch
#                   competitive ..... competitiveSearch
#                   myrefined ....... bidirectionalRefinedSearch
#                   och ............. bidirectionalRefinedSearchOch
#                   src ............. directionalSrcSearch
#                   trg ............. directionalTrgSearch
#                   union ........... bidirectionalUnion
#                   intersection .... bidirectionalIntersection
#                   <default> ....... topLinkSearch
#
#===========================================================================


sub findAlignment{
    my $self=shift;
    $self->{links}={};
    my $minScore=$self->scoreThreshold();
    my $method=$self->parameter('search');

    if ($method=~/nextbest/){
	return $self->nextBestSearch($self->{links},$minScore);}
    elsif ($method=~/competitive/){
	return $self->competitiveSearch($self->{links},$minScore);}
    elsif ($method=~/oneone/){
	return $self->oneOneFirstSearch($self->{links},$minScore);}
    elsif ($method=~/myrefined/){
	return $self->bidirectionalRefinedSearch($self->{links},$minScore);}
    elsif ($method=~/(och|refined)/){
	return $self->bidirectionalRefinedSearchOch($self->{links},$minScore);}
    elsif ($method=~/src/){
	return $self->directionalSrcSearch($self->{links},$minScore);}
    elsif ($method=~/trg/){
	return $self->directionalTrgSearch($self->{links},$minScore);}
    elsif ($method=~/union/){
	return $self->bidirectionalUnion($self->{links},$minScore);}
    elsif ($method=~/intersection/){
	return $self->bidirectionalIntersection($self->{links},$minScore);}
    else{
	return $self->topLinkSearch($self->{links},$minScore);}


#    return $self->matrixSearch1($self->{links},$minScore);
#    return $self->matrixSearch3($self->{links},$minScore);
#    return $self->matrixSearch2($self->{links});
#    return $self->matrixSearch10($self->{links},$minScore);

#    $self->normalizeMatrix($self->{matrix});
#    return $self->matrixBeamSearch($self->{links},$minScore);
#    return $self->matrixSearch10($self->{links},$minScore);

}





#===========================================================================
# add scores to the clue matrix for 
# sentence alignments with only 1 word in either source or target
#===========================================================================


sub align1x{
    my $self=shift;
    my ($LinkProb)=@_;
    my $Align11=$self->parameter('align 1:1');
    my $Align1x=$self->parameter('align 1:x');
    if ($Align11 and ($#{$LinkProb}==0)){
	if ($#{$$LinkProb[0]}==0){
	    my $p=$$LinkProb[0][0];
	    $$LinkProb[0][0]=$p+$Align11-$p*$Align11;
	    return;
	}
    }
    if ($Align1x and ($#{$LinkProb}==0)){
	foreach (0..$#{$$LinkProb[0]}){
	    my $p=$$LinkProb[0][$_];
	    $$LinkProb[0][$_]=$p+$Align1x-$p*$Align1x;
	}
	return;
    }
    if ($Align1x){
	my $ok=1;
	foreach (0..$#{$LinkProb}){
	    if ($#{$$LinkProb[$_]}!=0){$ok=0;}
	}
	if ($ok){
	    foreach (0..$#{$LinkProb}){
		my $p=$$LinkProb[$_][0];
		$$LinkProb[$_][0]=$p+$Align1x-$p*$Align1x;
	    }
	}
    }
}

#===========================================================================
# add scores to the clue matrix for
# pairs of identical tokens with at least one non-alphabetical character
# (hard-coded as /[^A-Za-z]/ !!!!!!)
#===========================================================================

sub alignIdentical{
    my $self=shift;
    my $AlignIdentical=$self->parameter('align identical');
    if (not $AlignIdentical){return;}
    my ($src,$trg,$s,$t,$LinkProb)=@_;
    if ($src=~/[^A-Za-z]/){
	if ($src eq $trg){
	    my @SrcTok=split(/:/,$s);
	    my @TrgTok=split(/:/,$t);
	    foreach my $x (@SrcTok){
		foreach my $y (@TrgTok){
		    my $p=$$LinkProb[$x][$y];
		    $$LinkProb[$x][$y]=$p+$AlignIdentical-$p*$AlignIdentical;
		}
	    }
	}
    }
}




#===========================================================================
#
# topLinkSearch:
#   1) search best link in the matrix
#   2) add link to link clusters
#   3) continue with 1) until finished
#
#===========================================================================

sub topLinkSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @LinkMatrix;
    my @LinkCluster;
    my ($x,$y);


    # ----------------------------

#    print STDERR "---------new sentence-------$MinScore-------\n";
    undef $self->{SORTEDLINKS};

    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);   # clone the matrix

    while (($x,$y)=$self->getTopLink(\@LinkMatrix,$MinScore)){
#	print STDERR "$x:$y\n";
	if ($MinScore=~/\%/){
	    $MinScore=$LinkMatrix[$x][$y]*$MinScore/100;
	    print STDERR "## minscore == $MinScore\n";
	}
	if ($LinkMatrix[$x][$y]<$MinScore){last;}

	$self->add2LinkCluster($x,$y,\@LinkCluster);
	$LinkMatrix[$x][$y]=0;
    }


    # ----------------------------
    # get the links from the set of link clusters

    $self->getClusterLinks(\@LinkCluster,$Links);     # get links
}




#===========================================================================
#
# nextBestSearch:
#    1) find score distance to "next best link" for each word pair
#    2) call topLinkSearch
#
#===========================================================================



sub nextBestSearch{
    my $self=shift;
    my $LinkProb=$self->{matrix};
    $self->nextBestMatrix($LinkProb);
    return $self->topLinkSearch(@_);
}


sub nextBestMatrix{
    my $self=shift;
    my ($LinkProb)=@_;

    my @SortedColumns=();
    my @SortedRows=();

    my $sizeX=$#{$LinkProb};
    my $sizeY=$#{$$LinkProb[0]};

    foreach my $x (0..$sizeX){
	@{$SortedColumns[$x]}=
	    sort {$$LinkProb[$x][$b] <=> $$LinkProb[$x][$a]} (0..$sizeY);
    }
    foreach my $y (0..$sizeY){
	@{$SortedRows[$y]}=
	    sort {$$LinkProb[$b][$y] <=> $$LinkProb[$a][$y]} (0..$sizeX);
    }

    my @LinkMatrix=();
    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);

    my $lowest=0;

    foreach my $x (0..$sizeX){
	foreach my $y (0..$sizeY){
	    my $NextBestY=$SortedColumns[$x][0];
	    if ($NextBestY==$y){$NextBestY=$SortedColumns[$x][1];}
	    my $NextBestX=$SortedRows[$y][0];
	    if ($NextBestX==$x){$NextBestX=$SortedRows[$y][1];}
	    my $NextBest=$LinkMatrix[$NextBestX][$y];
	    if ($LinkMatrix[$x][$NextBestY]>$NextBest){
		$NextBest=$LinkMatrix[$x][$NextBestY];
	    }
	    $$LinkProb[$x][$y]-=$NextBest;
	    if ($$LinkProb[$x][$y]<$lowest){
		$lowest=$$LinkProb[$x][$y];
	    }
	}
    }
    foreach my $x (0..$sizeX){               # normalize!
	foreach my $y (0..$sizeY){           # no negative values
	    $$LinkProb[$x][$y]-=$lowest;     # in the matrix!
	}
    }
    if ($self->parameter('verbose')){
	$self->printClueMatrix($self->{token}->{source},
			       $self->{token}->{target},
			       $LinkProb);
    }
}



#===========================================================================
#
# oneOneFirstSearch:
#    1) find all one-to-one word links first (non-overlapping links)
#    2) add iteratively overlapping links
#
#===========================================================================

sub oneOneFirstSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @LinkMatrix;
    my @LinkCluster;
    my ($x,$y);


    # ----------------------------
    # 1) get all word-to-word links without any overlaps

    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);   # clone the matrix

    while (($x,$y)=$self->getTopLink(\@LinkMatrix,$MinScore)){
	if ($MinScore=~/\%/){
	    $MinScore=$LinkMatrix[$x][$y]*$MinScore/100;
	    print STDERR "## minscore == $MinScore\n";
	}
	if ($LinkMatrix[$x][$y]<$MinScore){last;}
	my @overlap=$self->findClusterOverlap($x,$y,\@LinkCluster);

	if (not @overlap){
	    $LinkCluster[$#LinkCluster+1]={};
	    $LinkCluster[-1]{src}{$x}=1;
	    $LinkCluster[-1]{trg}{$y}=1;
	}
	$LinkMatrix[$x][$y]=0;
    }

    # ----------------------------
    # 2) do it again --> find overlapping links!

    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);   # clone the matrix

    while (($x,$y)=$self->getTopLink(\@LinkMatrix,$MinScore)){
	if ($LinkMatrix[$x][$y]<$MinScore){last;}
	$self->add2LinkCluster($x,$y,\@LinkCluster);
	$LinkMatrix[$x][$y]=0;
    }


    # ----------------------------
    # get the links from the set of link clusters

    $self->getClusterLinks(\@LinkCluster,$Links);     # get links
}




#===========================================================================
# ------------------  directional alignment (source to target) ----------------
#===========================================================================

sub directionalSrcSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my @LinkCluster;
    my ($x,$y);

    my @SrcLinks=$self->bestSrcLinks($MinScore,$competitive);

    foreach (0..$#SrcLinks){
	if (defined $SrcLinks[$_]){
	    $self->add2LinkCluster($_,$SrcLinks[$_],\@LinkCluster);
	}
    }

    $self->getClusterLinks(\@LinkCluster,$Links);
}

#===========================================================================
# ------------------  directional alignment (target to source ) ---------------
#===========================================================================

sub directionalTrgSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my @LinkCluster;
    my ($x,$y);

    my @TrgLinks=$self->bestTrgLinks($MinScore,$competitive);
    foreach (0..$#TrgLinks){
	if (defined $TrgLinks[$_]){
	    $self->add2LinkCluster($TrgLinks[$_],$_,\@LinkCluster);
	}
    }

    $self->getClusterLinks(\@LinkCluster,$Links);
}


#===========================================================================
# competitive linking
#   1) get best word-to-word link (s,t)
#   2) remove alternative links for (s) and for (t)
#   3) go to 1) until finished
#===========================================================================

sub competitiveSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $Token=$self->{token};
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @WordLinks=();
    if ($NrTrg>$NrSrc){
	return $self->directionalTrgSearch($Links,$MinScore,1);
    }
    return $self->directionalSrcSearch($Links,$MinScore,1);
}

#===========================================================================
# refined symmetric link search a la Och&Ney
#
#===========================================================================

sub bidirectionalRefinedSearchOch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my $LinkProb=$self->{matrix};
    my @LinkCluster;
    my %WordLinks=();
    my %InvWordLinks=();
    my ($x,$y);

    #-----------------------------------
    # 1) get directional links

    my @SrcLinks=$self->bestSrcLinks($MinScore,$competitive);
    my @TrgLinks=$self->bestTrgLinks($MinScore,$competitive);

    #-----------------------------------
    # 2) intersection of directional links

    foreach (0..$#SrcLinks){
	if ((defined $SrcLinks[$_]) and
	    ($TrgLinks[$SrcLinks[$_]] eq $_)){
	    $WordLinks{$_}{$SrcLinks[$_]}=1;
	    $InvWordLinks{$SrcLinks[$_]}{$_}=1;
#	    print STDERR "$_ --> $SrcLinks[$_]\n";
	}
    }


    #-----------------------------------
    # 3) add overlapping links
    #    * sort all scores in the matrix
    #    * run through possible links starting with the highest score
    #    * repeat until no more links can be added
    #
    # links (s,t) are added if
    #    * there is no other link for both, s AND t
    #    * or ..the new link is adjacent to another link in source OR target
    #           and thew new link does not create links which have neighbors
    #           in both directions

    my %scores=();
    foreach my $s (0..$#{$LinkProb}){
	foreach my $t (0..$#{$$LinkProb[$s]}){   # put all scores
	    $scores{"$s:$t"}=$$LinkProb[$s][$t]; # in a long list
	}
    }

    my $added=0;
    do{
	$added=0;
	foreach my $pair (sort {$scores{$b} <=> $scores{$a} } keys %scores){
	    if ($scores{$pair}<$MinScore){last;}
	    my ($s,$t)=split(/\:/,$pair);

	    if (((not defined $WordLinks{$s}) or      # if no other links
		 (not keys %{$WordLinks{$s}})) and    # are defined for both,
		((not defined $InvWordLinks{$t}) or   # source AND target
		 (not keys %{$InvWordLinks{$t}}))){   # word:
		$added++;
		$scores{$pair}=0;                     # add the link
		$WordLinks{$s}{$t}=1;
		$InvWordLinks{$t}{$s}=1;
#		print STDERR "add $s --> $t (new)\n";
	    }
	    elsif ((($s>0) and 
		    (defined $WordLinks{$s-1}{$t})) or    # the link has a
		   (defined $WordLinks{$s+1}{$t}) or      # vertical neighbor
		   (($t>0) and 
		    (defined $WordLinks{$s}{$t-1})) or    # or a
		   (defined $WordLinks{$s}{$t+1})){       # horizontal neighbor

		$InvWordLinks{$t}{$s}=1;
		$WordLinks{$s}{$t}=1;                     # if there are
		if (&CheckWordLinks(\%WordLinks,          # no links with
				    \%InvWordLinks)){     # neighbors in both
		    $added++;                             # dimensions! -->
		    $scores{$pair}=0;                     # add the new link
#		    print STDERR "add $s --> $t (adj)\n";
		}
		else{                                     # else:
		    delete $WordLinks{$s}{$t};            # delete the link
		    delete $InvWordLinks{$t}{$s};
#		    print STDERR "reject $s --> $t\n";
		}
	    }
	}
    }
    until (not $added);      # repeat as long as links are added!

    $self->setParameter('adjacent_only',0);
    $self->setParameter('adjacent_score',0);

    foreach my $s (keys %WordLinks){                      # put word-to-word
	foreach my $t (keys %{$WordLinks{$s}}){           # links together
	    $self->add2LinkCluster($s,$t,\@LinkCluster);  # (link clusters)
	}
    }


    #-----------------------------------
    # 4) convert link cluster to word/phrase links

    $self->getClusterLinks(\@LinkCluster,$Links);
}

#-------------------------------------------------------------------------
# check if there are alignments containing horicontal AND vertical links
# (---> return 0 if there are such links!)

sub CheckWordLinks{
    my $srclinks=shift;
    my $trglinks=shift;

    foreach my $s (keys %{$srclinks}){
	foreach my $t (keys %{$$srclinks{$s}}){
	    if (keys %{$$srclinks{$s}} > 1){
		if (keys %{$$trglinks{$t}} > 1){
		    return 0;
		}
	    }
	}
    }
    return 1;
}


#===========================================================================
# symmetric alignment (bi-directional)
#   1) get links in both directions
#   2) get intersection of links
#   3) iteratively add new links to existing link clusters
#===========================================================================


sub bidirectionalRefinedSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my $LinkProb=$self->{matrix};
    my @LinkCluster;
    my ($x,$y);

    #-----------------------------------
    # 1) get directional links

    my @SrcLinks=$self->bestSrcLinks($MinScore,$competitive);
    my @TrgLinks=$self->bestTrgLinks($MinScore,$competitive);

    #-----------------------------------
    # 2) intersection of directional links

    foreach (0..$#SrcLinks){
	if ((defined $SrcLinks[$_]) and
	    ($TrgLinks[$SrcLinks[$_]] eq $_)){
	    $self->add2LinkCluster($_,$SrcLinks[$_],
				   \@LinkCluster);  # (link clusters)
	}
    }


    #-----------------------------------
    # 3) add overlapping links
    #    * sort all scores in the matrix
    #    * run through possible links starting with the highest score
    #    * repeat until no more links can be added
    #
    # links (s,t) are added if
    #    * there is no other link for both, s AND t
    #    * or ..the new link is adjacent to another link in source OR target
    #           and thew new link does not create links which have neighbors
    #           in both directions

    my %scores=();
    foreach my $s (0..$#{$LinkProb}){
	foreach my $t (0..$#{$$LinkProb[$s]}){   # put all scores
	    $scores{"$s:$t"}=$$LinkProb[$s][$t]; # in a long list
	}
    }

    my $added=0;
    do{
	$added=0;
	foreach my $pair (sort {$scores{$b} <=> $scores{$a} } keys %scores){
	    if ($scores{$pair}<$MinScore){last;}
	    my ($s,$t)=split(/\:/,$pair);

	    if ($self->add2LinkCluster($s,$t,\@LinkCluster)){
		$added++;
		delete $scores{$pair};
	    }
	}
    }
    until (not $added);      # repeat as long as links are added!

    #-----------------------------------
    # 4) convert link cluster to word/phrase links

    $self->getClusterLinks(\@LinkCluster,$Links);
}




# ------------------  bi-directional alignment (union) ------------------
#
# union of links in both diretions
#

sub bidirectionalUnion{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my @LinkCluster;
    my ($x,$y);

    my @SrcLinks=$self->bestSrcLinks($MinScore,$competitive);
    foreach (0..$#SrcLinks){
	if (defined $SrcLinks[$_]){
	    $self->add2LinkCluster($_,$SrcLinks[$_],\@LinkCluster);
	}
    }
    my @TrgLinks=$self->bestTrgLinks($MinScore,$competitive);
    foreach (0..$#TrgLinks){
	if (defined $TrgLinks[$_]){
	    $self->add2LinkCluster($TrgLinks[$_],$_,\@LinkCluster);
	}
    }

    $self->getClusterLinks(\@LinkCluster,$Links);
}


# ------------------  bi-directional alignment (intersection) -------------
#
# intersection of links in both directions
#

sub bidirectionalIntersection{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;
    my $competitive=shift;

    my @LinkCluster;
    my ($x,$y);

    my @SrcLinks=$self->bestSrcLinks($MinScore,$competitive);
    my @TrgLinks=$self->bestTrgLinks($MinScore,$competitive);

    foreach (0..$#SrcLinks){
	if ((defined $SrcLinks[$_]) and
	    ($TrgLinks[$SrcLinks[$_]] eq $_)){
	    $self->add2LinkCluster($_,$SrcLinks[$_],\@LinkCluster);
	    $SrcLinks[$_]=undef;
	    $TrgLinks[$SrcLinks[$_]]=undef;
	}
    }

    $self->getClusterLinks(\@LinkCluster,$Links);
}











# ------------------------------------
# get best links from source to target words

sub bestSrcLinks{
    my $self=shift;
    my $MinScore=shift;                 # score threshold
    my $competitive=shift;              # enable/disable competive linking

    if ($competitive){
	return $self->competitiveSrcLinks($MinScore,@_);
    }

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @Links=();

    # ----------------------------
    my @LinkMatrix=();
    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);
    # ----------------------------

    foreach my $s (0..$NrSrc){
	my $bestLink=0;
	my $bestScore=$LinkMatrix[$s][$bestLink];
	foreach my $t (1..$NrTrg){
	    if ($LinkMatrix[$s][$t]>$bestScore){
		$bestLink=$t;
		$bestScore=$LinkMatrix[$s][$bestLink];
	    }
	}
	if ($LinkMatrix[$s][$bestLink]<$MinScore){next;}
#	if ($LinkMatrix[$s][$bestLink]<$MinScore){last;}
	$Links[$s]=$bestLink;
    }

    return @Links;
}

# ------------------------------------
# get best links from target to source words

sub bestTrgLinks{
    my $self=shift;
    my $MinScore=shift;                 # score threshold
    my $competitive=shift;              # enable/disable competive linking

    if ($competitive){
	return $self->competitiveTrgLinks($MinScore,@_);
    }

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @Links=();

    # ----------------------------
    my @LinkMatrix=();
    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);
    # ----------------------------

    foreach my $t (0..$NrTrg){
	my $bestLink=0;
	my $bestScore=$LinkMatrix[$bestLink][$t];
	foreach my $s (1..$NrSrc){
	    if ($LinkMatrix[$s][$t]>$bestScore){
		$bestLink=$s;
		$bestScore=$LinkMatrix[$bestLink][$t];
	    }
	}
	if ($LinkMatrix[$bestLink][$t]<$MinScore){next;}
#	if ($LinkMatrix[$bestLink][$t]<$MinScore){last;}
	$Links[$t]=$bestLink;
    }
    return @Links;
}


# ------------------------------------
# competitive linking from source to target


sub competitiveSrcLinks{
    my $self=shift;
    my $MinScore=shift;                 # score threshold

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};
    my @Links=();

    # ----------------------------
    my @LinkMatrix=();
    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);
    # ----------------------------

    my ($s,$t);
    while (($s,$t)=$self->getTopLink(\@LinkMatrix,$MinScore)){
	if ($LinkMatrix[$s][$t]<$MinScore){next;}
	$LinkMatrix[$s][$t]=0;

	$Links[$s]=$t;

	foreach my $x (0..$NrSrc){$LinkMatrix[$x][$t]=0;}
	foreach my $x (0..$NrTrg){$LinkMatrix[$s][$x]=0;}
    }
    return @Links;
}

# ------------------------------------
# competitive linking from target to source

sub competitiveTrgLinks{
    my $self=shift;
    my $MinScore=shift;                 # score threshold

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};
    my @Links=();

    # ----------------------------
    my @LinkMatrix=();
    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);
    # ----------------------------

    my ($s,$t);
    while (($s,$t)=$self->getTopLink(\@LinkMatrix,$MinScore)){
	if ($LinkMatrix[$s][$t]<$MinScore){next;}
	$LinkMatrix[$s][$t]=0;

	$Links[$t]=$s;

	foreach my $x (0..$NrSrc){$LinkMatrix[$x][$t]=0;}
	foreach my $x (0..$NrTrg){$LinkMatrix[$s][$x]=0;}
    }
    return @Links;
}


#==========================================================================
#
# get the word-to-word link with the highest score from the clue matrix
#
#==========================================================================

sub getTopLink{
    my $self=shift;
    my $LinkProb=shift;
    my $MinScore=shift;

    my $bestX=undef;
    my $bestY=undef;
    my $bestVal;

    if (not ref($self->{SORTEDLINKS})){
	$self->sortLinks($LinkProb,$MinScore);
    }
    my $top=shift @{$self->{SORTEDLINKS}};
    if (not defined $top){
	delete $self->{SORTEDLINKS};
    }
    my @link=split (':',$top);
    return @link;
}

sub sortLinks{
    my $self=shift;
    my $LinkProb=shift;
    my $MinScore=shift;
    $self->{ALLLINKS}={};
    foreach my $x (0..$#{$LinkProb}){
	foreach my $y (0..$#{$$LinkProb[$x]}){
	    if ($$LinkProb[$x][$y]<$MinScore){next;}
	    $self->{ALLLINKS}->{"$x:$y"}=$$LinkProb[$x][$y];
	}
    }
    @{$self->{SORTEDLINKS}}=
	sort {$self->{ALLLINKS}->{$b} <=> $self->{ALLLINKS}->{$a}} 
    keys %{$self->{ALLLINKS}};
}

sub getTopLinkOld{
    my $self=shift;
    my $LinkProb=shift;

    my $bestX=undef;
    my $bestY=undef;
    my $bestVal;

    foreach my $x (0..$#{$LinkProb}){
	my @sort = sort {$$LinkProb[$x][$b] <=> $$LinkProb[$x][$a]} 
	                (0..$#{$$LinkProb[$x]});
	if ($$LinkProb[$x][$sort[0]]>$bestVal){
	    $bestVal=$$LinkProb[$x][$sort[0]];
	    $bestX="$x";
	    $bestY="$sort[0]";
	}
    }
    if ((defined $bestX) and (defined $bestY)){
	return ($bestX,$bestY);
    }
    else{
	return ();
    }
}

#==========================================================================
#
# getClusterLinks:
#    make word/phrase links out of link clusters
#    (add all necessary information for storing links, 
#     e.g. token pairs, id's, byte spans)
#
#==========================================================================


sub getClusterLinks{
    my $self=shift;
    my $LinkCluster=shift;
    my $Links=shift;

    my $LinkProb=$self->{matrix};
    my $TokenAttr=$self->{tokenAttr};

    if (ref($Links) ne 'HASH'){$Links={};}

    foreach (0..$#{$LinkCluster}){
	if (keys %{$$LinkCluster[$_]{src}}){
	    if (keys %{$$LinkCluster[$_]{trg}}){
		my $src=join ':',sort {$a<=>$b} keys %{$$LinkCluster[$_]{src}};
		my $trg=join ':',sort {$a<=>$b} keys %{$$LinkCluster[$_]{trg}};
		my $score=$self->getMatrixScore($LinkProb,
						$$LinkCluster[$_]{src},
						$$LinkCluster[$_]{trg});
		my $link=$self->getLinkString($TokenAttr,$src,$trg);

		$$Links{$src}{link}=$link;
		$$Links{$src}{source}=
		    $self->ngramIDs($src,$TokenAttr,'source');
		$$Links{$src}{target}=
		    $self->ngramIDs($trg,$TokenAttr,'target');
		my $span=$self->ngramSpans($src,$TokenAttr,'source');
		if ($span){$$Links{$src}{src}=$span;}
		$span=$self->ngramSpans($trg,$TokenAttr,'target');
		if ($span){$$Links{$src}{trg}=$span;}
		$$Links{$src}{target}=
		    $self->ngramIDs($trg,$TokenAttr,'target');
		$$Links{$src}{score}=$score;
	    }
	}
    }
    return $Links;
}


sub getMatrixScore{
    my $self=shift;
    my ($matrix,$src,$trg)=@_;
    my $score=0;
    my $count;
    foreach my $s (keys %{$src}){
	foreach my $t (keys %{$trg}){
	    if ($$matrix[$s][$t]>0){
		$score+=log($$matrix[$s][$t]);
		$count++;
	    }
	}
    }
    if ($count){
	$score/=$count;
    }
    return exp($score);
}


#==========================================================================
#
# add links to link clusters
#
#==========================================================================

sub add2LinkCluster{
    my $self=shift;
    my ($x,$y,$cluster)=@_;
    my @overlap=$self->findClusterOverlap($x,$y,$cluster);
    if ((not $self->parameter('allow_multiple_overlaps')) and (@overlap>1)){
#	print STDERR "disregard $x - $y !\n";
	return 0;
    }
    elsif (@overlap){
	if ($self->parameter('in_phrases_only')){
	    if ($self->parameter('fill_phrases')){
		if (not $self->fillPhrases($x,$y,$cluster,$overlap[0])){
		    return 0;
		}
	    }
	    if (not $self->isInPhrase($x,$y,$$cluster[$overlap[0]])){
		return 0;
	    }
	}
	if ($self->parameter('adjacent_only')){
	    if (not $self->isAdjacent($x,$y,$$cluster[$overlap[0]])){
		return 0;
	    }
	}
	if ($self->parameter('adjacent_score')){
	    if (not $self->isAdjacentScore($x,$y,$$cluster[$overlap[0]],
				      $self->parameter('adjacent_score'))){
		return 0;
	    }
	}
	$$cluster[$overlap[0]]{src}{$x}=1;
	$$cluster[$overlap[0]]{trg}{$y}=1;
	if (@overlap>1){                              # join all overlapping
	    foreach my $o (1..$#overlap){             # link clusters!
		foreach (keys %{$$cluster[$overlap[$o]]{src}}){
		    delete $$cluster[$overlap[$o]]{src}{$_};
		    $$cluster[$overlap[0]]{src}{$_}=1;
		}
		foreach (keys %{$$cluster[$overlap[$o]]{trg}}){
		    delete $$cluster[$overlap[$o]]{trg}{$_};
		    $$cluster[$overlap[0]]{trg}{$_}=1;
		}
	    }
	}
    }
    else{
	$$cluster[$#{$cluster}+1]={};
	$$cluster[-1]{src}{$x}=1;
	$$cluster[-1]{trg}{$y}=1;
    }
    return 1;
}


sub isInPhrase{
    my $self=shift;
    my ($newX,$newY,$cluster)=@_;
    my @srcAccepted=keys %{$self->{srcToken}};
    my @trgAccepted=keys %{$self->{trgToken}};

    my %src=%{$cluster->{src}};
    my %trg=%{$cluster->{trg}};
    $src{$newX}=1;
    $trg{$newY}=1;

#    my $srcPhr=join ':',sort {$a <=> $b} keys %src;
#    my $trgPhr=join ':',sort {$a <=> $b} keys %trg;

    my $srcPhr=join '(:[0-9]+)?:',sort {$a <=> $b} keys %src;
    my $trgPhr=join '(:[0-9]+)?:',sort {$a <=> $b} keys %trg;

    if (grep(/$srcPhr/,@srcAccepted)){
	if (grep(/$trgPhr/,@trgAccepted)){
#	    my @missing=$self->getMissingTokens(\%src,\%trg);
	    return 1;
	}
    }
    return 0;
}

sub fillPhrases{
    my $self=shift;
    my ($newX,$newY,$cluster,$nr)=@_;

    my %link=();
    %{$link{src}}=%{$cluster->[$nr]->{src}};
    %{$link{trg}}=%{$cluster->[$nr]->{trg}};
    $link{src}{$newX}=1;
    $link{trg}{$newY}=1;

    my @missing=$self->getMissingTokens($link{src},$link{trg});
    if (not @missing){
	return 0;
    }
    my @missSrc=split(/:/,$missing[0]);
    my @missTrg=split(/:/,$missing[1]);
    my %overlap=();
    foreach my $s (@missSrc){
	$self->findSrcOverlap($s,$cluster,\%overlap);
	$link{src}{$s}=1;
    }
    foreach my $t (@missTrg){
	$self->findTrgOverlap($t,$cluster,\%overlap);
	$link{trg}{$t}=1;
    }
    foreach (keys %overlap){
	if (not $self->isIncluded($cluster->[$_],\%link)){
	    foreach (@missSrc){delete $link{src}{$_};}
	    foreach (@missTrg){delete $link{trg}{$_};}
	    return 0;
	}

#############  !!!!!!!!!!!!!! change this:
	print STDERR "delete cluster $_!\n";
	$cluster->[$_]->{src}=();   
	$cluster->[$_]->{trg}=();
#############  !!!!!!!!!!!!!! change this:

    }

    if (@missSrc or @missTrg){                  # ... just for information
	print STDERR "fill cluster $nr with missing tokens!\n";
    }

    foreach (keys %{$link{src}}){
	$cluster->[$nr]->{src}->{$_}=1;
    }
    foreach (keys %{$link{trg}}){
	$cluster->[$nr]->{trg}->{$_}=1;
    }
    return 1;
}


#sub removeClusterInclusions{
#    my $self=shift;
#    my $cluster=shift;
#    foreach my $c (@{$cluster}){
#	my $src=join '(:[0-9]+)?:',sort {$a <=> $b} keys %{$$cluster[$c]{src}};
#	my $trg=join '(:[0-9]+)?:',sort {$a <=> $b} keys %{$$cluster[$c]{trg}};
#    }
#}


sub isIncluded{
    my $self=shift;
    my ($cluster1,$cluster2)=@_;
    foreach (keys %{$cluster1->{src}}){
	if (not defined $cluster2->{src}->{$_}){return 0;}
    }
    foreach (keys %{$cluster1->{trg}}){
	if (not defined $cluster2->{trg}->{$_}){return 0;}
    }
    return 1;
}

sub findSrcOverlap{
    my $self=shift;
    return $self->findOverlap('src',@_);
}
sub findTrgOverlap{
    my $self=shift;
    return $self->findOverlap('trg',@_);
}

sub findOverlap{
    my $self=shift;
    my ($lang,$token,$cluster,$overlap)=@_;
    my @c=grep (defined $$cluster[$_]{$lang}{$token},0..$#{$cluster});
    foreach (@c){
	$$overlap{$_}=1;
    }
}

sub getMissingTokens{
    my $self=shift;
    my ($src,$trg)=@_;
    my @srcAccepted=keys %{$self->{srcToken}};
    my @trgAccepted=keys %{$self->{trgToken}};

    my $srcPhr=join '(:[0-9]+)?:',sort {$a <=> $b} keys %{$src};
    my $trgPhr=join '(:[0-9]+)?:',sort {$a <=> $b} keys %{$trg};

    my $missingSrc=undef;
    my $missingTrg=undef;

    my @match;

    if (@match=grep(/$srcPhr/,@srcAccepted)){

	@match=sort {length($a) <=> length($b)} @match;
	if ($match[0]=~/^(.*)$srcPhr(.*)$/){
	    $missingSrc="$1$2$3$4$5$6$7$8$9";
	}

	if (@match=grep(/$trgPhr/,@trgAccepted)){

	    @match=sort {length($a) <=> length($b)} @match;
	    if ($match[0]=~/^(.*)$trgPhr(.*)$/){
		$missingTrg="$1$2$3$4$5$6$7$8$9";
	    }
	    $missingSrc=~s/^://;$missingSrc=~s/:$//;
	    $missingTrg=~s/^://;$missingTrg=~s/:$//;
	    return ($missingSrc,$missingTrg);
	}
    }

    return ();
}


sub isAdjacent{
    my $self=shift;
    my ($x,$y,$cluster)=@_;
    if ((defined $$cluster{src}{$x}) and
	((defined $$cluster{trg}{$y-1}) or
	 ((defined $$cluster{trg}{$y+1})))){
	return 1;
    }
    if ((defined $$cluster{trg}{$y}) and
	((defined $$cluster{src}{$x-1}) or
	 ((defined $$cluster{src}{$x+1})))){
	return 1;
    }
    return 0;
}

sub isAdjacentScore{
    my $self=shift;
    my ($x,$y,$cluster,$p)=@_;

    if ((defined $$cluster{src}{$x}) and
	(defined $$cluster{trg}{$y-1})){
	if ($self->{matrix}->[$x]->[$y]>=$self->{matrix}->[$x]->[$y-1]*$p){
	    return 1;
	}
	return 0;
    }
    if ((defined $$cluster{src}{$x}) and
	(defined $$cluster{trg}{$y+1})){
	if ($self->{matrix}->[$x]->[$y]>=$self->{matrix}->[$x]->[$y+1]*$p){
	    return 1;
	}
	return 0;
    }
    if ((defined $$cluster{src}{$x-1}) and
	(defined $$cluster{trg}{$y})){
	if ($self->{matrix}->[$x]->[$y]>=$self->{matrix}->[$x-1]->[$y]*$p){
	    return 1;
	}
	return 0;
    }
    if ((defined $$cluster{src}{$x+1}) and
	(defined $$cluster{trg}{$y})){
	if ($self->{matrix}->[$x]->[$y]>=$self->{matrix}->[$x+1]->[$y]*$p){
	    return 1;
	}
	return 0;
    }
    return 0;
}


sub findClusterOverlap{
    my $self=shift;
    my ($x,$y,$cluster)=@_;
    my @overlap=();
    foreach (0..$#{$cluster}){
	if (defined $$cluster[$_]{src}{$x}){
	    push(@overlap,$_);
	}
	elsif (defined $$cluster[$_]{trg}{$y}){
	    push(@overlap,$_);
	}
    }
    return @overlap;
}



#========================================================================

sub cloneLinkMatrix{
    my $self=shift;
    my $matrix=shift;
    my $clone=shift;

    if (ref($matrix) ne 'ARRAY'){return ();}
    if (ref($clone) ne 'ARRAY'){$clone=[];}

    foreach my $x (0..$#{$matrix}){
	foreach my $y (0..$#{$$matrix[$x]}){
	    $$clone[$x][$y]=$$matrix[$x][$y];
	}
    }
    return $clone;
}




#==========================================================================
#
#
#
#==========================================================================



sub clueMatrixToHtml{
    my $self=shift;

    my $Matrix=$self->{matrix};
    my $Token=$self->{token};
    my $SrcTok=$$Token{source};
    my $TrgTok=$$Token{target};
    my $nrSrc=$#{$$Token{source}};
    my $nrTrg=$#{$$Token{target}};

    my $max;
    foreach my $s (0..$nrSrc){
        foreach my $t (0..$nrTrg){
            if ($Matrix->[$s]->[$t]>$max){$max=$Matrix->[$s]->[$t];}
        }
    }
    if (not $max){$max=1;}

    my $html="<p>\n";
    $html.="<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";
    $html.="<tr><th></th>\n";

    foreach my $t (0..$nrTrg){
        my $str=$TrgTok->[$t];
        $html.="<th>$str</th>\n";
    }

    foreach my $s (0..$nrSrc){
        $html.="</tr><tr>\n";
        my $str=$SrcTok->[$s];
        $html.="<th>$str</th>\n";
        foreach my $t (0..$nrTrg){
            my $score=0;
            if ($Matrix->[$s]){
                if ($Matrix->[$s]->[$t]){
                    $score=$Matrix->[$s]->[$t];
                }
            }
            my $color=255-$score*256/$max;
            if ($color==-1){$color=0;}
	    my $hex=sprintf("%X",$color);
	    if (length($hex)<2){$hex="0$hex";}
	    my $val=int(100*$score);
            if ($color<128){
		$html.="<td bgcolor=\"#$hex$hex$hex\">";
		$html.='<font color="#ffffff">';
		$html.="$val</font></td>\n";
	    }
	    else{
		$html.="<td bgcolor=\"#$hex$hex$hex\">";
                $html.="$val</td>\n";
	    }
        }
    }
    $html.="</tr></table><hr>\n";
    return $html;
}



sub printHtmlClueMatrix{
    my $self=shift;
    print STDERR $self->clueMatrixToHtml();
}



sub printClueMatrix{
    my $self=shift;

    my ($SrcTok,$TrgTok,$Matrix)=@_;

    my $nrSrc=$#{$SrcTok};
    my $nrTrg=$#{$TrgTok};

    my @char=();
    &MakeCharArr($TrgTok,\@char);
    foreach my $c (0..$#char){
	printf STDERR "\n%10s",' '; 
	foreach (@{$char[$c]}){
	    printf STDERR "%4s",$_;
	}
    }

    print STDERR "\n";

    foreach my $s (0..$nrSrc){
	my $str=substr($SrcTok->[$s],0,10);
	$str=&Uplug::Encoding::convert($str,'utf-8','iso-8859-1');

	printf STDERR "%10s",$str; 
	foreach my $t (0..$nrTrg){
	    my $score=0;
	    if ($Matrix->[$s]){
		if ($Matrix->[$s]->[$t]){
		    $score=$Matrix->[$s]->[$t];
		}
	    }
	    printf STDERR " %3d",$score*100;
	}
	print STDERR "\n";
    }
}


sub MakeCharArr{
    my ($tok,$char)=@_;

    my @lat1=@{$tok};

#    my @lat1=();
#    foreach (0..$#{$tok}){
#	$lat1[$_]=&Uplug::Data::encode($tok->[$_],'utf-8','iso-8859-1');
#    }

    map ($lat1[$_]=&Uplug::Encoding::convert($lat1[$_],'utf-8','iso-8859-1'),
	 (0..$#lat1));

    my $max=&MaxLength(\@lat1);
    foreach my $t (0..$#{$tok}){
	my @c=split(//,$lat1[$t]);
	foreach (1..$max){
	    if (@c){
		$char->[$max-$_]->[$t]=pop(@c);
#		$char->[$max-$_]->[$t]=shift(@c);
	    }
	    else{$char->[$max-$_]->[$t]=' ';}
	}
    }
}

sub MaxLength{
    my ($tok)=@_;
    my $max=0;
    foreach (@{$tok}){
	if (length($_)>$max){$max=length($_);}
    }
    return $max;
}









#==========================================================================
#==========================================================================
#
# from here .... old stuff ......
#
#==========================================================================
#==========================================================================











sub getTopLogLink{
    my $self=shift;
    my $LinkProb=shift;

    my $bestX=undef;
    my $bestY=undef;
    my $bestVal;
    foreach my $x (0..$#{$LinkProb}){
	my @sort = sort {$$LinkProb[$x][$a] <=> $$LinkProb[$x][$b]} 
	                (0..$#{$$LinkProb[$x]});
	@sort=grep(defined $$LinkProb[$x][$_],@sort);
	if (not @sort){next;}
	if (not defined $bestVal){
	    $bestVal=$$LinkProb[$x][$sort[0]];
	    $bestX="$x";
	    $bestY="$sort[0]";
	}
	elsif ($$LinkProb[$x][$sort[0]]<$bestVal){
	    $bestVal=$$LinkProb[$x][$sort[0]];
	    $bestX="$x";
	    $bestY="$sort[0]";
	}
    }
    if ((defined $bestX) and (defined $bestY)){
	return ($bestX,$bestY);
    }
    else{
	return ();
    }
}




sub getMatrixScore2{
    my $self=shift;
    my ($matrix,$src,$trg)=@_;
    my $score=0;
    foreach my $s (keys %{$src}){
	foreach my $t (keys %{$trg}){
	    $score+=$$matrix[$s][$t]-$score*$$matrix[$s][$t];
	}
    }
    return $score;
}







sub MakeCharArrNew{
    my ($tok,$char)=@_;
    my $max=0;
    foreach (@{$tok}){
	if (length($_)>$max){$max=length($_);}
    }
    $max=int($max/3+1);
    foreach my $t (0..$#{$tok}){
	my @c=split(//,$tok->[$t]);
	foreach (1..$max){
	    if (@c){
		$char->[$max-$_]->[$t]=shift(@c);
		$char->[$max-$_]->[$t].=shift(@c);
		$char->[$max-$_]->[$t].=shift(@c);
	    }
	    else{$char->[$max-$_]->[$t]=' ';}
	}
    }
}









sub SingleWordClusters{
    my ($links,$cluster)=@_;

    foreach my $s (keys %{$links}){
	foreach my $t (keys %{$$links{$s}}){
	    $$cluster[$#{$cluster}+1]={};
	    $$cluster[-1]{src}{$s}=1;
	    $$cluster[-1]{trg}{$t}=1;
	}
    }
    return 1;
}


#===========================================================================














sub normalizeMatrix{
    my $self=shift;
    my ($LinkProb)=@_;

    my $sizeX=$#{$LinkProb}+1;
    my $sizeY=$#{$$LinkProb[0]}+1;

    foreach my $x (0..$#{$LinkProb}){
	foreach my $y (0..$#{$$LinkProb[$x]}){
	    $$LinkProb[$x][$sizeY]+=$$LinkProb[$x][$y];
	    $$LinkProb[$sizeX][$y]+=$$LinkProb[$x][$y];
	}
    }
    foreach my $x (0..$#{$LinkProb}){
	foreach my $y (0..$#{$$LinkProb[$x]}){
#	    my $sum=$$LinkProb[$x][$sizeY]+
#		$$LinkProb[$sizeX][$y]-
#		2*$$LinkProb[$x][$y];
#	    my $sum=$$LinkProb[$x][$sizeY]+
#		$$LinkProb[$sizeX][$y];
	    my $sum=$$LinkProb[$x][$sizeY]+
		$$LinkProb[$sizeX][$y]-
		$$LinkProb[$x][$y];
	    if ($sum){
		$$LinkProb[$x][$y]/=$sum;
	    }
	}
    }
    foreach (0..$sizeX-1){
	pop (@{$$LinkProb[$_]});
    }
    pop @{$LinkProb};
}










sub matrixSearch5{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @LinkMatrix;
    my @LinkCluster;
    my ($x,$y);

    # ----------------------------
    # 2) do it again --> find overlapping links!

    $self->cloneLinkMatrix($LinkProb,\@LinkMatrix);   # clone the matrix

    my @linklist=();
    while (($x,$y)=$self->getTopLink(\@LinkMatrix)){
	my $idx=$#linklist+1;
	$linklist[$idx][0]=$x;
	$linklist[$idx][1]=$y;
	$linklist[$idx][2]=$$LinkProb[$x][$y];
	if ($LinkMatrix[$x][$y]<$MinScore){last;}
	$LinkMatrix[$x][$y]=0;
    }
    my @overlaplinks=();
    while (@linklist){
	my $x=$linklist[0][0];
	my $y=$linklist[0][1];
	my $p=$linklist[0][2];
	if (@overlaplinks){
	    while (@overlaplinks and ($overlaplinks[0][2]*0.8>$p)){
		$self->add2LinkCluster($overlaplinks[0][0],$overlaplinks[0][1],
				       \@LinkCluster);
		shift (@overlaplinks);
	    }
	}
	my @overlap=$self->findClusterOverlap($x,$y,\@LinkCluster);
	if ((not @overlap) or ($p*0.8>$linklist[1][2])){
	    $self->add2LinkCluster($x,$y,\@LinkCluster);
	    shift (@linklist);
	}
	else{
	    my $idx=$#overlaplinks+1;
	    @{$overlaplinks[$idx]}=@{$linklist[0]};
	    shift (@linklist);
	}
    }
    while (@overlaplinks){
	$self->add2LinkCluster($overlaplinks[0][0],$overlaplinks[0][1],
			       \@LinkCluster);
	shift (@overlaplinks);
    }

    # ----------------------------
    # get the links from the set of link clusters

    $self->getClusterLinks(\@LinkCluster,$Links);     # get links
}





sub matrixSearch10{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $keep=10;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};


    my %links=();
    &GetLinks($LinkProb,\%links);

    my %align=();
    foreach (sort {$links{$b} <=> $links{$a}} keys %links){
	$self->addLink(\%align,$_,$links{$_});
	&KeepBestAlign(\%align,$keep);
    }

    my @sort=sort {$align{$b}{relscore} <=> $align{$a}{relscore}} keys %align;
    $self->getClusterLinks($align{$sort[0]}{LinkCluster},$Links);
    return;

#    my @LinkCluster=();
#    my @sort=sort {$align{$b}{relscore} <=> $align{$a}{relscore}} keys %align;
#    my @pairs=split(/\&/,$sort[0]);
#    foreach my $l (@pairs){
#	my ($x,$y)=split(/\:/,$l);
#	$self->add2LinkCluster($x,$y,\@LinkCluster);
#    }
#    $self->getClusterLinks(\@LinkCluster,$Links);
}

sub addLink{
    my $self=shift;
    my ($align,$link,$score)=@_;
    my ($src,$trg)=split(/\:/,$link);
    foreach (keys %{$align}){
	my $key=$_.'&'.$link;
	my $cluster=&Dumper($$align{$_}{LinkCluster});
	$$align{$key}{LinkCluster}=eval $cluster;
#	@{$$align{$key}{LinkCluster}}=@{$$align{$_}{LinkCluster}};
	if ($self->add2LinkCluster($src,$trg,$$align{$key}{LinkCluster})){
	    $$align{$key}{score}=$$align{$_}{score}+$score;
	    %{$$align{$key}{src}}=%{$$align{$_}{src}};
	    %{$$align{$key}{trg}}=%{$$align{$_}{trg}};
	    $$align{$key}{src}{$src}=$trg;
	    $$align{$key}{trg}{$trg}=$src;
	    my $nrlinks=
		(scalar keys %{$$align{$key}{src}})+
		(scalar keys %{$$align{$key}{trg}});
	    $$align{$key}{relscore}=$$align{$key}{score}/($nrlinks*$nrlinks*$nrlinks);
	}
	else{
	    delete $$align{$key};
	}
    }
    $$align{$link}{score}=$score;
    $$align{$link}{src}{$src}=$trg;
    $$align{$link}{trg}{$trg}=$src;
    $$align{$link}{relscore}=$$align{$link}{score}/8;
    $$align{$link}{LinkCluster}=[];
    $self->add2LinkCluster($src,$trg,$$align{$link}{LinkCluster});
}

sub KeepBestAlign{
    my ($align,$nr)=@_;
    my @sort=sort {$$align{$b}{relscore} <=> $$align{$a}{relscore}} 
    keys %{$align};
    foreach ($nr..$#sort){
	delete $$align{$sort[$_]};
    }
}


sub GetLinks{
    my ($matrix,$links)=@_;
    foreach my $x (0..$#{$matrix}){
	foreach my $y (0..$#{$$matrix[$x]}){
	    if ($$matrix[$x][$y]){
		$$links{"$x:$y"}=log($$matrix[$x][$y]);
	    }
	}
    }
}


sub matrixBeamSearch{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $BeamSize=5;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my %beam;
    my %toplinks=();
    foreach my $x (0..$NrSrc){
	@{$toplinks{src}{$x}}=&GetBestTrgLinks($$LinkProb[$x]);
	if (not @{$toplinks{src}{$x}}){next;}
	my $y=$toplinks{src}{$x}[0];
	my $score=log($$LinkProb[$x][$y]);
	$beam{0}{src}{$x}{$y}=$score;
	$beam{0}{trg}{$y}{$x}=$score;
	$beam{0}{score}+=$score;
    }
    foreach my $y (0..$NrTrg){
	@{$toplinks{trg}{$y}}=&GetBestSrcLinks($LinkProb,$y);
	if (not @{$toplinks{trg}{$y}}){next;}
	if (not defined $beam{0}{trg}{$y}){
	    my $x=$toplinks{trg}{$y}[0];
	    my $score=log($$LinkProb[$x][$y]);
	    $beam{0}{src}{$x}{$y}=$score;
	    $beam{0}{trg}{$y}{$x}=$score;
	    $beam{0}{score}+=$score;
	}
    }
    my ($newx,$newy,$newscore);
#    do {
#	($newx,$newy,$newscore)=&GetBestLink(\%toplinks,$LinkProb);
#    }
#    until (not $newscore);
	($newx,$newy,$newscore)=&GetBestLink(\%toplinks,$LinkProb);
    $beam{0}{LinkCluster}=[];
    foreach my $x (keys %{$beam{0}{src}}){
	foreach my $y (keys %{$beam{0}{src}{$x}}){
	    $self->add2LinkCluster($x,$y,$beam{0}{LinkCluster});
	}
    }
    $self->getClusterLinks($beam{0}{LinkCluster},$Links);
}


sub GetBestLink{
    my $toplinks=shift;
    my $probs=shift;

    my ($x1,$y1,$bestx);
    my ($x2,$y2,$besty);

    foreach (keys %{$$toplinks{src}}){
	if (not keys %{$$toplinks{src}}){next;}
	if (not @{$$toplinks{src}{$_}}){next;}
	if ((not defined $bestx) or
	    ($$probs[$_][$$toplinks{src}{$_}[0]]>$bestx)){
	    $x1=$_;
	    $y1=$$toplinks{src}{$_}[0];
	    $bestx=$$probs[$x1][$y1];
	}
    }
    foreach (keys %{$$toplinks{trg}}){
	if (not keys %{$$toplinks{trg}}){next;}
	if (not @{$$toplinks{trg}{$_}}){next;}
	if ((not defined $besty) or
	    ($$probs[$$toplinks{trg}{$_}[0]][$_]>$besty)){
	    $x2=$_;
	    $y2=$$toplinks{trg}{$_}[0];
	    $besty=$$probs[$x2][$y2];
	}
    }
    if ((defined $x1) and ($bestx>$besty)){
	shift @{$$toplinks{src}{$x1}};
	return ($x1,$y1,$bestx);
    }
    if (defined $y2){
	shift @{$$toplinks{trg}{$y2}};
	return ($x2,$y2,$besty);
    }
    return ();
}



sub GetBestTrgLinks{
    my $probs=shift;
    my $nr=shift;
    my @sort=grep ($$probs[$_]>0,(0..$#{$probs}));
    @sort = sort {$$probs[$b] <=> $$probs[$a]} @sort;
    if ($nr){splice @sort,$nr;}
    return @sort;
}

sub GetBestSrcLinks{
    my $probs=shift;
    my $y=shift;
    my $nr=shift;

    my %scores=();
    foreach my $x (0..$#{$probs}){
	$scores{$x}=$$probs[$x][$y];
    }
    my @sort=grep ($$probs[$_][$y]>0,keys %scores);
    @sort = sort {$scores{$b} <=> $scores{$a}} @sort;
    if ($nr){splice @sort,$nr;}
    return @sort;
}













sub matrixBeamSearchOld2{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $BeamSize=5;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my %Beam;

    my @trg=&GetBestTrgLinks($$LinkProb[0],$BeamSize);
    foreach my $y (@trg){
	my $score=$$LinkProb[0][$y];
	$self->AddInitialBeamScore(\%Beam,0,$y,$score);
    }

    foreach my $x (1..$NrSrc){
	my %NewBeam=();
	my @trg=&GetBestTrgLinks($$LinkProb[$x],$BeamSize);
	foreach my $y (@trg){
	    my $score=$$LinkProb[$x][$y];
	    $self->AddBeamScore(\%Beam,\%NewBeam,$x,$y,$score);
	}
	&GetBestBeams(\%Beam,\%NewBeam,$BeamSize);
    }

    $self->getClusterLinks($Beam{1}{LinkCluster},$Links);
#     $self->getClusterLinks($Beam{0}{LinkCluster},$Links);
}

sub AddBeamScore{
    my $self=shift;
    my ($beam,$new,$x,$y,$score)=@_;
    if (not $score){return;}

    my $last=keys %{$new};

    foreach my $b (keys %{$beam}){
	$last++;
	$$new{$last}={};
	&CloneBeam($$beam{"$b"},$$new{$last});
#	if ($self->add2LinkCluster($x,$y,$$new{$last}{LinkCluster})){
	    $$new{$last}{score}+=log($score);
	    $$new{$last}{link}{"$self->{token}->{source}->[$x]:$self->{token}->{target}->[$y]"}=$score;
#	    $$new{$last}{src}{$x}=1;
#	    $$new{$last}{trg}{$y}=1;
#	    $self->add2LinkCluster($x,$y,$$new{$last}{LinkCluster});
#	}
#	else{
#	    delete $$new{$last};
#	    $last--;
#	}
    }
}


sub AddInitialBeamScore{
    my $self=shift;
    my ($beam,$x,$y,$score)=@_;
    if (not $score){return;}
    my $size=keys %{$beam};
    $size++;
    $$beam{$size}{score}+=log($score);
    $$beam{$size}{link}{"$self->{token}->{source}->[$x]:$self->{token}->{target}->[$y]"}=$score;
#    $$beam{$size}{src}{$x}=1;
#    $$beam{$size}{trg}{$y}=1;
    $$beam{$size}{LinkCluster}=[];
}


sub GetBestBeams{
    my ($beam,$new,$size)=@_;
    my %scores=();
    foreach my $b (keys %{$new}){
	$scores{$b}=$new->{$b}->{score};
    }
    my @sort = sort {$scores{$b} <=> $scores{$a}} keys %scores;
    foreach (0..$size){
	&CloneBeam($$new{"$sort[$_]"},$$beam{"$_"});
    }
}

sub CloneBeam{
    my ($old,$new)=@_;

    if (ref($$old{link}) eq 'HASH'){%{$$new{link}}=%{$$old{link}};}
    if (ref($$old{src}) eq 'HASH'){%{$$new{src}}=%{$$old{src}};}
    if (ref($$old{trg}) eq 'HASH'){%{$$new{trg}}=%{$$old{trg}};}
    $$new{score}=$$old{score};
    if (ref($$old{LinkCluster}) eq 'ARRAY'){
	@{$$new{LinkCluster}}=@{$$old{LinkCluster}};
    }
		   
#    my $string=Dumper($old);
#    $new=eval $string;
}









sub matrixBeamSearchOld{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $BeamSize=5;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my %Beam;
    foreach (0..$BeamSize){
	$Beam{$_}{LinkCluster}=[];
    }


    foreach my $x (0..$NrSrc){

	my $y=&GetLowestTrgLink($$LinkProb[$x]);
	my $score=$$LinkProb[$x][$y];

#	my $y=&GetBestTrgLink($$LinkProb[$x]);
#	my $score=$$LinkProb[$x][$y];

	foreach my $i (0..$BeamSize){                         # add lowest score
	    if (not $score){last;}                            # to each beam
	    $Beam{$i}{newscore}=$Beam{$i}{score}+log($score);
	    $Beam{$i}{newsrc}=$x;
	    $Beam{$i}{newtrg}=$y;
	}


	foreach my $y (0..$NrTrg){
	    my $score=$$LinkProb[$x][$y];
	    if (not $score){next;}
	    &AddScoreToBeam(\%Beam,$x,$y,$score,$BeamSize);
	}
	foreach (0..$BeamSize){                              # add links
	    $Beam{$_}{score}=$Beam{$_}{newscore};            # to link clusters
	    $Beam{$_}{src}{$Beam{$_}{newsrc}}=1;
	    $Beam{$_}{trg}{$Beam{$_}{newtrg}}=1;
	    $self->add2LinkCluster($Beam{$_}{newsrc},
				   $Beam{$_}{newtrg},
				   $Beam{$_}{LinkCluster});
	}
    }


    foreach my $y (0..$NrTrg){             # links for target tokens ...

#	my $x=&GetBestSrcLink($LinkProb,$y);
	my $x=&GetLowestSrcLink($LinkProb,$y);

	foreach my $i (0..$BeamSize){                         # add lowest score
	    my $score=$$LinkProb[$x][$y];                      # to each beam
	    if ($Beam{$i}{src}{$x} and $Beam{$i}{trg}{$y}){   # only if they
		$Beam{$i}{newscore}=$Beam{$i}{score};         # are both tokens
	    }                                                 # are not linked
	    else{                                             # yet
		if (not $score){last;}
		$Beam{$i}{newscore}=$Beam{$i}{score}+log($score);
		$Beam{$i}{newsrc}=$x;
		$Beam{$i}{newtrg}=$y;
	    }
	}

	foreach my $x (0..$NrSrc){
	    my $score=$$LinkProb[$x][$y];
	    if (not $score){next;}
	    &AddScoreToBeam(\%Beam,$x,$y,$score,$BeamSize);
	}
	foreach (0..$BeamSize){                              # add links
	    $Beam{$_}{score}=$Beam{$_}{newscore};            # to link clusters
	    $Beam{$_}{src}{$Beam{$_}{newsrc}}=1;
	    $Beam{$_}{trg}{$Beam{$_}{newtrg}}=1;
	    $self->add2LinkCluster($Beam{$_}{newsrc},
				   $Beam{$_}{newtrg},
				   $Beam{$_}{LinkCluster});
	}
    }
    # ----------------------------
    # get the links from the set of link clusters

    $self->getClusterLinks($Beam{0}{LinkCluster},$Links);     # get links
}

sub GetBestTrgLink{
    my $probs=shift;
    my @sort = sort {$$probs[$b] <=> $$probs[$a]} (0..$#{$probs});
    return shift @sort;
}

sub GetBestSrcLink{
    my $probs=shift;
    my $y=shift;
    my $highscore=0;
    my $best;
    foreach my $x (0..$#{$probs}){
	if ($$probs[$x][$y]>$highscore){
	    $highscore=$$probs[$x][$y];
	    $best=$x;
	}
    }
    return $best;
}


sub GetLowestTrgLink{
    my $probs=shift;
    my @sort = sort {$$probs[$a] <=> $$probs[$b]} (0..$#{$probs});
    while (@sort and (not $$probs[$sort[0]])){shift @sort;}
    return shift @sort;
}

sub GetLowestSrcLink{
    my $probs=shift;
    my $y=shift;
    my $highscore=1;
    my $lowest;
    foreach my $x (0..$#{$probs}){
	if ($$probs[$x][$y]<$highscore){
	    if (not $$probs[$x][$y]){last;}
	    $highscore=$$probs[$x][$y];
	    $lowest=$x;
	}
    }
    return $lowest;
}


sub AddScoreToBeam{
    my ($beam,$x,$y,$score,$size)=@_;

    my $LowestScore=$$beam{$size}{score};
    if (not defined $$beam{$size}{score}){
	$LowestScore=-9999999999999999999999999999;
    }

    foreach my $b (keys %{$beam}){
	if (not $score){last;}
	my $NewScore=$$beam{$b}{score}+log($score);
	if ($NewScore>$LowestScore){
	    &CloneBeam($$beam{$b},$$beam{$size+2});
	    $$beam{$size+2}{newscore}=$$beam{$size+2}{score}+log($score);
	    $$beam{$size+2}{newsrc}=$x;
	    $$beam{$size+2}{newtrg}=$y;

	    my $nr=$size;
	    while ($NewScore>$$beam{$nr}{newscore}){
		$$beam{$nr+1}=$$beam{$nr};
		if ($nr==0){last;}
		$nr--;
	    }
	    $$beam{$nr}=$$beam{$size+2};
	    delete $$beam{$size+2};
	    delete $$beam{$size+1};
	}
    }
}


sub CloneBeamOld{
    my ($old,$new)=@_;
    my $string=Dumper($old);
    $new=eval $string;
}






sub matrixSearch3{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @LinkMatrix;                           # copy matrix!
    foreach my $x (0..$#{$LinkProb}){
	foreach my $y (0..$#{$$LinkProb[$x]}){
	    if ($$LinkProb[$x][$y]){
		$LinkMatrix[$x][$y]=-log($$LinkProb[$x][$y]);
	    }
	}
    }

    my @LinkCluster;
    my ($x,$y);
    my %linksX=();
    my %linksY=();

    my ($align,$score)=$self->getBestAlignment(\@LinkMatrix,
					       \%linksX,\%linksY,$MinScore);
    $self->makeLinks($align,$Links);
}


#-----------------------------------------------------
# make links from align-strings from matrixSearch3

sub makeLinks{
    my $self=shift;
    my ($align,$WordLinks)=@_;

    my $TokenAttr=$self->{tokenAttr};
    my $LinkProb=$self->{matrix};

    my @links=split(/;/,$align);
    my %linksX=();
    my %linksY=();

    foreach my $l (@links){
	my ($src,$trg)=split(/\>/,$l);
	my @tok=split(/:/,$trg);
	foreach (@tok){
	    $linksX{$src}{$_}=1;
	    $linksY{$_}{$src}=1;
	}
    }
    my %cluster=();
    foreach my $x (keys %linksX){
	my ($y)=each %{$linksX{$x}};
	my $src=join ':',sort {$a <=> $b} keys %{$linksY{$y}};
	my $trg=join ':',sort {$a <=> $b} keys %{$linksX{$x}};
	%{$cluster{"$src;$trg"}{src}}=%{$linksY{$y}};
	%{$cluster{"$src;$trg"}{trg}}=%{$linksX{$x}};
    }
    foreach (keys %cluster){
	my ($src,$trg)=split(/;/,$_);
	my $score=$self->getMatrixScore($LinkProb,
					$cluster{$_}{src},
					$cluster{$_}{trg});
	my $link=$self->getLinkString($TokenAttr,$src,$trg);

	$$WordLinks{$src}{link}=$link;
	$$WordLinks{$src}{source}=
	    $self->ngramIDs($src,$TokenAttr,'source');
	$$WordLinks{$src}{target}=
	    $self->ngramIDs($trg,$TokenAttr,'target');
	my $span=$self->ngramSpans($src,$TokenAttr,'source');
	if ($span){$$WordLinks{$src}{src}=$span;}
	$span=$self->ngramSpans($trg,$TokenAttr,'target');
	if ($span){$$WordLinks{$src}{trg}=$span;}
	$$WordLinks{$src}{target}=
	    $self->ngramIDs($trg,$TokenAttr,'target');
	$$WordLinks{$src}{score}=$score;
    }
}

#-----------------------------------------------------
# get best alignment for matrixSearch3
#

sub getBestAlignment{
    my $self=shift;
    my ($matrix,$linksX,$linksY,$MinScore)=@_;


    my @scores=();
    my @aligns=();

    while (my ($x,$y)=$self->getTopLogLink($matrix)){
	my $LinkScore=$$matrix[$x][$y];
	if (exp($LinkScore)<$MinScore){last;}
	if (not defined $LinkScore){last;}

	$$matrix[$x][$y]=undef;

	if (defined $$linksX{$x}){
	    if (defined $$linksY{$y}){next;}           # overlaps in x AND y

#	    if ((defined $$linksX{$x}{$y+1}) and
#		(defined $$linksX{$x}{$y-1})){
#		next;
#		#-------------------------------------
#		# .... or put together 2 clusters?!
#	    }


	    if ((not defined $$linksX{$x}{$y+1}) and   # links not adjacent!!!
		(not defined $$linksX{$x}{$y-1})){
		my %old=%{$$linksX{$x}};
		$$linksX{$x}={};
		$$linksX{$x}{$y}=$LinkScore;
		my ($align,$score)=$self->getBestAlignment($matrix,$linksX,
							   $linksY,$MinScore);
		push (@scores,$score);
		push (@aligns,$align);
		%{$$linksX{$x}}=%old;
		next;
	    }
	    print STDERR "adjacent x: $x-$y\n";
	}
	elsif (defined $$linksY{$y}){


	    if (defined $$linksY{$y}{$x+1}){
		print STDERR join ":",keys %{$$linksX{$x+1}};
		print STDERR "\n";
		if (not defined $$linksX{$x+1}{$y}){next;}
	    }
	    if (defined $$linksY{$y}{$x-1}){
		print STDERR join ":",keys %{$$linksX{$x-1}};
		print STDERR "\n";
		if (not defined $$linksX{$x-1}{$y}){next;}
	    }

	    if ((defined $$linksY{$y}{$x+1}) and
		(defined $$linksY{$y}{$x-1})){

		next;
		#-------------------------------------
		# .... or put together 2 clusters?!
	    }

	    if ((not defined $$linksY{$y}{$x+1}) and   # links not adjacent!!!
		(not defined $$linksY{$y}{$x-1})){
		my %old=%{$$linksY{$y}};
		$$linksY{$y}={};
		$$linksY{$y}{$x}=$LinkScore;
		my ($align,$score)=$self->getBestAlignment($matrix,$linksX,
							   $linksY,$MinScore);
		push (@scores,$score);
		push (@aligns,$align);
		%{$$linksY{$y}}=%old;
		next;
	    }
	    print STDERR "adjacent y: $x-$y\n";
	}

	$$linksX{$x}{$y}=$LinkScore;
	$$linksY{$y}{$x}=$LinkScore;

    }

    my $score=0;
    my $align='';
    foreach my $x (keys %{$linksX}){
	$align.="$x>";
	foreach my $y (keys %{$$linksX{$x}}){
	    $score+=$$linksX{$x}{$y};
	    $align.="$y:";
	}
	chop $align;
	$align.=';';
    }
    chop $align;

    my $bestAlign=$align;
    my $bestScore=$score;

    foreach (0..$#scores){
	if ($scores[$_]<$bestScore){
	    $bestAlign=$aligns[$_];
	    $bestScore=$scores[$_];
	}
    }
    print STDERR "align: $bestAlign ($bestScore)\n";
    return ($bestAlign,$bestScore);
}







sub matrixSearch1{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    my @LinkMatrix;                           # copy matrix!
    foreach my $x (0..$#{$LinkProb}){
	foreach my $y (0..$#{$$LinkProb[$x]}){
	    $LinkMatrix[$x][$y]=$$LinkProb[$x][$y];
	}
    }

    my @LinkCluster;
    my ($x,$y);

    while (($x,$y)=$self->getTopLink(\@LinkMatrix)){
	if ($LinkMatrix[$x][$y]<$MinScore){last;}
	$self->add2LinkCluster($x,$y,\@LinkCluster);
	$LinkMatrix[$x][$y]=0;
    }

    foreach (0..$#LinkCluster){
	if (keys %{$LinkCluster[$_]{src}}){
	    if (keys %{$LinkCluster[$_]{trg}}){
		my $src=join ':',sort {$a<=>$b} keys %{$LinkCluster[$_]{src}};
		my $trg=join ':',sort {$a<=>$b} keys %{$LinkCluster[$_]{trg}};
		my $score=$self->getMatrixScore($LinkProb,
						$LinkCluster[$_]{src},
						$LinkCluster[$_]{trg});
		my $link=$self->getLinkString($TokenAttr,$src,$trg);

		$$Links{$src}{link}=$link;
		$$Links{$src}{source}=
		    $self->ngramIDs($src,$TokenAttr,'source');
		$$Links{$src}{target}=
		    $self->ngramIDs($trg,$TokenAttr,'target');
		my $span=$self->ngramSpans($src,$TokenAttr,'source');
		if ($span){$$Links{$src}{src}=$span;}
		$span=$self->ngramSpans($trg,$TokenAttr,'target');
		if ($span){$$Links{$src}{trg}=$span;}
		$$Links{$src}{target}=
		    $self->ngramIDs($trg,$TokenAttr,'target');
		$$Links{$src}{score}=$score;
	    }
	}
    }
}



sub matrixSearch2{
    my $self=shift;
    my $Links=shift;
    my $MinScore=shift;

    my $LinkProb=$self->{matrix};
    my $Token=$self->{token};
    my $TokenAttr=$self->{tokenAttr};

    my @SrcLinks;
    my @TrgLinks;
    my $NrSrc=$#{$$Token{source}};
    my $NrTrg=$#{$$Token{target}};

    for my $s (0..$NrSrc){
	my @sort=sort {$$LinkProb[$s][$b] <=> $$LinkProb[$s][$a]} (0..$NrTrg);
	if ($$LinkProb[$s][$sort[0]]){
	    $SrcLinks[$s]=$sort[0];
	}
    }
    for my $t (0..$NrTrg){
	my @sort=sort {$$LinkProb[$b][$t] <=> $$LinkProb[$a][$t]} (0..$NrSrc);
	if ($$LinkProb[$sort[0]][$t]){
	    $TrgLinks[$t]=$sort[0];
	}
    }

    foreach my $s (0..$#SrcLinks){

	my $added=1;
	my %S=($s => 1);
	my %T=();
	while ($added){
	    $added=0;
	    if (defined $SrcLinks[$s]){
		my $t=$SrcLinks[$s];
		$T{$t}=1;
		my @linked=grep($SrcLinks[$_] eq $t,(0..$#SrcLinks));
		foreach (@linked){
		    if (not defined $S{$_}){
			$S{$_}=1;
			$added=1;
		    }
		}
	    }
	}
	if (keys %T){
	    my $src= join ':', sort {$a <=> $b} keys %S;
	    my $trg= join ':', sort {$a <=> $b} keys %T;
	    my $score=$self->getMatrixScore($LinkProb,\%S,\%T);
	    if ($score<$MinScore){next;}
	    my $link=$self->getLinkString($TokenAttr,$src,$trg);

	    $$Links{$src}{link}=$link;
	    $$Links{$src}{source}=$self->ngramIDs($src,$TokenAttr,'source');
	    $$Links{$src}{target}=$self->ngramIDs($trg,$TokenAttr,'target');
	    $$Links{$src}{score}=$score;
	    my $span=$self->ngramSpans($src,$TokenAttr,'source');
	    if ($span){$$Links{$src}{src}=$span;}
	    $span=$self->ngramSpans($trg,$TokenAttr,'target');
	    if ($span){$$Links{$src}{trg}=$span;}
	}
    }
}








1;

