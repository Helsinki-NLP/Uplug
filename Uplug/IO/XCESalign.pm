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

#####################################################################
#
# XCESalign
#
#####################################################################
# $Author$
# $Id$


package Uplug::IO::XCESalign;

use strict;
use vars qw(@ISA $VERSION);
use vars qw(%StreamOptions);
use Uplug::IO::XML;
use Uplug::IO::Any;
use Uplug::Data;
# use Uplug::Data::DOM;

$VERSION=0.1;
@ISA = qw( Uplug::IO::XML );

# stream options and their default values!!

%StreamOptions = ('DocRootTag' => 'cesAlign',
		  'root' => 'link',
		  'DataStructure' => 'complex',
		  'SkipDataHeader' => 1,
		  'SkipDataTail' => 1,
		  'DTDname' => 'cesAlign',
#		  'DTDsystemID' => 'dtd/xcesAlign.dtd',
		  'DTDpublicID' => '-//CES//DTD XML cesAlign//EN'
		  );
$StreamOptions{DocRoot}{version}='1.0';

sub new{
    my $class=shift;
    my $self=$class->SUPER::new($class);
    foreach (keys %StreamOptions){
	$self->setOption($_,$StreamOptions{$_});
    }
#    &Uplug::IO::AddHash2Hash($self->{StreamOptions},\%StreamOptions);
    return $self;
}


sub open{
    my $self            = shift;
    if ($self->SUPER::open(@_)){

	if ($self->{AccessMode} eq 'read'){         # if access-mode=read:
	    if (not $self->option('DocBodyTag')){   # set document body-tag
		$self->setOption('DocBodyTag','(linkGrp|linkAlign)');
	    }
	}
	if (defined $self->{StreamOptions}->{fromDoc}){
	    $self->OpenAlignDocs($self->{StreamOptions});
	}
	elsif (defined $self->{StreamHeader}->{fromDoc}){
	    $self->OpenAlignDocs($self->{StreamHeader});
	    $self->{StreamOptions}->{fromDoc}=$self->{StreamHeader}->{fromDoc};
	    $self->{StreamOptions}->{toDoc}=$self->{StreamHeader}->{toDoc};
	}
	elsif (defined $self->{StreamOptions}->{DocRoot}->{fromDoc}){
	    $self->OpenAlignDocs($self->{StreamOptions}->{DocRoot});
	    $self->{StreamOptions}->{fromDoc}=
		$self->{StreamOptions}->{DocRoot}->{fromDoc};
	    $self->{StreamOptions}->{toDoc}=
		$self->{StreamOptions}->{DocRoot}->{toDoc};
	}
	elsif (defined $self->{StreamHeader}->{DocRoot}->{fromDoc}){
	    $self->OpenAlignDocs($self->{StreamHeader}->{DocRoot});
	    $self->{StreamOptions}->{fromDoc}=
		$self->{StreamHeader}->{DocRoot}->{fromDoc};
	    $self->{StreamOptions}->{toDoc}=
		$self->{StreamHeader}->{DocRoot}->{toDoc};
	}

	if ($self->{AccessMode} ne 'read'){
	    if (($self->{fromDoc} ne 'exists') and (not ref($self->{source}))){
		$self->{StreamOptions}->{fromDoc}=
		    $self->{StreamOptions}->{file}.'.src';
	    }
	    if (($self->{toDoc} ne 'exists') and (not ref($self->{target}))){
		$self->{StreamOptions}->{toDoc}=
		    $self->{StreamOptions}->{file}.'.trg';
	    }
	    $self->OpenAlignDocs($self->{StreamOptions});

	    # write linkGrp-tag only of we skip data headers!
	    # otherwise: linkGrp is expected to be in the data-headers
	    #            of data written to cesAlign files!!

	    if ($self->{StreamOptions}->{SkipDataHeader}){
		$self->OpenTag('linkGrp',
			       {'targType' => 's',
				'fromDoc' => $self->{StreamOptions}->{fromDoc},
				'toDoc' => $self->{StreamOptions}->{toDoc}});
	    }
	}
	return 1;
    }
    return 0;

}

sub close{
    my $self=shift;
    if (ref($self->{source})){
	$self->{source}->close();
    }
    if (ref($self->{target})){
	$self->{target}->close();
    }
    return $self->SUPER::close();
}


