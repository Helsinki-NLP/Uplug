#!/usr/bin/perl
#---------------------------------------------------------------------------
# bitext2cwb.pl
#
# create CWB inoutfor Uplug bitexts
#
# usage: bitext-indexer.pl corpus src trg bitexts
#
#   corpus .... short name of the corpus (no spaces!)
#   src ....... source language ID (e.g. sv, en, de)
#   trg ....... target language ID (e.g. sv, en, de)
#   bitexts ... XCES align files (one or more)
#
# CWB files will be stored in cwb-files/
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

use strict;

use FindBin qw($Bin);
use File::Copy;
use File::Basename;
use XML::Parser;

#use lib ('/home/staff/joerg/user_local/lib/perl5/site_perl/5.8.0/');
#use WebCqp::Query;

#my $CWBBIN='/usr/local/bin';
#my $ENCODE="$CWBBIN/cwb-encode";
#my $CWBMAKEALL="${CWBBIN}/cwb-makeall";
#my $CWBALIGNENCODE="${CWBBIN}/cwb-align-encode";

my $ENCODE='cwb-encode';
my $CWBMAKEALL='cwb-makeall';
my $CWBALIGNENCODE='cwb-align-encode';

my $CORPUS    = shift(@ARGV);  # corpus name
my $SRCLANG   = shift(@ARGV);  # source language
my $TRGLANG   = shift(@ARGV);  # target language


my @BITEXTS   = @ARGV;         # one or more bitext-files (XCES align)


my $DIR    = $ENV{PWD};
my $TMPDIR = 'cwb-files';
if (! -e $TMPDIR){mkdir $TMPDIR,0755;}
chdir $TMPDIR;


my @srcfiles;
my @trgfiles;
&GetXMLFiles(\@BITEXTS,\@srcfiles,\@trgfiles);   # get all source/target files

my $allattr=1;
my $spattern=undef;
my $ppattern=undef;

print "convert XML files to CWB input ....\n";

my $attr=&XML2CWBinput($SRCLANG,\@srcfiles,$allattr,$spattern,$ppattern);
print ("encode with: $ENCODE -R regdir/$SRCLANG -d datdir/$SRCLANG -f $TMPDIR/$SRCLANG $attr\n");
my $attr=&XML2CWBinput($TRGLANG,\@trgfiles,$allattr,$spattern,$ppattern);
print ("encode with: $ENCODE -R regdir/$TRGLANG -d datdir/$TRGLANG -f $TMPDIR/$TRGLANG $attr\n");

print "convert sentence alignment to CWB input ....\n";

&Align2CWBinput($SRCLANG,$TRGLANG,\@BITEXTS);

print "encode with: $CWBALIGNENCODE -r regdir -D $TMPDIR/$SRCLANG$TRGLANG.alg\n";
print "encode with: $CWBALIGNENCODE -r regdir -D $TMPDIR/$TRGLANG$SRCLANG.alg\n";


chdir $DIR;




#----------------------------------------------------------------------
#----------------------------------------------------------------------
# read through bitext files and return source/target files
#----------------------------------------------------------------------
#----------------------------------------------------------------------

sub GetXMLFiles{
    my ($bitexts,$src,$trg)=@_;
    my $count=0;

    foreach my $f (@{$bitexts}){

	if (not -e $f){$f="$DIR/$f";}
	if (not -e $f){next;}

	my $bitextname=&basename($f);
	my $bitextdir=&dirname($f);

	if ($f=~/\.gz$/){open F,"gzip -cd <$f |";}
	else{open F,"<$f";}

	local $/='>';              # read blocks end at '>'

	while(<F>){
	    if (/fromDoc\s*=\s*\"([^\"]+)\"/){
		my $srcdoc=$1;
		$srcdoc=~s/\/\.\//\//g;
		if (not -e $srcdoc){$srcdoc="$bitextdir/$srcdoc";}
		if (/toDoc\s*=\s*\"([^\"]+)\"/){
		    my $trgdoc=$1;
		    $trgdoc=~s/\/\.\//\//g;
		    if (not -e $trgdoc){$trgdoc="$bitextdir/$trgdoc";}
		    if (($srcdoc ne $$src[-1]) or ($trgdoc ne $$trg[-1])){
			push (@{$src},$srcdoc);
			push (@{$trg},$trgdoc);
			$count++;
		    }
		}
	    }
	}
    }
    return $count;
}







#----------------------------------------------------------------------
#----------------------------------------------------------------------
# convert XCES align to CWB input format
#----------------------------------------------------------------------

