#!/usr/bin/perl
# -*-perl-*-
#
# sentalign.pl:
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
# usage: sentalign.pl <infile >outfile
#        sentalign.pl [-i config] [-src file1] [-trg file2] [-out out] [-s sys]
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
my $IniFile='sentalign.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

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

#---------------------------------------------------------------------------

my $HardRegion=$IniData{parameter}{'hard region'};
my $PageBreak=$IniData{parameter}{'page break'};
my $Section=$IniData{parameter}{'section'};

my $AlignDir=$UplugHome.'ext/align/';
my $TmpSrc=Uplug::IO::Any::GetTempFileName;
my $TmpTrg=Uplug::IO::Any::GetTempFileName;
# my $TmpSrc=$AlignDir.'AlignSrc.'.$$;
# my $TmpTrg=$AlignDir.'AlignTrg.'.$$;
my $AlignPrg=$AlignDir.'align2';


#---------------------------------------------------------------------------
# open data streams!
#

if (not $source->open('read',$SrcStream)){exit;}
if (not $target->open('read',$TrgStream)){exit;}
$OutputStream->{DocRoot}->{version}='1.0';
$OutputStream->{DocRoot}->{fromDoc}=$SrcStream->{file},;
$OutputStream->{DocRoot}->{toDoc}=$TrgStream->{file},;
# $OutputStream->{DTDname}='liuAlign';
# $OutputStream->{DTDsystemID}='liu-align.dtd';
# $OutputStream->{DTDpublicID}='....';

if (not $output->open('write',$OutputStream)){exit;}
#---------------------------------------------------------------------------

my $data=Uplug::Data->new;
my %regions;
%{$regions{src}}=();
%{$regions{trg}}=();

# $source->open('read',$SrcStream);
open F,">$TmpSrc";
binmode(F,':encoding(utf-8)') if ($]>=5.008);
print F '<page>'."\n";
while ($source->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	my @tok=$data->content;
	map(s/^\s*//,@tok);                    # remove initial white-spaces
	map(s/\s*$//,@tok);                    # remove final white-spaces
	@tok=grep(/\S/,@tok);                  # take only non-empty tokens
	if (@tok){                             # print them if any left

	    my $before=$data->header;
	    if ($before=~/\<$PageBreak[\s\/\>]/s){
		print F '<page>'."\n";
		$regions{src}{page}++;
	    }
	    if ($before=~/\<\/$Section[\s\/\>]/s){
		print F '<p>'."\n";
		$regions{src}{paragraph}++;
	    }
	    print F '<s id="'.$id."\"\>\n";
	    print F join "\n",@tok;
	    print F "\n".'<seg>'."\n";
	}
    }
}
print F '<p>'."\n";
print F '<page>'."\n";
print F '<end>'."\n";
close F;
$source->close;

#---------------------------------------------------------------------------

my $data=Uplug::Data->new;    # use a new data-object (new XML parser!)
# $target->open('read',$TrgStream);
open F,">$TmpTrg";
binmode(F,':encoding(utf-8)')  if ($]>=5.008);
print F '<page>'."\n";
while ($target->read($data)){
    my $id=$data->attribute('id');
    if (defined $id){
	my @tok=$data->content;
	map(s/^\s*//,@tok);                      # the same for the target lang
	map(s/\s*$//,@tok);
	@tok=grep(/\S/,@tok);
	if (@tok){
	    my $before=$data->header;
	    if ($before=~/\<$PageBreak[\s\/\>]/s){
		print F '<page>'."\n";
		$regions{trg}{page}++;
	    }
	    if ($before=~/\<\/$Section[\s\/\>]/s){
		print F '<p>'."\n";
		$regions{trg}{paragraph}++;
	    }
	    print F '<s id="'.$id."\"\>\n";
	    print F join "\n",@tok;
	    print F "\n".'<seg>'."\n";
	}
    }
}
print F '<p>'."\n";
print F '<page>'."\n";
print F '<end>'."\n";
close F;
$target->close;

#---------------------------------------------------------------------------

my $soft='<seg>';
my $hard='<end>';
if ((defined $regions{src}{$HardRegion}) and 
    ($regions{src}{$HardRegion}==$regions{trg}{$HardRegion})){
    if ($HardRegion eq 'paragraph'){
	$hard='<p>';
    }
    else{
	$hard='<page>';
    }
}
elsif ($HardRegion eq 'paragraph'){
    if ((defined $regions{src}{page}) and 
	($regions{src}{page}==$regions{trg}{page})){
	$hard='<page>';
    }
}

print STDERR "para: $regions{src}{paragraph} -- $regions{trg}{paragraph}\n";
print STDERR "page: $regions{src}{page} -- $regions{trg}{page}\n";
print STDERR "$AlignPrg -v -d '$soft' -D '$hard' $TmpSrc $TmpTrg\n";
`$AlignPrg -v -d '$soft' -D '$hard' $TmpSrc $TmpTrg`;

#---------------------------------------------------------------------------

my @segments;
my %align;
my $score;
my $segID;
open F,"<$TmpSrc.al";
binmode(F,':encoding(utf-8)') if ($]>=5.008);
# binmode(F);
my @seg=();
while (<F>){
    if (/\<s id=\"(.*)\"\>/){
	push (@seg,$1);
    }
    elsif (/\<seg\>\s+([0-9]+\.[0-9]+)\s*$/){
	$segID=$1;
	push(@segments,$segID);
	$align{$segID}{src}=join(' ',@seg);
	$align{$segID}{score}=$score;
	@seg=();
    }
    elsif (/\.Score\s+(\-?[0-9]+)\s*$/){
	$score=$1;
    }
}
close F;

open F,"<$TmpTrg.al";
binmode(F,':encoding(utf-8)') if ($]>=5.008);
# binmode(F);
my @seg=();
while (<F>){
    if (/\<s id=\"(.*)\"\>/){
	push (@seg,$1);
    }
    elsif (/\<seg\>\s+([0-9]+\.[0-9]+)\s*$/){
	$segID=$1;
	$align{$segID}{trg}=join(' ',@seg);
	@seg=();
    }
}
close F;

