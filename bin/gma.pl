#!/usr/bin/perl
# -*-perl-*-
#
# gma.pl:
#
# sentence alignment using GMA (ext/gma)
# http://nlp.cs.nyu.edu/GMA/
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
# usage: hunalign.pl <infile >outfile
#        hunalign.pl [-i config] [-src file1] [-trg file2] [-out out] [-s sys]
#
# config      : configuration file
# file1       : input file (source language)
# file2       : input file (target language)
# out         : output file
# system      : Uplug system (subdirectory of UPLUGSYSTEM)
# 
# 

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Uplug::Data;
use Uplug::IO::Any;
use Uplug::Config;

my $UplugHome="$Bin/../";

use strict;

my %IniData=&GetDefaultIni;
my $IniFile='gma.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);


## prepare external program call

my $UPLUGHOME="$Bin/..";
if (exists $ENV{UPLUGHOME}){$UPLUGHOME=$ENV{UPLUGHOME};}

my $GMAHOME="$UplugHome/ext/gma";
my $JAVA=$ENV{JAVA_HOME}.'/bin/java';
$ENV{CLASSPATH}="$ENV{CLASSPATH}:$GMAHOME/lib/gma.jar";
my $AlignPrg=$JAVA." -DGMApath=$GMAHOME -Xms128m -Xmx512m gma.GMA";
my $GSMCONFIG="$GMAHOME/config/GMA.config.default";
use Cwd;
my $PWD=getcwd;


#---------------------------------------------------------------------------

my $SrcStream=$IniData{input}{'source text'};
my $TrgStream=$IniData{input}{'target text'};
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

my $source=Uplug::IO::Any->new($SrcStream);
my $target=Uplug::IO::Any->new($TrgStream);
my $output=Uplug::IO::Any->new($OutputStream);

if (not -e $SrcStream->{file}){
    die "# sentalign.pl: need a source language file!";
}
if (not -e $TrgStream->{file}){
    die "# sentalign.pl: need a target language file!";
}

#---------------------------------------------------------------------------

my $SrcLang=$IniData{parameter}{'language (source)'};         # source language
my $TrgLang=$IniData{parameter}{'language (target)'};         # target language
if (-e "$GMAHOME/config/GMA.config.$SrcLang$TrgLang"){        # check language-
    $GSMCONFIG="$GMAHOME/config/GMA.config.$SrcLang$TrgLang"; # spcific config
}

#---------------------------------------------------------------------------
# open data streams!
#

if (not $source->open('read',$SrcStream)){exit;}
if (not $target->open('read',$TrgStream)){exit;}
$OutputStream->{DocRoot}->{version}='1.0';
$OutputStream->{DocRoot}->{fromDoc}=$SrcStream->{file},;
$OutputStream->{DocRoot}->{toDoc}=$TrgStream->{file},;

if (not $output->open('write',$OutputStream)){exit;}
#---------------------------------------------------------------------------

my @SrcSent=();
my @TrgSent=();


my $TmpSrc=Uplug::IO::Any::GetTempFileName;
my $TmpTrg=Uplug::IO::Any::GetTempFileName;


#---------------------------------------------------------------------------
# make xAxis for GMA (source file)

my $data=Uplug::Data->new;
open F,">$TmpSrc";
binmode(F,':encoding(utf-8)') if ($]>=5.008);

my $pos=0;
while ($source->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	push (@SrcSent,$id);
	print F "$pos <EOS>\n";
	my @tok=$data->content;
	map(s/^\s*//,@tok);                    # remove initial white-spaces
	map(s/\s*$//,@tok);                    # remove final white-spaces
	@tok=grep(/\S/,@tok);                  # take only non-empty tokens
	foreach my $t (@tok){
	    my $length = length($t);
	    printf F "%s %s\n",$pos+$length/2,$t;
	    $pos+=$length+1;
	}
    }
}
print F "$pos <EOS>\n";
close F;
$source->close;

#---------------------------------------------------------------------------
# make yAxis for GMA (target file)

my $data=Uplug::Data->new;
open F,">$TmpTrg";
binmode(F,':encoding(utf-8)') if ($]>=5.008);

my $pos=0;
while ($target->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	push (@TrgSent,$id);
	print F "$pos <EOS>\n";
	my @tok=$data->content;
	map(s/^\s*//,@tok);                    # remove initial white-spaces
	map(s/\s*$//,@tok);                    # remove final white-spaces
	@tok=grep(/\S/,@tok);                  # take only non-empty tokens
	foreach my $t (@tok){
	    my $length = length($t);
	    printf F "%s %s\n",$pos+$length/2,$t;
	    $pos+=$length+1;
	}
    }
}
print F "$pos <EOS>\n";
close F;
$target->close;


#---------------------------------------------------------------------------
# run GMA and create temporary output

my $TmpSIMR=Uplug::IO::Any::GetTempFileName;
my $TmpGSA=Uplug::IO::Any::GetTempFileName;

chdir $GMAHOME;
print STDERR "$AlignPrg -properties $GSMCONFIG -xAxisFile $TmpSrc -yAxisFile $TmpTrg -simr.outputFile $TmpSIMR -gsa.outputFile $TmpGSA\n";
my @alignments = `$AlignPrg -properties $GSMCONFIG -xAxisFile $TmpSrc -yAxisFile $TmpTrg -simr.outputFile $TmpSIMR -gsa.outputFile $TmpGSA`;
chdir $PWD;


#---------------------------------------------------------------------------
# read through output and create xml-alignment file

open F,"<$TmpGSA" || die "# gma.pl: cannot open GSA output file $TmpGSA!\n";
my $id=0;
while (<F>){
    chomp;
    my ($s,$t)=split(/ <=> /);
    my @src = split(/,/,$s);
    my @trg = split(/,/,$t);

    my @LinkSrc=();
    my @LinkTrg=();

    foreach my $s (@src){
	if ($s eq 'omitted'){last;}         # zero alignments
	push(@LinkSrc,$SrcSent[$s-1]);
    }
    foreach my $t (@trg){
	if ($t eq 'omitted'){last;}
	push(@LinkTrg,$TrgSent[$t-1]);
    }
    my $link = join(' ',@LinkSrc);
    $link .= ';';
    $link .= join(' ',@LinkTrg);

    my $out=Uplug::Data->new;
    $out->setContent(undef,$output->option('root'));
    $out->setAttribute('id','SL'.$id);
    $out->setAttribute('xtargets',$link);
    $output->write($out);
    $id++;
}

#---------------------------------------------------------------------------

close F;
$output->close;

unlink $TmpSrc;
unlink $TmpTrg;
unlink $TmpSIMR;
unlink $TmpGSA;





############################################################################


sub GetDefaultIni{

    my $DefaultIni = {
  'input' => {
    'source text' => {
      'format' => 'XML',
      'file' => 'data/source.xml',
      'root' => 's',
    },
    'target text' => {
      'format' => 'XML',
      'file' => 'data/target.xml',
      'root' => 's',
    }
  },
  'output' => {
    'bitext' => {
      'format' => 'xces align',
      'write_mode' => 'overwrite',
    }
  },
  'parameter' => {
  },
  'arguments' => {
    'shortcuts' => {
       'src' => 'input:source text:file',
       'trg' => 'input:target text:file',
       'out' => 'output:bitext:file',
       'srclang' => 'parameter:language (source)',
       'trglang' => 'parameter:language (target)',
    }
  },
};
    return %{$DefaultIni};
}
