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


package Uplug::Web::Process::Stack;

use strict;

my $DEFAULTMAXFLOCKWAIT=5;


sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->setFile($_[0]);
    $self->setFlockWait($_[1]);
    return $self;
}



sub setFile{
    my $self=shift;
    my $file=shift;
    if (not -e $file){
	open F,">$file";
	close F;
	system "chmod g+w $file";
    }
    $self->{FILE}=$file;
}

sub getFile{
    my $self=shift;
    return $self->{FILE};
}

sub setFlockWait{
    my $self=shift;
    my $wait=shift;
    if ($wait){$self->{MAXFLOCKWAIT}=$wait;}
    else{$self->{MAXFLOCKWAIT}=$DEFAULTMAXFLOCKWAIT;}
}

sub open{
    my $self=shift;

    my $fh=$self->{FH};
    if (not -e $self->{FILE}){return 0;}
    open $self->{FH},"+<$self->{FILE}";
    my $sec=0;
    while (not flock($self->{FH},2)){
	$sec++;sleep(1);
	if ($sec>$self->{MAXFLOCKWAIT}){
	    close $self->{FH};
	    return 0;
	}
    }
    $self->{STATUS}='open';
    return 1;
}

sub close{
    my $self=shift;

    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	truncate($fh,tell($fh));
	close $fh;
	$self->{STATUS}='closed';
    }
}

sub read{
    my $self=shift;

    if ($self->{STATUS} ne 'open'){
	if ($self->open()){
	    my $fh=$self->{FH};
	    my @content=<$fh>;
	    $self->close();
	    return wantarray ? @content : join "@content";
	}
	return ();
    }
    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	my @content=<$fh>;
	return wantarray ? @content : join "@content";
    }
    return ();
}

sub write{
    my $self=shift;
    my $content=shift;

    if ($self->{STATUS} eq 'open'){
	my $fh=$self->{FH};
	seek ($fh,0,0);
	if (ref($content) eq 'ARRAY'){print $fh @{$content};}
	else{print $fh $content;}
	return 1;
    }
    return 0;
}


sub push{
    my $self=shift;
    my $text=join(':',@_);

    if ($self->open()){
	my @content=$self->read();
	push (@content,$text."\n");
	$self->write(\@content);
	$self->close();
	return 1;
    }
    return 0;
}


sub pop{
    my $self=shift;

    if ($self->open()){
	my @content=$self->read();
	my $text=pop (@content);
	$self->write(\@content);
	$self->close();
	chomp($text);
	return wantarray ? split(/\:/,$text) : $text;
    }
    return undef;
}



sub unshift{
    my $self=shift;
    my $text=join(':',@_);

    if ($self->open()){
	my @content=$self->read();
	unshift (@content,$text."\n");
	$self->write(\@content);
	$self->close();
	return 1;
    }
    return 0;
}


sub shift{
    my $self=shift;

    if ($self->open()){
	my @content=$self->read();
	my $text=shift (@content);
	$self->write(\@content);
	$self->close();
	chomp($text);
	return wantarray ? split(/\:/,$text) : $text;
    }
    return undef;
}

sub remove{
    my $self=shift;
    my @data=@_;
    map($_=quotemeta($_),@data);

    my $pattern='^'.join(':',@data).'(\:|\Z)';
    if ($self->open()){
	my @content=$self->read();
	@content=grep($_!~/$pattern/,@content);
	$self->write(\@content);
	$self->close();
	return 1;
    }
    return 0;
}


sub find{
    my $self=shift;
    my @data=@_;
    map($_=quotemeta($_),@data);

    my $pattern='^'.join(':',@data).'(\:|\Z)';
    my @content=$self->read();
    my @match=grep($_=~/$pattern/,@content);
    chomp($match[0]);
    return wantarray ? split(/\:/,$match[0]) : $match[0];
}
