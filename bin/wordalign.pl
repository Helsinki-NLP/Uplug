#!/usr/bin/perl
# -*-perl-*-
#
# wordalign.pl:
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
#
# $Id$
#
# 
# information from the configfile will override other parameters
# (e.g. parameters [-in ...] and [-out ...] are discarded 
#       if input/output files are given in the configfile)
# default parameters are given in the &GetDefaultIni subfunction
#    at the end of the script!
#

use strict;

BEGIN{
    use FindBin qw($Bin);
    use lib "$Bin/..";
    if (not defined $ENV{UPLUGHOME}){
	$ENV{UPLUGHOME}=$Bin.'/..';
    }
}

# use Time::HiRes qw(time);

use Uplug::Data::Align;
use Uplug::IO::Any;
use Uplug::Config;

use Uplug::Align::Word;
use Uplug::Align::Word::Clue;
use Uplug::Align::Word::UWA;

use Cwd;

## global variable for socket handles
use vars qw/*SOCKET/;

## server mode: listen on port 1201 for requests
##              read wordalign arguments and run word alignment
##              write result and log info to socket
if (grep($_ eq '-server',@ARGV)){
    use IO::Socket;
    my $request_sock = new IO::Socket::INET (
					     LocalHost => 'localhost',
					     LocalPort => '1201',
					     Proto => 'tcp',
					     Listen => 1,
					     Reuse => 1,
					     );
    die "Could not create socket: $!\n" unless $request_sock;

    while (*SOCKET = $request_sock->accept()){
	my $request = <SOCKET>;
	*STDERR=*SOCKET;
	*STDOUT=*SOCKET;
#	print STDERR "req: $request";
	my @argv = split(/\s+/,$request);
	&wordalign(@argv);
#	print SOCKET "done!\n";
	close(*SOCKET);
    }
    close($request_sock);
}


## standard mode: just run the word alignment with given parameters
else{
    &wordalign(@ARGV);
}






sub wordalign{
    my @argv = @_;

#---------------------------------------------------------------------------

my $TmpCnt=0;

my %IniData=&GetDefaultIni;
my $IniFile='wordalign.ini';
&CheckParameter(\%IniData,\@argv,$IniFile);

my $PrintProgr=$IniData{'parameter'}{'runtime'}{'print progress'};
my $PrintHtml=$IniData{'parameter'}{'runtime'}{'print html'};
my $PrintHtmlOnly=$IniData{'parameter'}{'runtime'}{'print html only'};


    my $CurrentDir=getcwd();
    if (defined $IniData{parameter}{'runtime dir'}){
	chdir($IniData{parameter}{'runtime dir'});
    }

#---------------------------------------------------------------------------
# input and output data streams
#

my $CorpusStream=&GetCorpusStream(\%IniData);
my ($OutputStreamName,$OutputStream)=each %{$IniData{'output'}};
my $corpus=Uplug::IO::Any->new($CorpusStream);
$corpus->open('read',$CorpusStream) ||
    die "# wordalign.pl: failed to open the bitext!\n";
my $links={};
my $Param={};
&OpenLinkStreams(\%IniData,$links,$Param);

my $output=Uplug::IO::Any->new($OutputStream);
# my $header=$corpus->header;
# if (ref($header) ne 'HASH'){$header={};}
my $header={};
$header->{SkipDataHeader}=0;
$header->{SkipDataTail}=0;
$header->{SkipSrcFile}=1;
$header->{SkipTrgFile}=1;
$output->addheader($header);
if (not $PrintHtmlOnly){
    $output->open('write',$OutputStream);
}

#---------------------------------------------------------------------------
# some additional parameters
#

my $PWASTYLE=0;
if ($OutputStream->{style}=~/pwa/i){$PWASTYLE=1;}
my $PRINTMATRIX=$IniData{parameter}{runtime}{'print link matrix'};
my $DefaultWeight=$IniData{'parameter'}{'alignment'}{'default score weight'};
my $verboseAlign=$IniData{'parameter'}{'alignment'}{verbose};
my $alignIndex=$IniData{'parameter'}{'alignment'}{'index'};
my $nrAlign=$IniData{parameter}{runtime}{'number of segments'};
if (not defined $DefaultWeight){$DefaultWeight=0.5;}

#-----------------------------------------------------------------
# get general parameters for getting N-gram pairs from the bitext
# (take the settings of one of the input streams)

if ((defined $IniData{'parameter'}{'general input parameter'}) and
    (ref($IniData{'parameter'}{'general input parameter'}) eq 'HASH')){
    %{$Param->{general}}=%{$IniData{'parameter'}{'general input parameter'}};
}
elsif(defined $IniData{'parameter'}{'alignment'}{'general stream'}){
    my $st=$IniData{'parameter'}{'alignment'}{'general stream'};
    if (ref($Param->{$st}) eq 'HASH'){
	%{$Param->{general}}=%{$Param->{$st}};
    }
}
if (not defined $Param->{general}){
    my ($LinkStr)=each %{$links};
    if (ref($Param->{$LinkStr}) eq 'HASH'){
	%{$Param->{general}}=%{$Param->{$LinkStr}};
    }
}

#-----------------------------------------------------------------
# original N-grams: original wordforms from the text
#

$Param->{original}->{'language (source)'}=
    $Param->{general}->{'language (source)'};
$Param->{original}->{'language (target)'}=
    $Param->{general}->{'language (target)'};
$Param->{original}->{'token label'}=$Param->{general}->{'token label'};
$Param->{original}->{'delimiter'}=$Param->{general}->{'delimiter'};

#-----------------------------------------------------------------
# some more (clue) parameters from the config-file

my @ParSpec;
if (ref($IniData{parameter}{alignment}{clues}) eq 'ARRAY'){
    @ParSpec=@{$IniData{parameter}{alignment}{clues}};
}
elsif (ref($IniData{parameter}{alignment}{clues}) eq 'HASH'){
    @ParSpec=grep ($IniData{parameter}{alignment}{clues}{$_},
		   keys %{$IniData{parameter}{alignment}{clues}});
}
else{@ParSpec=keys %{$links};}
push (@ParSpec,'general','original','string pairs');
foreach my $l (@ParSpec){
    if (ref($IniData{parameter}{$l}) eq 'HASH'){
	foreach (keys %{$IniData{parameter}{$l}}){
	    $Param->{$l}->{$_}=$IniData{parameter}{$l}{$_};
	}
    }
}

#-----------------------------------------------------------------

my %lang;
$lang{source}=$Param->{general}->{'language (source)'};
$lang{target}=$Param->{general}->{'language (target)'};


my $MinScore=$IniData{'parameter'}{'alignment'}{'minimal score'};
$$Param{general}{'minimal score'}=$MinScore;
my $SearchMode=$IniData{'parameter'}{'alignment'}{'search'};
my $MaxNrNodes=$IniData{'parameter'}{'alignment'}{'node limit'};

#---------------------------------------------------------------------------
# variables for storing the processing time
#

my $StartTime=time;
my $FindBestTime=0;
my $GetLinksTime=0;
my $StoreLinksTime=0;
my $time;


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
# and here we go!
# ... the main part - alignment starts

if ($PrintProgr){
    print STDERR "read alignments\n";
}

my $count=0;
my $AlignCount=0;
my %CoocFreq;
my %SrcFreq;
my %TrgFreq;
my ($TotalCooc,$TotalSrc,$TotalTrg);
my $NrLinks=0;
my $NrToken=0;
my @idx=();

#------------------------------------------------------------------------
my $align;
if ($SearchMode=~/best\-?first/){
    $align=Uplug::Align::Word->new($corpus,%{$IniData{parameter}{alignment}});
}
#elsif ($SearchMode=~/tree/){
#    $align=uplugTreeAlign->new($corpus,%{$IniData{parameter}{alignment}});
#}
elsif ($SearchMode=~/uwa/){
    $align=Uplug::Align::Word::UWA->new($corpus,%{$IniData{parameter}{alignment}});
}
else{
    $align=Uplug::Align::Word::Clue->new($corpus,%{$IniData{parameter}{alignment}});
}
$align->setLinkParams($Param);
$align->setLanguages($lang{source},$lang{target});
$align->setLinkStreams($links);
#------------------------------------------------------------------------

my $time=time();
while ($align->read($alignIndex)){

    $count++;
    $AlignCount++;
    my $id=$align->dataId();
#    if ($alignIndex){
#	if ($alignIndex ne $id){next;}
#    }

    #------------------------------------------------
    # print some information to show progress

    if ($PrintProgr){
	if ($SearchMode ne 'tree'){
	    if (not ($AlignCount % 10)){
#		if (Uplug::Align::Word::Clue::DEBUG){
#		my $used=time-$StartTime;
#		print STDERR "\n* prepare   : ",$align->{prepare_time},"\n";
#		print STDERR "* get scores: ",$align->{get_scores_time},"\n";
#		print STDERR "   identical: ",$align->{identical_score_time},"\n";
#		print STDERR "          1x: ",$align->{'1x_score_time'},"\n";
#		print STDERR "      before: ",$align->{before_score_time},"\n";
#		print STDERR "      search: ",$align->{search_score_time},"\n";
#		print STDERR "       after: ",$align->{after_score_time},"\n";
#		print STDERR "* align     : ",$align->{align_time},"\n";
#		print STDERR "= used      : ",$used,"\n";
#               }
		$|=1;print STDERR '.';$|=0;
	    }
	}
	if (not ($AlignCount % 100)){
	    $|=1;
	    print STDERR time()-$time;
	    print STDERR " sec: $AlignCount bitext segments\n";
	    $|=0;
	}
	if ($nrAlign and ($AlignCount>$nrAlign)){last;}
    }

    my $LinkPt=$align->align();

    my %Links=();
    if (ref($LinkPt) eq 'HASH'){
	%Links=%{$LinkPt};
    }

    #-------------------------------------------------------------------------
    if ($PrintHtml and ($PrintHtml>$#idx)){
	my $file=$id.'.html';
	push (@idx,$id);
	&PrintHtmlClue(\@idx,$#idx,$align,$PrintHtml);
    }
    if ($PrintHtmlOnly){                   # just print html-output
	&PrintHtml(\@idx,$#idx,$align);    # for one alignment segment!!
	last;
    }
    #-------------------------------------------------------------------------

    my $data=$align->data();

    if ($verboseAlign){
	print STDERR "\n===================================================\n";
	print STDERR "word alignments";
	print STDERR "\n===================================================\n";
    }

    foreach my $s (keys %Links){

#	if ($Links{$s}{score}<$MinScore){next;}
	$NrLinks+=split(/\:/,$Links{$s}{source});

	if ($verboseAlign){
	    $align->printBitextLink($id,$Links{$s});
	}
	if ($PWASTYLE){
	    my $data=Uplug::Data::Align->new;
	    my ($src,$trg)=split(/;/,$Links{$s}{link});
	    $data->setAttribute('source_id',$Links{$s}{source});
	    $data->setAttribute('target_id',$Links{$s}{target});
	    $data->setAttribute('id',$id);
	    $data->setAttribute('source',$src);
	    $data->setAttribute('target',$trg);
	    $data->setAttribute('score',$Links{$s}{score});
	    $data->setAttribute('align step',1);
	    if ($Links{$s}{src}){
		$data->setAttribute('source_span',$Links{$s}{src});
	    }
	    if ($Links{$s}{trg}){
		$data->setAttribute('target_span',$Links{$s}{trg});
	    }
	    $output->write($data);
	}
#	elsif ($OutputStream->{style}=~/liu/){
	elsif (($OutputStream->{format}=~/(align|koma|xces|xml)/i) or
	       ($OutputStream->{style}=~/(liu|koma|xces|xml)/i)){
	    $data->addWordLink($Links{$s});
	}
	else{
	    my $data=Uplug::Data::Align->new;
	    $data->setAttribute('source',$Links{$s}{source});
	    $data->setAttribute('target',$Links{$s}{target});
	    $data->setAttribute('id',$id);
	    $data->setAttribute('link',$Links{$s}{link});
	    $data->setAttribute('score',$Links{$s}{score});
	    $output->write($data);
	}

    }
    if (($OutputStream->{format}=~/(koma|align|xces|xml)/i) or
	   ($OutputStream->{style}=~/(liu|koma|xces|xml)/i)){
	my $OutData=$data->{link};
	$output->write($OutData);
    }
#    my $used=time-$time;
    if ($alignIndex){last;}          # align only one sentence alignment!
}

#--------------------------------------------------------------------------
# ready!!!
# close all streams and print some information
#

$corpus->close;
if (not $PrintHtmlOnly){$output->close;}
foreach (keys %{$links}){
    $links->{$_}->close;
}

my $TotalTime=time-$StartTime;
print STDERR "overall time for this module         : $TotalTime\n";
print STDERR "linked source tokens: $NrLinks/$NrToken = ";
# print STDERR int(10000*$NrLinks/$NrToken)/100;
print STDERR "\% \n";


    chdir($CurrentDir);

}

#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

sub PrintHtmlClue{
    my ($idx,$id,$align,$max)=@_;
    my $dir='clue-html-files';
    if (not -d $dir){
	mkdir $dir,0755;
    }
    my $file="$dir/$id.html";
    open F,">$file";

    &PrintHtmlHeader(*F);
    &PrintPrevNextLinks(*F,$idx,$id,$max);
    print F $align->clueMatrixToHtml();
    print F $align->linksToHtml();
    print F "<hr>\n";
    my $data=$align->data();
    print F $data->toHTML();
    &PrintHtmlFooter(*F);
    close F;
    return;
}

sub PrintHtml{
    my ($idx,$id,$align)=@_;
#    &PrintHtmlHeader(*STDOUT);
    my $data=$align->data();
    print $align->clueMatrixToHtml();
    print $align->linksToHtml();
    print "<hr>\n";
    print $data->toHTML();
#    &PrintHtmlFooter(*STDOUT);
    return;
}

sub PrintHtmlHeader{
    my $f=shift;
    print $f '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/transitional.dtd">';
    print $f "\n<html>\n<head>\n";
    print $f '<meta http-equiv="content-type" content="text/html; charset=UTF-8">';
    print $f "\n<title>clue alignment result</title>\n";
    print $f "\n<style>\n";
    print $f "<!--th { font-size:x-small; }-->\n";
    print $f "<!--td { font-size:x-small;text-align:center }-->\n";
    print $f "</style>\n</head><body>\n";
}

sub PrintHtmlFooter{
    my $f=shift;
    print $f "</body></html>";
}

sub PrintPrevNextLinks{
    my ($f,$idx,$id,$max)=@_;
    my $dir='clue-html-files';
    print $f "<table width=\"60%\"><tr><td>";
    my $prev;if ($id>0){$prev=$id-1;}
    my $next=$id+1;
    if (defined $prev){
	print $f "<a href=\"$prev.html\">\&lt;\&lt;</a>";
    }
    print $f "</td><td>$$idx[$id]</td>";
    if ($id<$max){
	print $f "<td><a href=\"$next.html\">\&gt;\&gt;</a></td>";
    }
    print $f "</tr></table><hr>";
}



sub GetCorpusStream{
    my $IniData=shift;
    foreach (keys %{$$IniData{input}}){
	if (/text/){return $$IniData{input}{$_};}
    }
}

sub OpenLinkStreams{
    my ($IniData,$links,$Param)=@_;

    my %LinkStream;
    foreach (keys %{$$IniData{input}}){
#	if (/text/){$CorpusStream=$$IniData{input}{$_};}
#	else{$LinkStream{$_}=$$IniData{input}{$_};}
	if ($_!~/text/){$LinkStream{$_}=$$IniData{input}{$_};}
    }

    #-----------------
    # check if there's a defined list of clues
    # (open only defined clues)x

    my @clues=keys %LinkStream;
    if (ref($$IniData{parameter}{alignment}{clues}) eq 'ARRAY'){
	@clues=@{$$IniData{parameter}{alignment}{clues}};
    }
    elsif (ref($$IniData{parameter}{alignment}{clues}) eq 'HASH'){
	@clues=grep ($$IniData{parameter}{alignment}{clues}{$_},
		     keys %{$$IniData{parameter}{alignment}{clues}});
    }

    foreach my $l (keys %LinkStream){
	if (not grep($_ eq $l,@clues)){next;}
	if (not defined $LinkStream{$l}{format}){
	    if (not defined $LinkStream{$l}{'stream name'}){
		delete $LinkStream{$l};
		next;
	    }
	}
	$links->{$l}=Uplug::IO::Any->new($LinkStream{$l});
	if (not ref($links->{$l})){
	    warn " something wrong with $l!\n";
	    delete $LinkStream{$l};
	    delete $links->{$l};
	    next;
	}
	if (not $links->{$l}->open('read',$LinkStream{$l})){
	    delete $LinkStream{$l};
	    delete $links->{$l};
	    next;
	}
	$Param->{$l}=$links->{$l}->header;
    }
}


sub GetDefaultIni{

    my $DefaultIni = 
{
  'module' => {
    'program' => 'wordalign.pl',
    'location' => '$UplugBin',
    'name' => 'The clue aligner - linking words',
    'stdin' => 'bitext',
    'stdout' => 'bitext',
  },
  'description' => 'This module links words and phrases using the
  clues that are available and which have been enabled for the
  alignment. Note: If you enable additional clues make sure that they
  exist, i.e. that they have been produced before. Non-existing clues
  are simply ignored.<p>
  The search parameter sets the link strategy:
  The default search
  strategy is a constrained best-first search (=best first). Other
  available strategies are 
  <ul><li>a refined bi-directional alignment
  (=refined)
  <li>the intersection of directional alignments (source to
  target and target to source) (=intersection)
  <li>the union of
  directional alignments (=union)
  <li>a competitive linking approach (=competitive)
  <li>and two directional alignment strategies
  (directional_src and directional_trg).</ul>',
  'input' => {
    'bitext' => {
      'format' => 'xces align',
    },
    'string similarities' => {
      'stream name' => 'string similarities',
    },
    'dice' => {
       'stream name' => 'dice',
    },
    'mutual information' => {
       'stream name' => 'mutual information',
    },
    't-score' => {
       'stream name' => 't-score',
    },
    'pos dice' => {
       'stream name' => 'pos dice', 
    },
    'giza dictionary' => {
       'stream name' => 'giza dictionary', 
    },
    'giza inverse' => {
       'stream name' => 'giza inverse', 
    },
    'dynamic POS clue' => {
      'stream name' => 'POS clue',
    },
    'dynamic POS clue (coarse)' => {
      'stream name' => 'POS clue (coarse)',
    },
    'dynamic chunk clue' => {
      'stream name' => 'chunk clue',
    },
    'dynamic position clue' => {
      'stream name' => 'position clue',
    },
    'dynamic lex clue' => {
      'stream name' => 'lex clue',
    },
    'dynamic lex/POS clue' => {
      'stream name' => 'lexpos clue',
    },
    'dynamic left POS-bigram clue' => {
      'stream name' => 'posleft clue',
    },
    'dynamic right POS-bigram clue' => {
      'stream name' => 'posright clue',
    },
    'dynamic POS-trigram clue' => {
      'stream name' => 'postrigram clue',
    },
    'dynamic chunk/POS clue' => {
      'stream name' => 'chunkpos clue',
    },
    'dynamic chunk/POS-trigram clue' => {
      'stream name' => 'chunkpostrigram clue',
    },
    'posposi clue' => {
      'stream name' => 'posposi clue',
    },
    'pos2posi clue' => {
      'stream name' => 'pos2posi clue',
    },
    'postri clue' => {
      'stream name' => 'postri clue',
    },
    'postriposi clue' => {
      'stream name' => 'postriposi clue',
    },
    'postri2posi clue' => {
      'stream name' => 'postri2posi clue',
    },
    'postri2 clue' => {
      'stream name' => 'postri2 clue',
    },
    'chunktripos clue' => {
      'stream name' => 'chunktripos clue',
    },
    'chunktriposi clue' => {
      'stream name' => 'chunktriposi clue',
    },
    'chunktri clue' => {
      'stream name' => 'chunktri clue',
    },
  },
  'output' => {
    'bitext' => {
      'format' => 'xces align',
      'status' => 'word',
    },
  },
  'parameter' => {
    'string similarities' => {
      'minimal score' => 0.3,
      'score weight' => 0.05,
    },
    'dice' => {
      'minimal score' => 0.2,
      'score weight' => 0.05,
    },
    'mutual information' => {
      'minimal score' => 2,
      'score weight' => 0.005,
    },
    't-score' => {
      'minimal score' => 0.8,
      'score weight' => 0.01,
    },
    'length clue' => {
      'score weight' => 0.0001,
      'string length difference' => 1,
    },
    'pos dice' => {
      'minimal score' => 0.2,
      'score weight' => 0.01,  
    },
    'giza dictionary' => {
      'score weight' => '0.1',
    },
    'giza inverse' => {
      'score weight' => '0.1',
    },
    'dynamic POS clue' => {
#      'minimal score' => 0.2,
      'score weight' => 0.05,
    },
    'dynamic POS clue (coarse)' => {
#      'minimal score' => 0.2,
      'score weight' => 0.05,
    },
    'dynamic position clue' => {
#      'minimal score' => 0.2,
      'score weight' => 0.01,
    },
    'dynamic chunk clue' => {
#      'minimal score' => 0.2,
      'score weight' => 0.01,
    },
    'general' => {
        'chunks (source)' => 'c.*',
        'chunks (target)' => 'c.*',
    },
    'alignment' => {
      'remove word links' => 0,
      'clues' => {
        'string similarities' => 1,
        'dice' => 1,
        'mutual information' => 0,
        't-score' => 0,
        'giza dictionary' => 1,
        'giza inverse' => 1,
        'dynamic POS clue' => 0,
        'dynamic POS clue (coarse)' => 0,
        'dynamic chunk clue' => 0,
        'dynamic position clue' => 0,
	'chunktriposi clue' => 1,
	'postriposi clue' => 1,
      },
      'minimal score' => '0.00001',
      'search' => 'matrix',
       'verbose' => 0,                # don't print clue matrices!
#      'minimal score' => '70%',
#      'general stream' => 'dice',
#      'align 1:1' => '0.5',
#      'remove linked' => 1,
#      'align identical' => '0.08',
    },
    'runtime' => {
      'print progress' => 1,
      'print link matrix' => 1,
    },
  },
  'arguments' => {
    'shortcuts' => {
      'sim' => 'parameter:alignment:clues:string similarities',
      'dice' => 'parameter:alignment:clues:dice',
      'mi' => 'parameter:alignment:clues:mutual information',
      'tscore' => 'parameter:alignment:clues:t-score',
      'giza' => 'parameter:alignment:clues:giza dictionary',
      'giza2' => 'parameter:alignment:clues:giza inverse',
      'dynpos' => 'parameter:alignment:clues:dynamic POS clue',
      'dynpos2' => 'parameter:alignment:clues:dynamic POS clue (coarse)',
      'dynchunk' => 'parameter:alignment:clues:dynamic chunk clue',
      'dynposi' => 'parameter:alignment:clues:dynamic position clue',
      'dynlex' => 'parameter:alignment:clues:dynamic lex clue',
      'dynlexpos' => 'parameter:alignment:clues:dynamic lex/POS clue',
      'dynposbigramleft' => 'parameter:alignment:clues:dynamic left POS-bigram clue',
      'dynposbigramright' => 'parameter:alignment:clues:dynamic right POS-bigram clue',
      'dynpostrigram' => 'parameter:alignment:clues:dynamic POS-trigram clue',
      'dynchunkpos' => 'parameter:alignment:clues:dynamic chunk/POS clue',
      'dynchunkpostrigram' => 'parameter:alignment:clues:dynamic chunk/POS-trigram clue',

      'posposi' => 'parameter:alignment:clues:posposi clue',   
      'pos2posi' => 'parameter:alignment:clues:pos2posi clue',   
      'postri' => 'parameter:alignment:clues:postri clue',   
      'postri2' => 'parameter:alignment:clues:postri2 clue',   
      'postriposi' => 'parameter:alignment:clues:postriposi clue',
      'postri2posi' => 'parameter:alignment:clues:postri2posi clue',
      'chunktri' => 'parameter:alignment:clues:chunktri clue',
      'chunktripos' => 'parameter:alignment:clues:chunktripos clue',
      'chunktriposi' => 'parameter:alignment:clues:chunktriposi clue',


      'simw' => 'parameter:string similarities:score weight',
      'dicew' => 'parameter:dice:score weight',
      'miw' => 'parameter:mutual information:score weight',
      'tscorew' => 'parameter:t-score:score weight',
      'gizaw' => 'parameter:giza dictionary:score weight',
      'dynposw' => 'parameter:dynamic POS clue:score weight',
      'dynpos2w' => 'parameter:dynamic POS clue (coarse):score weight',
      'dynchunkw' => 'parameter:dynamic chunk clue:score weight',
      'dynposiw' => 'parameter:dynamic position clue:score weight',
      'statposw' => 'parameter:static POS clue:score weight',
      'statpos2w' => 'parameter:static POS clue 2:score weight',
      'statchunkw' => 'parameter:static chunk clue:score weight',

      'dynlexw' => 'parameter:dynamic lex clue:score weight',
      'dynlexposw' => 'parameter:dynamic lex/POS clue:score weight',
      'dynposbigramleftw' => 'parameter:dynamic left POS-bigram clue:score weight',
      'dynposbigramrightw' => 'parameter:dynamic right POS-bigram clue:score weight',
      'dynpostrigramw' => 'parameter:dynamic POS-trigram clue:score weight',
      'dynchunkposw' => 'parameter:dynamic chunk/POS clue:score weight',
      'dynchunkpostrigramw' => 'parameter:dynamic chunk/POS-trigram clue:score weight',


      'new' => 'parameter:alignment:non-aligned only',
       'in' => 'input:bitext:file',
       'infile' => 'input:bitext:file',
       'informat' => 'input:bitext:format',
       'out' => 'output:bitext:file',
       'srclang' => 'parameter:general:language (source)',
       'trglang' => 'parameter:general:language (target)',
        'id' => 'parameter:alignment:index',
        'html' => 'parameter:runtime:print html only',
        'search' => 'parameter:alignment:search',
        'v' => 'parameter:alignment:verbose',
	'adj' => 'parameter:alignment:adjacent_only',
        'phr' => 'parameter:alignment:in_phrases_only',
	'min' => 'parameter:alignment:minimal score',
    }
  },
  'widgets' => {
      'parameter' => {
	  'alignment' => {
	     'clues' => {
		 'string similarities' => 'checkbox',
		 'dice' => 'checkbox',
		 'giza dictionary' => 'checkbox',
		 'dynamic POS clue' => 'checkbox',
		 'dynamic POS clue (coarse)' => 'checkbox',
		 'dynamic chunk clue' => 'checkbox',
		 'dynamic position clue' => 'checkbox',
		 'dynamic lex clue' => 'checkbox',
		 'dynamic lex/POS clue' => 'checkbox',
		 'posposi clue' => 'checkbox',
		 'postri clue' => 'checkbox',
		 'postriposi clue' => 'checkbox',
		 'chunktri clue' => 'checkbox',
		 'chunktripos clue' => 'checkbox',
		 'chunktriposi clue' => 'checkbox',
	     },
	     'minimal score' => 'scale (0,1,0.00001,0.005)',
	     'search' => 'optionmenu (best first,refined,intersection,union,competitive,directional_src,directedional_trg)',
	 }
      }
  }
};

    return %{$DefaultIni};
}



