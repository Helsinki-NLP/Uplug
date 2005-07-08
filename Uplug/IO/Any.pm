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
    my ($stream,$format);
    if (ref($_[0]) eq 'HASH'){$stream = shift;}
    else{$stream={};$format = shift;}

    ## ---------------------------------
    ## 'stream name' => look for a 'named stream' and ignore all other settings

    if (defined $stream->{'stream name'}){
	$stream=&Uplug::Config::GetNamedIO($stream);
    }
    if ((not defined $format) and (defined $stream->{format})){
	$format=$stream->{format};
    }

    ##-----------------------------
    ## create data stream object according to format settings

    if ($format=~/^text$/i){return Uplug::IO::Text->new();}
    elsif ($format=~/^koma(\s|\Z)/i){return Uplug::IO::LiuAlign->new();}
#    elsif ($format=~/^align(\s|\Z)/i){return Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^align(\s|\Z)/i){return Uplug::IO::XCESlign->new();}
    elsif ($format=~/^liu\s*xml$/i){return Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^xces(\s|\Z)/i){return Uplug::IO::XCESalign->new();}
    elsif ($format=~/^xml$/i){return Uplug::IO::XML->new();}
    elsif ($format=~/^plug$/i){return Uplug::IO::PlugXML->new();}
    elsif ($format=~/^lwa/i){return Uplug::IO::LWA->new();}
    elsif ($format=~/^tab$/i){return Uplug::IO::Tab->new();}
    elsif ($format=~/^uwa\s+tab$/i){return Uplug::IO::Tab->new();}
    elsif ($format=~/^collection$/i){return Uplug::IO::Collection->new();}
    elsif ($format=~/^dbm$/i){return Uplug::IO::DBM->new();}
    elsif ($format=~/^stor/i){return Uplug::IO::Storable->new();}

    ##-----------------------------
    ## try to find the appropriate format ...

    elsif (defined $stream->{file}){
	if ($format=&CheckExtender($stream->{file})){
	    $stream->{format}=$format;
	    return Uplug::IO::Any->new($stream);
	}
    }
    warn "# Uplug::IO::Any: no format specification found!\n";
    return undef;
}


sub CheckExtender{
    my $file=shift;

    if ($file=~/\.dbm$/){return 'dbm';}
    elsif ($file=~/\.uwa$/){return 'uwa tab';}
    elsif ($file=~/\.txt$/){return 'text';}
    elsif ($file=~/\.liu$/){return 'align';}
    elsif ($file=~/\.xml$/){return 'xml';}
    return undef;
}


sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}