sub read{
    my $self=shift;
    my $data=shift;

    $data->init;
    if (not ref($data->{link})){$data->{link}=Uplug::Data->new;}
    else{$data->{link}->init;}

    my $ret=$self->SUPER::read($data->{link},@_);
    if ($self->NewDocBody){
	my $BodyAttr=$self->DocBodyAttr;
	$self->addheader($BodyAttr);
	if (not  $self->OpenAlignDocs($BodyAttr)){
	    return 0;
	}
	delete $data->{sourceSent};     # delete previous data-objects
	delete $data->{targetSent};     # (to get new XML::Parser instances)
    }

    my $attr=$data->{link}->attribute();
#     $data->addChild('align',undef,$attr);
    $data->addNode('align',$attr);
    my ($src,$trg);
    my $xtargets=$data->{link}->attribute('xtargets');
    if (defined $xtargets){
	($src,$trg)=split(/\s*\;\s*/,$xtargets);
    }
    else{return 0;}

    my @srcID=split(/\s/,$src);
    my @trgID=split(/\s/,$trg);

#----------- sentences ------------------------------

    &ReadSegments($self->{source},$data,\@srcID,'source');
    &ReadSegments($self->{target},$data,\@trgID,'target');

    $self->Uplug::IO::read($data);

#    $data->{source}=$data->subData('source');
#    $data->{target}=$data->subData('target');

#    $data->subTree($data->{source},'source');
#    $data->subTree($data->{target},'target');

    return $ret;

}




sub write{
    my $self=shift;
    my ($data)=@_;

    $self->Uplug::IO::write($data);

    my $ret;
    my $source=$data->subData('source');
    my $target=$data->subData('target');

#     my $source=Uplug::Data::DOM->new;
#    my $source=Uplug::Data->new;
#    $data->subTree($source,'source');
#    my $target=Uplug::Data->new;
#     my $target=Uplug::Data::DOM->new;
#    $data->subTree($target,'target');


    if (ref($data->{link})){
	$ret=$self->SUPER::write($data->{link});
    }
    elsif (defined $data->attribute('xtargets')){
	$ret=$self->SUPER::write($data);
    }
    else{
	my $tag=$self->option('root');
	my $link=Uplug::Data->new($tag);
	my @src=$source->findNodes('s');
	my @srcID=$source->attribute(\@src,'id');
	foreach (0..$#src){
	    if (not defined $srcID[$_]){
		$self->{srcID}++;
		$srcID[$_]=$self->{srcID};
		$source->setAttribute($src[$_],'id',$srcID[$_]);
	    }
	    $self->{srcID}=$srcID[$_];
	}
	my @trg=$target->findNodes('s');
	my @trgID=$target->attribute(\@trg,'id');
	foreach (0..$#trg){
	    if (not defined $trgID[$_]){
		$self->{trgID}++;
		$trgID[$_]=$self->{trgID};
		$target->setAttribute($trg[$_],'id',$trgID[$_]);
	    }
	    $self->{trgID}=$trgID[$_];
	}
	my $s=join(' ',@srcID);
	my $t=join(' ',@trgID);
	$link->setAttribute('xtargets',"$s\;$t",$tag);

	my $id=$data->attribute('id');
	if (not defined $id){
	    $self->{alignID}++;
	    $id=$self->{alignID};
	}
	$link->setAttribute('id',$id);
	$ret=$self->SUPER::write($link);
    }
    if (($self->{fromDoc} ne 'exists') and (ref($self->{source}))){
#	$source->moveAttribute('s','seg');
	$self->{source}->write($source);
    }
    if (($self->{toDoc} ne 'exists') and (ref($self->{target}))){
#	$target->moveAttribute('s','seg');
	$self->{target}->write($target);
    }
    return $ret;
}