#---------------------------------------------------------------------------

# $OutputStream->{DocRoot}->{version}='1.0';
# $OutputStream->{DocRoot}->{fromDoc}=$SrcStream->{file},;
# $OutputStream->{DocRoot}->{toDoc}=$TrgStream->{file},;
# $OutputStream->{DTDname}='liuAlign';
# $OutputStream->{DTDsystemID}='liu-align.dtd';
## $OutputStream->{DTDpublicID}='....';

# $output->open('write',$OutputStream);

foreach (@segments){
    my $out=Uplug::Data->new;
    $out->setContent(undef,$output->option('root'));
    $out->setAttribute('id','SL'.$_);
#    $out->setAttribute('method','aut');
    $out->setAttribute('xtargets',$align{$_}{src}.';'.$align{$_}{trg});
    if (defined $align{$_}{score}){
	$out->setAttribute('certainty',$align{$_}{score});
    }
    $output->write($out);
}

$output->close;

unlink $TmpSrc;
unlink $TmpTrg;
unlink $TmpSrc.'.al';
unlink $TmpTrg.'.al';

############################################################################


sub GetDefaultIni{

    my $DefaultIni = {
  'input' => {
    'source' => {
      'format' => 'XML',
      'file' => 'data/source.xml',
      'root' => 's',
    },
    'target' => {
      'format' => 'XML',
      'file' => 'data/target.xml',
      'root' => 's',
    }
  },
  'output' => {
    'text' => {
      'format' => 'align',
    }
  },
  'parameter' => {
      'hard region' => 'paragraph',
 #     'hard region' => 'page',
      'page break' => 'pb',
      'section' => '(p|head)',
  },
  'arguments' => {
    'shortcuts' => {
       'src' => 'input:source:file',
       'trg' => 'input:target:file',
       'out' => 'output:text:file',
    }
  },
};
    return %{$DefaultIni};
}
