
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# -*-perl-*-
# $Id$	


package Uplug::IO::LWA;

use strict;
use vars qw(@ISA $VERSION);
use vars qw(%StreamOptions);
use Uplug::IO::Text;
use Uplug::IO::Any;
# use Uplug::Data;
# use Uplug::Data::Tree;

$VERSION='1.0';
@ISA = qw( Uplug::IO );

# stream options and their default values!!


sub open{
    my $self=shift;
    if ($self->SUPER::open(@_)){
	my $src=$self->options();
	$src->{file}=$self->option('source file');
	$self->{source}=Uplug::IO::Any->new('text',$src);
	if (not $self->{source}->open(@_[0],$src)){
	    return 0;
	}
	my $trg=$self->options();
	$trg->{file}=$self->option('target file');
	$self->{target}=Uplug::IO::Any->new('text',$trg);
	if (not $self->{target}->open(@_[0],$trg)){
	    return 0;
	}
	return 1;
    }
    return 0;
}


sub write{
    my $self=shift;
    my ($data)=@_;
    $self->Uplug::IO::write($data);
    my $cont=$data->content('source');
    $self->{source}->write($cont);
    my $cont=$data->content('target');
    $self->{target}->write($cont);
}


sub read{

    print STDERR "# Uplug::IO::LWA: read doesn't work\n";
    return 0;
}

sub close{
    my $self=shift;
    $self->{source}->close();
    $self->{target}->close();
    $self->SUPER::close(@_);
}