sub select{
    my $self=shift;
    my ($data,$pattern,$attr,$operator)=@_;

    $data->init;
    if (not ref($data->{link})){$data->{link}=Uplug::Data->new;}
    else{$data->{link}->init;}

    my %linkPattern=();
    my %srcPattern=();
    my %trgPattern=();
    if (ref($pattern) eq 'HASH'){
	%linkPattern=%{$pattern};
	if (ref($pattern->{source}) eq 'HASH'){
	    %srcPattern=%{$pattern->{source}};
	    delete $linkPattern{source};
	}
	elsif (defined $pattern->{source}){
	    $srcPattern{'#text'}=$pattern->{source};
	    delete $linkPattern{source};
	}
	if (ref($pattern->{target}) eq 'HASH'){
	    %trgPattern=%{$pattern->{target}};
	    delete $linkPattern{target};
	}
	elsif (defined $pattern->{target}){
	    $trgPattern{'#text'}=$pattern->{target};
	    delete $linkPattern{target};
	}
    }

    if ($self->{ENDOFSTREAM}){
	delete $self->{ENDOFSTREAM};
	$self->reopen();
    }

    while ($self->SUPER::read($data->{link})){

	if ($self->NewDocBody){
	    my $BodyAttr=$self->DocBodyAttr;
	    $self->addheader($BodyAttr);
	    if (not  $self->OpenAlignDocs($BodyAttr)){
		return 0;
	    }
	}

	if (not $data->{link}->matchData(\%linkPattern,$operator)){next;}

	my $attr=$data->{link}->attribute();
# 	$data->addChild('align',undef,$attr);
	$data->addNode('align',$attr);
	my ($src,$trg);
	my $xtargets=$data->{link}->attribute('xtargets');
	if (defined $xtargets){
	    ($src,$trg)=split(/\;/,$xtargets);
	}
	else{return 0;}

	my @srcID=split(/\s/,$src);
	my @trgID=split(/\s/,$trg);

#----------- sentences ------------------------------

	&SearchSegments($self->{source},$data,\@srcID,'source');
	&SearchSegments($self->{target},$data,\@trgID,'target');

	$self->Uplug::IO::read($data);

	$data->{source}=$data->subData('source');
	$data->{target}=$data->subData('target');

#	$data->subTree($data->{source},'source');
#	$data->subTree($data->{target},'target');

	return 1;
    }

    $self->{ENDOFSTREAM}=1;
    return 0;
}




sub selectOld{
    my $self=shift;
    return $self->Uplug::IO::select(@_);
}




sub FindAlignDocFile{
    my $self=shift;
    my $doc=shift;
    if ((-s $doc) or (-s "$doc.gz")){return $doc;}   # found it --> ok!

    my $file=$self->files();                            # no?
    my $dir='./';                                       # check relative to the
    if ($file=~/^(.*[\\\/])[^\\\/]+$/){$dir=$1;}        # align-document
    if ((-s $dir.$doc) or (-s "$dir$doc.gz")){          # (align-dir/filename)
#	print STDERR "$doc --> $dir$doc\n";
	if ($doc=~/^([\\\/\.]*[^\\\/\.]+)[\\\/]/){      # make symbolic links!
	    eval { symlink ($dir.$1,$1);1 };            # ... relative dir
	}                                               # ... or
	else{eval { symlink ($dir.$doc,$doc);1 };}      # ... file link
	return $dir.$doc;                               # return path+file
    }
    my $docfile=$doc;                                   # no?
    if ($doc=~/^.*[\\\/]([^\\\/]+)$/){$docfile=$1;}     # remove path in the
    if ((-s $dir.$docfile) or (-s "$dir$docfile.gz")){  # filename and check
#	print STDERR "$doc --> $dir$docfile\n";
	if ($doc=~/^([\\\/\.]*[^\\\/\.]+)[\\\/]/){
	    eval { symlink ($dir.$1,$1);1 };
	}
	else{eval { symlink ($dir.$docfile,$docfile);1 };}
	return $dir.$docfile;                            # found it --> return!
    }                                                      # no? --> remove
    if ($doc=~/^[^\\\/]+[\\\/]([^\\\/].*)$/){$docfile=$1;} # initial directory
    if ((-s $dir.$docfile) or (-s "$dir$docfile.gz")){     # and check again!
#	print STDERR "$doc --> $dir$docfile\n";
	if ($doc=~/^([\\\/\.]*[^\\\/\.]+)[\\\/]/){
	    eval { symlink ($dir,$1);1 };
#	    print STDERR "symlink ($dir,$1)\n";
	}
	else{eval { symlink ($dir.$docfile,$docfile);1 };}
#	print STDERR "symlink ($dir.$docfile,$docfile)\n";
	return $dir.$docfile;
    }
    return $doc;
}