sub Align2CWBinput{
    my ($srclang,$trglang,$bitexts)=@_;

    my $srcPosFile="$srclang.pos";
    my $trgPosFile="$trglang.pos";

    die "cannot find source position file $srcPosFile" unless -e $srcPosFile;
    die "cannot find target position file $trgPosFile" unless -e $trgPosFile;

    open ALG1,">$srclang$trglang.alg";
    open ALG2,">$trglang$srclang.alg";

    print ALG1 "$srclang\ts\t$trglang\ts\n";
    print ALG2 "$trglang\ts\t$srclang\ts\n";

    my %srcPos=();
    my %trgPos=();

    open F,"<$srcPosFile";
    my $file;
    while(<F>){
	chomp;
	if (/^\#\s+(\S+)\s*$/){
	    $file=$1;
	    next;
	}
	my ($id,$start,$end)=split(/\t/,$_);
	$srcPos{$file}{$id}{start}=$start;
	$srcPos{$file}{$id}{end}=$end;
    }

    open F,"<$trgPosFile";
    while(<F>){
	chomp;
	if (/^\#\s+(\S+)\s*$/){
	    $file=$1;
	    next;
	}
	my ($id,$start,$end)=split(/\t/,$_);
	$trgPos{$file}{$id}{start}=$start;
	$trgPos{$file}{$id}{end}=$end;
    }

    my $lastsrc=-1;
    my $lasttrg=-1;


    foreach my $f (@{$bitexts}){

	if (not -e $f){$f="$DIR/$f";}
	if (not -e $f){next;}

	my $bitextname=&basename($f);
	my $bitextdir=&dirname($f);

	if ($f=~/\.gz$/){open F,"gzip -cd <$f |";}
	else{open F,"<$f";}

	local $/='>';              # read blocks end at '>'
	my ($srcdoc,$trgdoc);

	while(<F>){
	    if (/fromDoc\s*=\s*\"([^\"]+)\"/){
		$srcdoc=$1;
		$srcdoc=~s/\/\.\//\//g;
		if (not -e $srcdoc){$srcdoc="$bitextdir/$srcdoc";}
		if (/toDoc\s*=\s*\"([^\"]+)\"/){
		    $trgdoc=$1;
		    $trgdoc=~s/\/\.\//\//g;
		    if (not -e $trgdoc){$trgdoc="$bitextdir/$trgdoc";}
		}
	    }
	    if (/(sentLink|link)\s.*xtargets=\"([^\"]+)\s*\;\s*([^\"]+)\"/){
		my $src=$2;
		my $trg=$3;
		my @srcsent=split(/\s/,$src);
		my @trgsent=split(/\s/,$trg);

		if (not (@srcsent and @trgsent)){next;}
		if (not defined $srcPos{$srcdoc}){
		    if (defined $srcPos{$srcdoc.'.gz'}){$srcdoc.='.gz';}
		    if (not defined $srcPos{$srcdoc}){next;}
		}
		if (not defined $srcPos{$srcdoc}{$srcsent[0]}){next;}
		if (not defined $srcPos{$srcdoc}{$srcsent[-1]}){next;}
		if (not defined $trgPos{$trgdoc}){
		    if (defined $trgPos{$trgdoc.'.gz'}){$trgdoc.='.gz';}
		    if (not defined $trgPos{$trgdoc}){next;}
		}
		if (not defined $trgPos{$trgdoc}{$trgsent[0]}){next;}
		if (not defined $trgPos{$trgdoc}{$trgsent[-1]}){next;}

	#------------------------------------------
	# print alignment file (src --> trg)

		if ($lastsrc<$srcPos{$srcdoc}{$srcsent[0]}{start}){
		    print ALG1 $srcPos{$srcdoc}{$srcsent[0]}{start},"\t";
		    print ALG1 $srcPos{$srcdoc}{$srcsent[-1]}{end},"\t";
		    print ALG1 $trgPos{$trgdoc}{$trgsent[0]}{start},"\t";
		    print ALG1 $trgPos{$trgdoc}{$trgsent[-1]}{end},"\t";
		    print ALG1 scalar @srcsent;
		    print ALG1 ':';
		    print ALG1 scalar @trgsent;
		    print ALG1 "\n";
		    $lastsrc=$srcPos{$srcdoc}{$srcsent[-1]}{end};
		}

	#------------------------------------------
	# print alignment file (trg --> src)

		if ($lasttrg<$trgPos{$trgdoc}{$trgsent[0]}{start}){
		    print ALG2 $trgPos{$trgdoc}{$trgsent[0]}{start},"\t";
		    print ALG2 $trgPos{$trgdoc}{$trgsent[-1]}{end},"\t";
		    print ALG2 $srcPos{$srcdoc}{$srcsent[0]}{start},"\t";
		    print ALG2 $srcPos{$srcdoc}{$srcsent[-1]}{end},"\t";
		    print ALG2 scalar @trgsent;
		    print ALG2 ':';
		    print ALG2 scalar @srcsent;
		    print ALG2 "\n";
		    $lasttrg=$trgPos{$trgdoc}{$trgsent[-1]}{end};
		}
	    }
	}
	close F;
    }

    close ALG1;
    close ALG2;
}


