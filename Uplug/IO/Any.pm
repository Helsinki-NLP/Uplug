#####################################################################
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
#
# Uplug::IO::Any - virtual class for arbitrary streams
#
#
#####################################################################
# $Author$
# $Id$



package Uplug::IO::Any;

use strict;
use vars qw(@ISA $VERSION);
use vars qw($DefaultFormat);
use FindBin qw($Bin);

use IO::File;
use POSIX qw(tmpnam);

use autouse 'Uplug::Config';

use Uplug::IO;
use Uplug::IO::Text;
use Uplug::IO::XML;
use Uplug::IO::PlugXML;
use Uplug::IO::Tab;
use Uplug::IO::Collection;
use Uplug::IO::LiuAlign;
use Uplug::IO::DBM;
use Uplug::IO::XCESalign;
use Uplug::IO::LWA;
use Uplug::IO::Storable;

$VERSION='0.1';
@ISA = qw( Uplug::IO );

1;


sub new{
    my $class=shift;
    my $stream=shift;
    my $format;
    if (ref($stream) eq 'HASH'){
	if (defined $stream->{format}){
	    $format=$stream->{format};
	}
	elsif (defined $stream->{file}){
	    $format=$stream->{file};
	}
    }
    else{
	$format=$stream;
    }

    my $self={};

    ## ---------------------------------
    ## 'stream name' => look for a 'named stream' and ignore all other settings

    if ((ref($stream) eq 'HASH') and ($stream->{'stream name'})){
	my $conf=&Uplug::Config::GetNamedStream($stream);
	$self=Uplug::IO::Any->new($conf);
#	$self->init($stream);
	if (not ref($self)){return 0;}
	&Uplug::IO::AddHash2Hash($self->{StreamOptions},$stream);
	return $self;
    }

    ##-----------------------------
    ## create data stream object according to format settings

    elsif ($format=~/^text$/i){$self=Uplug::IO::Text->new();}
    elsif ($format=~/^koma(\s|\Z)/i){$self=Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^align(\s|\Z)/i){$self=Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^liu\s*xml$/i){$self=Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^xces(\s|\Z)/i){$self=Uplug::IO::XCESalign->new();}
    elsif ($format=~/^xml$/i){$self=Uplug::IO::XML->new();}
    elsif ($format=~/^plug$/i){$self=Uplug::IO::PlugXML->new();}
    elsif ($format=~/^lwa/i){$self=Uplug::IO::LWA->new();}
    elsif ($format=~/^tab$/i){$self=Uplug::IO::Tab->new();}
    elsif ($format=~/^uwa\s+tab$/i){$self=Uplug::IO::Tab->new();}
    elsif ($format=~/^collection$/i){$self=Uplug::IO::Collection->new();}
    elsif ($format=~/^dbm$/i){$self=Uplug::IO::DBM->new();}
    elsif ($format=~/^stor/i){$self=Uplug::IO::Storable->new();}

    ##-----------------------------
    ## try to find the appropriate format ...

    else{
	my %new;
	if (ref($stream) eq 'HASH'){
	    %new=%{$stream};
	}
	if ($new{format}=&FindOut($format,\%new)){
	    if ($self=Uplug::IO::Any->new(\%new)){
#		$self->init(\%new);
		&Uplug::IO::AddHash2Hash($self->{StreamOptions},\%new);
		return $self;
	    }
	}
	return 0;
    }
    if (ref($stream) eq 'HASH'){
	&Uplug::IO::AddHash2Hash($self->{StreamOptions},$stream);
#	$self->init($stream);
    }
    $self->{StreamOptions}->{format}=$format;
    return $self;
}





sub FindOut{
    my $format=shift;
    my $stream=shift;

    my $found;
    if ($found=&Uplug::Config::CheckNamedStreams($stream,$format)){return $found;}
    if ($found=&CheckStreamName($stream,$format)){return $found;}
    if ($found=&CheckHeader($stream,$format)){return $found;}
    if ($found=&CheckExtender($stream,$format)){return $found;}

    return 0;
}


sub CheckStreamName{
    my $stream=shift;
    my $format=shift;

    my $format.='.upl';                       # uplug stream specifications!
    my $StreamSpec=$format;

    $StreamSpec=&FindStreamNameFile($StreamSpec);
    if ($StreamSpec){
	%{$stream}=&Uplug::Config::ReadIniFile($StreamSpec);
	return $stream->{format};
    }
}

sub FindStreamNameFile{
    my ($file)=@_;
    if (-f $file){return $file;}

    my $StreamSpec="$ENV{UPLUGRUN}/system/$file";
    if (-f $StreamSpec){return $StreamSpec;}
    $StreamSpec="$ENV{UPLUGRUN}/data/$file";
    if (-f $StreamSpec){return $StreamSpec;}
    $StreamSpec="$ENV{UPLUGRUN}/ini//$file";
    if (-f $StreamSpec){return $StreamSpec;}

    $StreamSpec="$ENV{UPLUGHOME}/$file";
    if (-f $StreamSpec){return $StreamSpec;}
    return undef;
}


sub CheckExtender{
    my $stream=shift;
    my $format=shift;

#    if (-f $format){
	if ($format=~/\.dbm$/){
	    %{$stream}=(file => $format);
	    return 'dbm';
	}
	elsif ($format=~/\.uwa$/){
	    %{$stream}=(file => $format);
	    return 'uwa tab';
	}
	elsif ($format=~/\.txt$/){
	    %{$stream}=(file => $format);
	    return 'text';
	}
	elsif ($format=~/\.liu$/){
	    %{$stream}=(file => $format);
	    return 'align';
	}
	elsif ($format=~/\.plug$/){
	    %{$stream}=(file => $format);
	    return 'plug';
	}
	elsif ($format=~/\.xml$/){
#	    if (my $found=&CheckHeader($stream,$format)){
#		return $found;
#	    }
	    %{$stream}=(file => $format);
	    return 'xml';
	}
#	elsif ($format=~/\.tei$/){
# 	%{$stream}=(file => $format);
#	    return 'tei';
#	}
	else{
	    return 0;
	}
#    }
    return 0;
}


sub CheckHeader{
    my $stream=shift;
    my $file=shift;

    $file=&FindDataFile($file);
    if ($file){
	%{$stream}=(file => $file);
	if (open F,"<$file"){
	    my $header=<F>;
	    if ($header=~/xml/){
		while (<F>){
		    if (/liu\-align\.dtd/){
			close F;
			return 'align';
		    }
		    elsif (/plugXML\.dtd/){
			close F;
			return 'plug';
		    }
#		    elsif (/TEI\/\/DTD/){
#			close F;
#			return 'tei';
#		    }
		}
		close F;
		return 'xml';
	    }
	    close F;
	}
    }
    return 0;
}


sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}

sub FindDataFile{
    my ($file)=@_;
    if (-f $file){return $file;}
    if (-f "$ENV{UPLUGHOME}/$file"){return "$ENV{UPLUGHOME}/$file";}
    if (-f "$ENV{UPLUGRUN}/data/$file"){return "$ENV{UPLUGRUN}/data/$file";}
    if ($file=~/[\\\/]([^\\\/]+)$/){
	if (-f "$ENV{UPLUGRUN}/data/$1"){return "$ENV{UPLUGRUN}/data/$1";}
    }
    return $file;
}