sub OpenAlignDocs{
    my $self=shift;
    my $options=shift;


    if (ref($options) ne 'HASH'){return 0;}
    if (($self->{AccessMode} ne 'read') and 
	((-s $options->{fromDoc}) or (-s "$options->{fromDoc}.gz") or
	 ($self->{StreamOptions}->{SkipSrcFile}))){
	$self->{fromDoc}='exists';
    }
    else{
	$options->{fromDoc}=$self->FindAlignDocFile($options->{fromDoc});
	my %stream=('file' => $options->{fromDoc},
		    'format' => 'XML',
		    'root' => 's');
	if ($self->{AccessMode} ne 'read'){$stream{DocRootTag}='document';}
	$self->{source}=Uplug::IO::Any->new(\%stream);
	if (not $self->{source}->open($self->{AccessMode},\%stream)){
	    return 0;
	}
    }
    if (($self->{AccessMode} ne 'read') and
	((-s $options->{toDoc}) or (-s "$options->{toDoc}.gz")) or
	 ($self->{StreamOptions}->{SkipTrgFile})){
	$self->{toDoc}='exists';
    }
    else{
	$options->{toDoc}=$self->FindAlignDocFile($options->{toDoc});
	my %stream=('file' => $options->{toDoc},
		    'format' => 'XML',
		    'root' => 's');
	if ($self->{AccessMode} ne 'read'){$stream{DocRootTag}='document';}
	$self->{target}=Uplug::IO::Any->new(\%stream);
	if (not $self->{target}->open($self->{AccessMode},\%stream)){
	    return 0;
	}
    }
    return 1;
}



sub ReadSegments{

    my ($stream,$data,$IDs,$lang)=@_;

    if (not ref($stream)){return;}
    if (not @{$IDs}){return;}
    my $i=0;

    #--------------------------------------------------------------
    if (not ref($data->{$lang})){
	$data->{$lang}=Uplug::Data::Lang->new();  # a new language object
    }
    if (not ref($data->{$lang.'Sent'})){
	$data->{$lang.'Sent'}=Uplug::Data->new(); # a new object for reading
    }
    #--------------------------------------------------------------

    my $parent=$data->addNode($lang);     # set root node = $lang
    $data->{$lang}->setRoot($parent);     # set root node of sub-lang-data
    my $sent=$data->{$lang.'Sent'};       # sentences will be read into $sent

#------------
# alternative: call stream->select
# (select uses read as default but may fail ...)
#
#    while ($stream->select($sent,{id => "$$IDs[0]"})){
#	my $id=$sent->attribute('id');
#	my $node=$sent->getRootNode();
#	$data->addChild($node,$parent);
#	if ($id eq $IDs->[-1]){last;}
#	$i++;
#	shift @{$IDs};
#    }

#-------------
# alterantive 2: read segments sequentially and check if the id
#                matches one of the aligned sentences
# problem: fails if the sentence does not exist
#          (the whole xml file will be read and the process stops)
# another problem: embedded non-aligned sentences
#                  right now: fail only once to match it
#                             or fail only when id is smaller then the first id
# last problem: reading stops after last id in IDs
#               sentences may be missing if a matching id comes after this one
#                   in the corpus
#
    my $fail=0;
    while ($stream->read($sent)){
	my $id=$sent->attribute('id');
	if (not grep ($_ eq $id,@{$IDs})){
	    if ($id<$IDs->[0]){next;}
	    else{
		$fail++;
		if ($fail>1){
		    last;
		}                # fail only once!!!
#		$stream->close;            # re-open the file: takes too
#		$stream->open('read');     #  much time! ... ignore it for now!
		next;
	    }
	}
	my $node=$sent->root();
	$data->addNode($parent,$node);
	if ($id eq $IDs->[-1]){last;}
	$i++;
    }
#    $sent->dispose();
}




sub SearchSegments{

    my ($stream,$data,$IDs,$lang)=@_;

    if (not ref($stream)){return;}
    if (not @{$IDs}){return;}
    my $i=0;
#    my $parent=$data->addChild($lang);
    my $parent=$data->addNode($lang);
    my $sent=Uplug::Data->new();

#------------
# call stream->select
#

    map ($_=quotemeta($_),@{$IDs});
    while (@{$IDs} and $stream->select($sent,{id => "\^$$IDs[0]\$"})){
	my $node=$sent->root();
#	$data->addChild($node,$parent);
	$data->addNode($parent,$node);
	$i++;
	shift @{$IDs};
    }
#    $sent->dispose();
}
