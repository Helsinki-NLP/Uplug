#!/usr/bin/perl
#---------------------------------------------------------------------------
# corpus-indexer.pl
#
# create CWB-indeces from XML corpus files
#
# usage: corpus-indexer.pl [-l language] reg data xml-files
#
#   reg ......... CWB registry file (will be created!)
#   data ........ CWB data directory
#   xml-files ... one or more XML files to be indexed
#   language .... language identifier (optional)
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

#my $CWBBIN='/usr/local/bin';
#my $ENCODE="$CWBBIN/cwb-encode";
#my $CWBMAKEALL="${CWBBIN}/cwb-makeall";
#my $CWBALIGNENCODE="${CWBBIN}/cwb-align-encode";

my $ENCODE='cwb-encode';
my $CWBMAKEALL='cwb-makeall';
my $CWBALIGNENCODE='cwb-align-encode';
my $LANG      = 'en';

while ($ARGV[0]=~/^\-/){
    my $opt=shift(@ARGV);
    if ($opt eq '-l'){$LANG=shift(@ARGV);}
}

my $REG       = shift(@ARGV);  # CWB regisistry
my $DATDIR    = shift(@ARGV);  # CWB data directory
my @CORPUS    = @ARGV;         # corpus files

if (not -d $DATDIR){mkdir $DATDIR;}
if (not -d $DATDIR){die "cannot access data dir: $DATDIR!";}

#-----------------------------------------------------------------------

my $DIR    = $ENV{PWD};
my $TMPDIR = '/tmp/CORPUSINDEXER'.$$;
mkdir $TMPDIR;
chdir $TMPDIR;

if (not -d $DATDIR){$DATDIR="$DIR/$DATDIR";}
if ($REG!~/^\//){$REG="$DIR/$REG";}

#-----------------------------------------------------------------------

foreach (0..$#CORPUS){
    if (not -e $CORPUS[$_]){$CORPUS[$_]="$DIR/$CORPUS[$_]";}
}

&XML2CWB($REG,$DATDIR,$LANG,\@CORPUS);

system "rm $TMPDIR/*";
system "rmdir $TMPDIR";
chdir $DIR;



#----------------------------------------------------------------------
#----------------------------------------------------------------------
# XML2CWB
#
# convert XML files to CWB index files
#----------------------------------------------------------------------
#----------------------------------------------------------------------

sub XML2CWB{

    my ($reg,$datdir,$lang,$files)=@_;
    $lang=~tr/A-Z/a-z/;


    #----------------------------------------------------------
    # convert corpus files to CWB input format!
    # (restrict structural patterns with spattern)

    my $allattr=1;
#    my $spattern=undef;
    my $spattern='(cell|row|table|s|p|pb|head|c|chunk)';
    my $ppattern=undef;
    my $attr=&XML2CWBinput($lang,$files,$allattr,$spattern,$ppattern);

    #----------------------------------------------------------
    # cwb-encode arguments (PATTR and SATTR) are stored in $L.cmd
    # (take only one of them to encode the entire corpus)

    if (not -d $datdir){mkdir "$datdir";}
    system ("$ENCODE -R $reg -d $datdir -f $lang $attr");
    my $regdir=dirname($reg);
    my $corpus=basename($reg);
    system ("$CWBMAKEALL -r $regdir -V $corpus");

    unlink $lang;
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