#----------------------------------------------------------------------
#----------------------------------------------------------------------
# XML2CWBinput
#
# convert XML files to CWB input files!
#----------------------------------------------------------------------

my @PATTR=();
my %SATTR=();
my %nrSATTR=();

my @AllPATTR=();
my %AllSATTR=();

my $pos=0;
my $SentTag='s';
my $WordTag='w';

my $SentStart=0;
my $SentDone=0;
my $WordStart=0;
my $WordDone=0;
my $XmlStr;
my %WordAttr=();
my ($AllAttributes,$StrucAttrPattern,$WordAttrPattern);


sub XML2CWBinput{
    my ($language,$files);
    ($language,$files,$AllAttributes,$StrucAttrPattern,$WordAttrPattern)=@_;

    my %LangCodes=(
	       'ar' => 'utf-8',
	       'az' => 'utf-8',
	       'be' => 'utf-8',
	       'bg' => 'utf-8',
	       'bs' => 'utf-8',
	       'cs' => 'iso-8859-2',
	       'el' => 'iso-8859-7',
#	       'el' => 'utf-8',
	       'eo' => 'iso-8859-3',
	       'et' => 'iso-8859-4',
	       'he' => 'utf-8',
	       'hr' => 'iso-8859-2',
	       'hu' => 'iso-8859-2',
	       'id' => 'utf-8',
	       'ja' => 'utf-8',
	       'jp' => 'utf-8',
	       'ko' => 'utf-8',
	       'ku' => 'utf-8',
	       'lt' => 'iso-8859-4',
	       'lv' => 'iso-8859-4',
	       'mi' => 'utf-8',
	       'mk' => 'utf-8',
	       'pl' => 'iso-8859-2',
	       'ro' => 'iso-8859-2',
	       'ru' => 'utf-8',
	       'sk' => 'iso-8859-2',
	       'sl' => 'iso-8859-2',
	       'sr' => 'iso-8859-2',
	       'ta' => 'utf-8',
	       'th' => 'utf-8',
	       'tr' => 'iso-8859-9',
	       'uk' => 'utf-8',
	       'vi' => 'utf-8',
	       'xh' => 'utf-8',
	       'zh_tw' => 'utf-8',
	       'zu' => 'utf-8'
		   );

    @PATTR=();
    %SATTR=();
    %nrSATTR=();

    @AllPATTR=();
    %AllSATTR=();

    $pos=0;
    $SentTag='s';
    $WordTag='w';

    $SentStart=0;
    $SentDone=0;
    $WordStart=0;
    $WordDone=0;
    $XmlStr;
    %WordAttr=();

    my $OutFile=$language;
    my $PosFile=$language.'.pos';
    open POS,">$PosFile";
    open OUT,">$OutFile";

    while (@{$files}){
	my $file=shift(@{$files});
	if (-d $file){
	    if (opendir(DIR, $file)){
		my @subdir = grep { /^[^\.]/ } readdir(DIR);
		map ($subdir[$_]="$file/$subdir[$_]",(0..$#subdir));
		push (@{$files},@subdir);
		closedir DIR;
	    }
	}
	elsif (-f $file){
	    &ConvertXML($file);
	}
    }
    close POS;

    return &AttrString();
}

#----------------------------------------------------------------------
# end of XML2CWBinput
#----------------------------------------------------------------------


sub ConvertXML{
    my $file=shift;
    my $zipped=0;
    print POS "# $file\n";
    if ((not -e $file) and (-e "$file.gz")){
	$file="$file.gz";
    }
    if (not -e $file){return;}
    if ($file=~/\.gz$/){
	$zipped=1;
	#--------------------
	# dirty hack to get one of the german OO-files to work:
	# /replace &nbsp; with ' ' to make the xml-parser happy
	#--------------------
	system ("gzip -cd $file | sed 's/\&nbsp/ /g;'> /tmp/xmltocwb$$");
	$file="/tmp/xmltocwb$$";
    }

    if ($AllAttributes){
	my $parser1=
	    new XML::Parser(Handlers => {Start => \&XmlAttrStart});
	
	eval { $parser1->parsefile($file); };
	if ($@){warn "$@";}
	@PATTR=sort keys %WordAttr;
    }

    my $parser2=
	new XML::Parser(Handlers => {Start => \&XmlStart,
				     End => \&XmlEnd,
				     Default => \&XmlChar,
				 },);

    eval { $parser2->parsefile($file); };
    if ($@){warn "$@";}
    if ($zipped){
	unlink "/tmp/xmltocwb$$";
    }
    foreach my $s (keys %SATTR){              # save structural attributes
	%{$AllSATTR{$s}}=%{$SATTR{$s}};       # in global attribute hash
    }
    if (@PATTR>@AllPATTR){                    # save positional attributes
	@AllPATTR=@PATTR;                     # in global attribute array
    }
}


#-------------------------------------------------------------------
# print cwb-encode arguments for structural & positional attributes

sub AttrString{
    my $attr="-xsB";
    foreach my $s (keys %AllSATTR){
	$attr.=" -S $s:0";
	my $a=join "+",keys %{$AllSATTR{$s}};
	if ($a){$attr.='+'.$a;}
    }
    foreach (@AllPATTR){
	$attr.=" -P $_";
    }
    return $attr;
}




#-------------------------------------------------------------------
# XML parser handles (parser 2)


sub XmlStart{
    my $p=shift;
    my $e=shift;
    if ($e eq $SentTag){
	if ($SentStart){             # there is already an open sentence!
	    printXmlEndTag($e,@_);   # --> close the old one first!!
	    print POS $pos-1,"\n";
	}
	$SentStart=1;
	printXmlStartTag($e,@_);
	my %attr=@_;
	print POS "$attr{id}\t$pos\t";
    }
    elsif ($e eq $WordTag){
	$WordStart=1;
	$XmlStr='';
	%WordAttr=@_;
    }
    elsif (defined $SATTR{$e}){
	$nrSATTR{$e}++;                             # don't allow recursive
	if ($nrSATTR{$e}==1){printXmlStartTag($e,@_);}  # structures!!!!!!
    }
}

sub XmlEnd{
    my $p=shift;
    my $e=shift;
    if ($e eq $SentTag){
	if ($SentStart){
	    $SentStart=0;
	    printXmlEndTag($e,@_);
	    print POS $pos-1,"\n";
	}
    }
    elsif ($e eq $WordTag){
	$WordStart=0;
	printWord($XmlStr,\%WordAttr);
	$pos++;
    }
    elsif (defined $SATTR{$e}){
	if ($nrSATTR{$e}==1){printXmlEndTag($e,@_);}
	$nrSATTR{$e}--;
    }
}

sub XmlChar{
    my $p=shift;
    my $e=shift;
    if ($WordStart){
	$XmlStr.=$p->recognized_string;
    }
}

#-------------------------------------------------------------------
# XML parser handles (parser 1)

sub XmlAttrStart{
    my $p=shift;
    my $e=shift;
    if ($e eq $WordTag){
	if (defined $WordAttrPattern){
	    if ($e!~/^$WordAttrPattern$/){return;}
	}
	$WordStart=1;
	while (@_){$WordAttr{$_[0]}=$_[1];shift;shift;}
    }
    else{
	if (defined $StrucAttrPattern){
	    if ($e!~/^$StrucAttrPattern$/){return;}
	    }
	while (@_){$SATTR{$e}{$_[0]}=$_[1];shift;shift;}
    }
}





sub printWord{
    my $word=shift;
    my $attr=shift;
    $word=~tr/\n/ /;
    $word=~s/^\s+(\S)/$1/s;
    $word=~s/(\S)\s+$/$1/s;
    eval { print OUT $word; };
    foreach (@PATTR){
	if (defined $attr->{$_}){
	    eval { print OUT "\t$attr->{$_}"; };
	}
	else{
	    print OUT "\tunknown";
	}
    }
    print OUT "\n";
}

sub printXmlStartTag{
    my $tag=shift;
    my %attr=@_;
    print OUT "<$tag";
    foreach (keys %attr){
	if (defined $SATTR{$tag}{$_}){
	    print OUT " $_=\"$attr{$_}\"";
	}
    }
    print OUT ">\n";
}

sub printXmlEndTag{
    my $tag=shift;
    my %attr=@_;
    print OUT "</$tag>\n";
}

#---------------------------------------------------------------------
#---------------------------------------------------------------------
