#!/usr/bin/perl
#
# convert.pl
#
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# $Author$
# $Id$
#
# usage:  convert.pl [-i configfile]
#
# configfile  : configuration file
#

use strict;
use FindBin qw($Bin);
use lib "$Bin/..";
use File::Copy;

use Uplug::IO::Any;
use Uplug::Config;

my %IniData=&GetDefaultIni;
my $IniFile='convert.ini';
&CheckParameter(\%IniData,\@ARGV,$IniFile);

my %IgnoreAttr=('write_mode' => 1,
		'HeaderTag' => 1,
		'DocRootTag' => 1,
		'DocHeaderTag' => 1,
		'DocBodyTag' => 1,
		'status' => 1,
		'fromDoc' => 1,
		'toDoc' => 1,
		'SkipSrcFile' => 1,
		'SkipTrgFile' => 1,
		'language' => 1,
		'corpus' => 1,
		);

#---------------------------------------------------------------------------

my ($InputStreamName,$InputStream)=           # take only 
    each %{$IniData{'input'}};                # the first input stream
my ($OutputStreamName,$OutputStream)=         # take only
    each %{$IniData{'output'}};               # the first output stream

if ($InputStreamName and $OutputStreamName){
    if (ref($InputStream) ne 'HASH'){exit;}
    if (ref($OutputStream) ne 'HASH'){exit;}
    my $input=Uplug::IO::Any->new($InputStream);
    my $output=Uplug::IO::Any->new($OutputStream);

#    $output->replaceWithStream($input);

    if (not $input->open('read',$InputStream)){exit;}
    my $header=$input->header;
    $output->addheader($header);
    if (not $output->open('write',$OutputStream)){exit;}

    my @attr=&CompareStreams($InputStream,$OutputStream);

#---------------------------------------------------------
# copy files (use gzip if necessary!!!)

    my ($inpipe,$outpipe);
    if (($#attr==0) and ($$InputStream{$attr[0]} eq 'gzip -cd')){
	$inpipe=shift(@attr);
	$inpipe=$$InputStream{$inpipe};
    }
    elsif (($#attr==0) and ($$OutputStream{$attr[0]} eq 'gzip -c')){
	$outpipe=shift(@attr);
	$outpipe=$$OutputStream{$outpipe};
    }
    if ((not @attr) and &FilesExist($input,$output)){
	my @inFiles=$input->files;
	my @outFiles=$output->files;
	$input->close;
	$output->close;
	undef $output;
	undef $input;
	foreach (0..$#inFiles){
	    if ($inpipe){
		print STDERR "$inpipe $inFiles[$_] --> $outFiles[$_]\n";
		system "$inpipe $inFiles[$_] >$outFiles[$_]";
	    }
	    elsif ($outpipe){
		print STDERR "cat $inFiles[$_] | $outpipe--> $outFiles[$_]\n";
		system "cat $inFiles[$_] | $outpipe >$outFiles[$_]";
	    }
	    else{
		print STDERR "copy $inFiles[$_] --> $outFiles[$_]\n";
		copy ($inFiles[$_],$outFiles[$_]);
	    }
	}
    }
    else{


#---------------------------------------------------------
# read from the input stream
# and write to ouput

	my $data=Uplug::Data->new;
	while ($input->read($data)){
	    my $id=$data->attribute('id');
	    $output->write($data);
	}
	$input->close;
	$output->close;
    }
}


sub FilesExist{
    my ($input,$output)=@_;
    my @inFiles=$input->files;
    my @outFiles=$output->files;
    foreach (@inFiles){
	if (not -e $_){return 0;}
    }
    foreach (@inFiles){
	if (not $_){return 0;}
    }
    return 1;
}

sub CompareStreams{
    my ($InputStream,$OutputStream)=@_;
    my %attr=();
    foreach (keys %{$InputStream}){
	if ($IgnoreAttr{$_}){next;}
	elsif (not defined $OutputStream->{$_}){
	    $attr{$_}=1;
	}
	elsif ($_ eq 'file'){next;}
#	elsif ($_ eq 'root'){next;}
	elsif ($_ eq 'source'){next;}
	elsif ($_ eq 'target'){next;}
	elsif ($OutputStream->{$_} ne $InputStream->{$_}){
	    $attr{$_}=1;
	}
    }
    foreach (keys %{$OutputStream}){
	if ($IgnoreAttr{$_}){next;}
	elsif (not defined $InputStream->{$_}){
	    $attr{$_}=1;
	}
	elsif ($_ eq 'file'){next;}
#	elsif ($_ eq 'root'){next;}
	elsif ($_ eq 'source'){next;}
	elsif ($_ eq 'target'){next;}
	elsif ($OutputStream->{$_} ne $InputStream->{$_}){
	    $attr{$_}=1;
	}
    }
    return keys %attr;
}


sub GetDefaultIni{

    my $DefaultIni = eval 
"{
}";
    return %{$DefaultIni};
}
