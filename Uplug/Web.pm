#
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


package Uplug::Web;

use strict;
use CGI qw/:standard escapeHTML escape/;
use Uplug::Web::Corpus;
use Uplug::Web::Process;
use Uplug::Web::User;
use Uplug::Web::CWB;
use XML::Parser;

our $CWBREG=$ENV{UPLUGCWB}.'/reg/';
our $ALIGN2CWB=$ENV{UPLUGHOME}.'/web/bin/make-cwb-align';
our $CORPUS2CWB=$ENV{UPLUGHOME}.'/web/bin/make-cwb-corpus';

our $RECODE='/home/staff/joerg/user_local/bin/recode';

my $MAXVIEWLINES=40;
my $MAXVIEWDATA=10;
binmode(STDOUT, ":utf8");            # set UTF8 for STDOUT

my %DataAccess=
    (admin => {corpus => ['info','view','send','add','align',
			  'index','query','remove'],
	       doc => ['info','view','send','remove'],
	       user => ['info','edit','remove']},
     user => {corpus => ['info','view','send','add','align',
			 'index','query','remove'],
	      doc => ['info','view','send','remove'],
	      'Uplug::Web::Data' => ['xml'],
	      'Uplug::Web::Bitext' => ['text','xml'],
	      'Uplug::Web::BitextLinks' => ['text','xml','matrix','edit'],
	      user => ['info','edit']},
     all => {doc => ['info','view','send'],
	     corpus => ['info','view','send'],
	     'Uplug::Web::Data' => ['xml'],
	     'Uplug::Web::Bitext' => ['text','xml'],
	     'Uplug::Web::BitextLinks' => ['text','xml','matrix'],
	     user => ['info']});



sub AccessMode{
    my $priv=shift;
    my $type=shift;
    return $DataAccess{$priv}{$type};
}

sub ShowUserInfo{
    my $query=shift;
    my $user=shift;
    my $UserData=shift;
    my $name=shift;
    my $admin=shift;

    my @rows=();
    foreach my $u (keys %{$UserData}){

	my $priv='all';                     # access priviliges: public
	if ($admin){$priv='admin';}         #    administrator
	elsif ($u eq $user){$priv='user';}  #    registered user

	my $url=&AddUrlParam($query,'n',$u);
	if (keys %{$$UserData{$u}} > 1){
	    push (@rows,
		  &th([$u]).
		  &td(&ActionLinks($url,&AccessMode($priv,'user'))));
	    foreach (keys %{$$UserData{$u}}){
		if ($_ eq 'Password'){$$UserData{$u}{$_}='*******';}
		push (@rows,td([$_,$$UserData{$u}{$_}]));
	    }
	}
	else{
	    push (@rows,
		  &th([$u]).
		  &td(&ActionLinks($url,&AccessMode($priv,'user'))));
	}
    }
    return &table({},caption(''),&Tr(\@rows));
}


#--------------------------------------------------------------------

sub RemoveCorpus{
    my $user=shift;
    my $corpus=shift;
    my $param=shift;

    if ($$param{'really'}){
	return &Uplug::Web::Corpus::RemoveCorpus($user,$corpus);
    }
    elsif (not defined $$param{'really'}){
	my $str= &start_multipart_form;
	$str.="Are you really sure to remove the entire '$corpus' corpus? ";
	$str.=&checkbox(-name=>'really',
			-value=>1,
			-label=>'yes!');
	$str.= &p();
	$str.= &submit(-name => 'submit');
	$str.= &endform;
	return $str;
    }
    return "Corpus $corpus has not been removed!";
}


sub AddCorpus{
    my $user=shift;
    my $param=shift;
    my $query=shift;

    my $name=$$param{name};
    my $priv=$$param{priv};

    #------------------------------------------------------------

    if (not $name){return &AddCorpusForm();}
    else{
	my ($ret,$msg)=&Uplug::Web::Corpus::AddCorpus($user,$name,$priv);
	return &h3($msg);
    }
}

sub AddDocument{
    my $user=shift;
    my $corpus=shift;
    my $file=shift;
    my $param=shift;
    my $query=shift;

    my $name=$$param{name};
#    my $file=$$param{file};
    my $lang=$$param{lang};
    my $enc=$$param{enc};

    #------------------------------------------------------------

    my $html;
    if ($corpus and $name and $file){
	my ($ret,$msg)=&Uplug::Web::Corpus::AddDocument($user,$corpus,
							$name,$file,
							$lang,$enc);
#	if (not $ret){
##	    my $back=&a({-href=>'javascript:',
##			 -onclick=>'history.go(-1)'},'back');
#	    return &h3($msg).&AddDocumentForm($user,$corpus);
#	}
	$html=&h3($msg);
    }
    return &AddDocumentForm($user,$corpus).$html;
}


sub AddDocumentOld{
    my $user=shift;
    my $corpus=shift;
    my $document=shift;
    my $param=shift;
    my $query=shift;

    my $name=$$param{'name'};
    my $file=$$param{'file'};
    my $lang=$$param{'lang'};
    my $enc=$$param{'enc'};

    my $CorpusName=&Uplug::Web::Corpus::GetCorpusName($name,$lang);

    #------------------------------------------------------------

    my $missing=0;
    my @rows=();

    if (not $name){$missing++;}
    if ((defined $name) and ($name!~/^[a-zA-Z\.\_0-9]{1,10}$/)){
	$missing++;
	print "Corpus name $name is not valid!",&br();
    }
#    if (defined $$CorpusData{$CorpusName}){
#	$missing++;
#	print "A corpus with the name '$CorpusName' exists already!",&br();
#    }
    if (not $file){$missing++;}

    if (not defined $enc){$enc='utf8';}
    if (not defined $lang){$lang='en';}

    #------------------------------------------------------------

    if ($missing){
	print &AddDocumentForm;
    }
    else{
	if (&Uplug::Web::Corpus::AddTextCorpus($user,$name,$lang,$file,$enc)){
	    print &h3("The corpus $CorpusName has been successfully added!");
	}
	else{
	    print &h3("Operation failed!");
	    print &AddCorpusQuery;
	}
	print &Uplug::Web::ShowCorpusInfo($user,$user,$corpus,$query);
    }
}



sub AddCorpusForm{
    my @rows;
    push (@rows,
	  &td(["Corpus name: ",
	       &textfield(-name=>'name',
			  -size=>25,
			  -maxlength=>50)]).
	  &td([&checkbox(-name=>'priv',
#			 -checked=>'checked',
			 -value=>1,
			 -label=>'private')]));

    my $str="Add a corpus to your repository!".&p();
    $str.= "Specify a unique name for your corpus ";
    $str.= "with not more than 10 characters!".&br;
    $str.= "Use ASCII characters only for the name of the corpus using the following character set: ";
    $str.= "[a-z,A-Z,0-9,_]!".&br();
    $str.= "Each corpus may consists of multiple files in different languages!".&p();
    $str.= "The file must be a plain text file! Additional markup is not recognized and will be used as text!".&br();

    $str.= &start_multipart_form;
    $str.= &table({},caption(''),&Tr(\@rows));
    $str.= &p();
    $str.= &submit(-name => 'submit');
    $str.= &endform;
}



sub AddDocumentForm{
    my $user=shift;
    my $corpus=shift;

    my @rows;
    my $corpora=&Uplug::Web::Corpus::Corpora($user);

    push (@rows,&td(['Select a corpus: ',
		     &popup_menu(-name=> 'c',
				 -values => [sort keys %{$corpora}])]));
    push (@rows,&td(["Document name: ",
		     &textfield(-name=>'name',
				-size=>25,
				-maxlength=>50).
		     &Uplug::Web::iso639_menu('lang','en')]));

    push (@rows,&td(["Upload file: ",
		     &filefield(-name=>'file',
				-size=>25,
				-maxlength=>50)]));

    push (@rows,&td(['Encoding',&Uplug::Web::encodings_menu('enc','utf8')]));

    my $str="Add a document to your repository!".&p();
    $str.= "Select a corpus and specify a unique name for your document ";
    $str.= "with not more than 15 characters!".&br;
    $str.= "Use ASCII characters only for the name of the document using the following character set: ";
    $str.= "[a-z,A-Z,0-9,_,.]!".&br();
    $str.= "Each document may be translated into different languages!".&p();
    $str.= "The file must be a plain text file! Additional markup is not recognized and will be used as text!".&br();
    $str.= "Make sure that the specified character encoding matches the encoding of your corpus file".&br();
    $str.= "Check for example ".&a({-href => 'http://czyborra.com/charsets/iso8859.html'},'this').' page for more information about character encoding'.&br();


    $str.= &start_multipart_form;
    $str.= &table({},caption(''),&Tr(\@rows));
    $str.= &p();
    $str.= &submit(-name => 'submit');
    $str.= &endform;
}









sub CorpusIndexerForm{
    my ($user)=@_;
    my %corpora=();
    &Uplug::Web::Corpus::GetCorpusData(\%corpora,$user);
    my $form= &startform();
    $form.='Select a corpus to be indexed by the Corpus Work Bench (CWB)'.&p();
    $form.=&popup_menu(-name=> 'corpus',
		       -values => [sort keys %corpora]);
    $form.=&br().&encodings_menu('srcenc','iso-8859-1');
    $form.='character encoding in the index (source language if bitext)'.&br();
    $form.=&encodings_menu('trgenc','iso-8859-1');
    $form.='character encoding in the index (target, only for bitexts)'.&br();
    $form.=&p();
    $form.= &submit(-name => 'action',-value => 'add');
    $form.= &endform;
    return $form;
}

sub LostPassword{
    my ($email)=@_;
    my $html=&h3("Lost password").&hr();
    if ($email){return $html.=&Uplug::Web::User::SendPassword($email);}
    my $form= &startform();
    $form.='Type your e-mail adress: ';
    $form.=&textfield(-name => 'e',-default=>'user@uplug.se');
    $form.= &submit(-name => 'action',-value => 'send');
    $form.= &endform;
    return $html.$form;
}

sub CorpusQueryForm{
    my ($owner,$corpus)=@_;
    return &Uplug::Web::CWB::Query('?a=corpus;t=query',$owner,$corpus);
}


sub CorpusQuery{

    my ($user,$owner,$corpus,$lang,$cqp,$aligned,$style)=@_;

    my $registry=$CWBREG.$user.'/'.$corpus;
    $WebCqp::Query::Registry = $registry;

    my $query;
    eval { $query = new WebCqp::Query("$lang"); };
    if ($@){print "--$@--$!--$?--";}

    $query->on_error(sub{grep {print "$_".&br()} @_});
    my @corpora=($lang);
    if (ref($aligned) eq 'ARRAY'){
	$query->alignments(sort @{$aligned});
	push (@corpora,@{$aligned});
    }
    $query->context('1 s', '1 s');
    if ($cqp!~/^[\"\[]/){$cqp='"'.$cqp.'"';}
    my @result = $query->query($cqp);
    my $nr_result = @result;

    my $html="Query string: \"$cqp\"".&br();
    $html.="<b>$nr_result</b> hits found<br>--------".&p();

    my @rows=();
    if ($style eq 'vertical'){
	push (@rows,&th(['',@corpora]));
    }

    my $nr;my $i;
    for ($i = 0; $i < $nr_result; $i++) {
	$nr = $i + 1;
	my $m = $result[$i];
	my $pos = $m->{'cpos'};
	my $ord = $m->{'kwic'}->{'match'};
	my $res_r = $m->{'kwic'}->{'right'};
	my $res_l = $m->{'kwic'}->{'left'};

	push (@rows,&td({-valign=>'top'},
			[$pos,"$res_l <b>$ord</b> $res_r"]));
	if (ref($aligned) eq 'ARRAY'){
	    foreach (@{$aligned}){
		if ($style eq 'vertical'){
		    $rows[-1].=&td({-valign=>'top'},$m->{$_});
		}
		else{
		    push (@rows,&td({-valign=>'top'},[$_,$m->{$_}]));
		}
	    }
	}
    }
    $html.=&table({-width=>'100%'},caption(''),&Tr(\@rows));
    return $html;
}


############################################################################
# ShowCorpusInfo:
#    * list all corpora of a certain owner
#    * list info about documents for selected corpora
############################################################################

sub ShowCorpusInfo{
    my $task=shift;
    my $owner=shift;
    my $corpus=shift;
    my $docbase=shift;
    my $doc=shift;
    my $priv=shift;

    my $CorpusNames=&Uplug::Web::Corpus::Corpora($owner);
    if (not defined $corpus){($corpus)=each %{$CorpusNames};}
    if (not defined $task){$task='view';}

    #--------------------------------------------------------
    # read info about corpus documents if a corpus is selected

    my %docs=();
    my $CorpusDocs={};
    if (defined $$CorpusNames{$corpus}){
	$CorpusDocs=&Uplug::Web::Corpus::CorpusDocuments($owner,$corpus);
	foreach my $c (sort keys %{$CorpusDocs}){
	    my $d=$$CorpusDocs{$c}{corpus};
	    $d=~s/\sword//;
	    my $l=$$CorpusDocs{$c}{language};
	    if ($l=~/^(.+)\-(.+)$/){             # alignments:
		my $s=$1;                        # source language
		my $t=$2;                        # target language
		if ($c=~/word\s\(/){             # word alignments:
		    $docs{$d}{$s}{$t}=$c;        #  save source->target
		}
		else{                            # sentence alignment:
		    $docs{$d}{$t}{$s}=$c;        #  save target->source
		}
	    }
	    else{
		$docs{$d}{$l}{'_doc'}=$c;
	    }
	}
    }
    #--------------------------------------------------------

    my $query=&AddUrlParam('','a','corpus');
    $query=&AddUrlParam($query,'o',$owner);

    my $link=$query;
    if (not defined $docbase){($docbase)=each %docs;}
    if (defined $corpus){$link=&AddUrlParam($link,'c',$corpus);}
    if (defined $docbase){$link=&AddUrlParam($link,'b',$docbase);}

    my $html;
#    my $html='possible tasks: ';
#    $html.=&TaskLinks({url=>$link,selected=>$task},
#		      &AccessMode($priv,'corpus')).&br();

#    $html.=&ActionLinks($link,&AccessMode($priv,'corpus')).&br();
#    $html.='selected task: '.$task;
    $query=&AddUrlParam($query,'t',$task);
    if ($task eq 'remove'){
	$html.=&p().&b('ATTENTION! ');
	$html.='Documents will be removed immediately';
	$html.=' when clicking on the links below!';
    }
    $html.=&p();

    foreach my $c (sort keys %{$CorpusNames}){

	$query=&AddUrlParam($query,'c',$c);
	if ($c eq $corpus){$html.=$c.' ';}
	else{$html.=&a({-href=>$query},$c.' ');}

	$html.=&TaskLinks({url=>$query,selected=>$task},
			  &AccessMode($priv,'corpus')).&p();

#	$html.=&ActionLinks($url,&AccessMode($priv,'corpus')).&br();
#	push (@rows,&td([&a({-href=>$url},$c)]));
	if ($c ne $corpus){next;}

	my @rows=();
	foreach my $d (sort keys %docs){
	    my $link=&AddUrlParam($query,'b',$d);   # add base name
#	    push (@rows,&th([$d]));
#	    $rows[-1].=&td(['['.&a({-href=>$link},'links').']']);
	    if ($d eq $docbase){push(@rows,&th([$d]));}
	    else{
		push(@rows,&th([&a({-href=>$link},$d)]));
	    }
	    my @lang=sort keys %{$docs{$d}};
	    foreach my $l (@lang){
		$link=&AddUrlParam($link,'d',$docs{$d}{$l}{'_doc'});
		$rows[-1].=&td({-align=>'center'},
			       ['['.&a({-href=>$link},$l).']']);
	    }
	    if ($docbase ne $d){next;}
	    foreach my $s (@lang){
		$link=&AddUrlParam($link,'d',$docs{$d}{$s}{'_doc'});
		push (@rows,&td({-align=>'right'},
				['['.&a({-href=>$link},$s).']']));
		foreach my $t (@lang){
		    if (defined $docs{$d}{$s}{$t}){
			$link=&AddUrlParam($link,'d',$docs{$d}{$s}{$t});
			if ($docs{$d}{$s}{$t}=~/\sword\s\(/){
			    $rows[-1].=&th([&a({-href=>$link},'word')]);
			    }
			else{
			    $rows[-1].=&th([&a({-href=>$link},'sent')]);
			}
		    }
		    else{
			$rows[-1].=&th({-align=>'center'},['-']);
		    }
		}
	    }
#	    if ((defined $doc) and ($task eq 'info')){
#		foreach (keys %{$$CorpusDocs{$doc}}){
#		    push (@rows,td([$_,$$CorpusDocs{$doc}{$_}]));
#		}
#	    }
	}
	$html.=&table({},caption(''),&Tr(\@rows)).&p();
	if ((defined $doc) and ($task eq 'info')){
	    my @rows=();
	    push (@rows,&th(['info:',$doc]));
	    foreach (keys %{$$CorpusDocs{$doc}}){
		push (@rows,&td([$_,$$CorpusDocs{$doc}{$_}]));
	    }
	    $html.=&table({},caption(''),&Tr(\@rows)).&p();
	}
    }
    return $html;
}


#
# end of ShowCorpusInfo
#
############################################################################


############################################################################
# ShowCorpusInfo:
#    * list all corpora of a certain owner
#    * list info about documents for selected corpora
############################################################################

sub ShowCorpusInfoLast{
    my $owner=shift;
    my $corpus=shift;
    my $doc=shift;
    my $priv=shift;

    my $query=&AddUrlParam('','a','corpus');
    $query=&AddUrlParam($query,'o',$owner);
    my $CorpusNames=&Uplug::Web::Corpus::Corpora($owner);
    if (not defined $corpus){($corpus)=each %{$CorpusNames};}

    #--------------------------------------------------------
    # read info about corpus documents if a corpus is selected

    my %docs=();
    my $CorpusDocs={};
    if (defined $$CorpusNames{$corpus}){
	$CorpusDocs=&Uplug::Web::Corpus::CorpusDocuments($owner,$corpus);

	foreach my $c (sort keys %{$CorpusDocs}){
	    if ($$CorpusDocs{$c}{format}=~/align/){
		push (@{$docs{alignment}},$c);
	    }
	    elsif (defined $$CorpusDocs{$c}{language}){
		push (@{$docs{monolingual}},$c);
	    }
	    else{
		push (@{$docs{other}},$c);
	    }
	}
    }
    #--------------------------------------------------------


    my @rows=();
    foreach my $c (sort keys %{$CorpusNames}){

	my $url=&AddUrlParam($query,'c',$c);
	push (@rows,&td([&a({-href=>$url},$c)]).
	      &td(&ActionLinks($url,&AccessMode($priv,'corpus'))));

	if ($c ne $corpus){next;}

	foreach my $t ('monolingual','alignment','other'){
	    if (ref($docs{$t}) eq 'ARRAY'){
		foreach my $d (sort @{$docs{$t}}){
		    my $url=&AddUrlParam($query,'c',$corpus);
		    $url=&AddUrlParam($url,'d',$d);

		    push (@rows,&th([$d]).
			  &td(&ActionLinks($url,&AccessMode($priv,'doc'))));

		    #---------------------------------------------
		    # if a document has been selected:
		    #    show all information about the document

		    if ($d eq $doc){
			foreach (keys %{$$CorpusDocs{$d}}){
			    push (@rows,td([$_,$$CorpusDocs{$d}{$_}]));
			}
		    }
		    #----------------------------------------------
		}
	    }
	}
    }
    return &table({},caption(''),&Tr(\@rows));
}


#
# end of ShowCorpusInfo
#
############################################################################




#-----------------------------
# ShowCorpusInfo:
#    * list all corpora of a certain owner
#    * if no owner specified: list all corpora of all users

sub ShowCorpusInfoOld{
    my $user=shift;
    my $owner=shift;
    my $corpus=shift;
    my $doc=shift;
    my $query=shift;

    my %CorpusData=();

    #----------------------------------------
    # no owner: get corpora of all users!

    if (not $owner){$owner=$user;};
#    if (not $owner){
#	my %UserData=();
#	&Uplug::Web::User::ReadUserInfo(\%UserData);
#	my $html='';
#	foreach my $u (keys %UserData){
#	    $html.=&h3($u);
#	    $html.=&ShowCorpusInfo($user,$u,$corpus,$query);
#	}
#	return $html;
#    }
    #----------------------------------------

    &Uplug::Web::Corpus::GetCorpusData(\%CorpusData,$owner);
    my %corpora=();
    foreach my $c (sort keys %CorpusData){
	if ($CorpusData{$c}{format}=~/align/){
	    push (@{$corpora{$CorpusData{$c}{corpus}}{alignment}},$c);
	}
	elsif (defined $CorpusData{$c}{language}){
	    push (@{$corpora{$CorpusData{$c}{corpus}}{monolingual}},$c);
	}
	else{
	    push (@{$corpora{$CorpusData{$c}{corpus}}{other}},$c);
	}
    }

    my @rows=();
    foreach my $c (sort keys %corpora){
	foreach my $t ('monolingual','alignment','other'){
	    if (ref($corpora{$c}{$t}) eq 'ARRAY'){
		push (@rows,&td([$c.' - '.$t]));
		foreach my $n (sort @{$corpora{$c}{$t}}){
		    my $url=&AddUrlParam($query,'c',$n);
		    $url=&AddUrlParam($url,'o',$owner);
		    if ($n eq $corpus){
			push (@rows,
			      &th([$n]).
			      &td(&ActionLinks($url,
					       &AccessMode($user,
							   $owner,
							   'corpus'))));
			foreach (keys %{$CorpusData{$n}}){
			    push (@rows,td([$_,$CorpusData{$n}{$_}]));
			}
		    }
		    else{
			push (@rows,&th([$n]).
			      &td(&ActionLinks($url,
					       &AccessMode($user,
							   $owner,
							   'corpus'))));
		    }
		}
	    }
	}
    }
    return &table({},caption(''),&Tr(\@rows));
}


sub ShowCorpusInfoNew{
    my $query=shift;
    my $user=shift;
    my $corpus=shift;

    my %CorpusData;
    &Uplug::Web::Corpus::GetCorpusData(\%CorpusData,$user);

    my %corpora;
    foreach my $c (sort keys %CorpusData){
	if ($CorpusData{$c}{format}=~/align/){
	    if ($CorpusData{$c}{language}=~/^(.*)\-(.*)$/){
		$corpora{$CorpusData{$c}{corpus}}{align}{$1}{$2}=$c;
	    }
	    push (@{$corpora{$CorpusData{$c}{corpus}}{alignment}},$c);
	}
	elsif (defined $CorpusData{$c}{language}){
	    $corpora{$CorpusData{$c}{corpus}}{mono}{$CorpusData{$c}{language}}=
		$c;
	}
	else{
	    push (@{$corpora{$CorpusData{$c}{corpus}}{other}},$c);
	}
    }

    my @rows=();
    foreach my $c (sort keys %corpora){

	if (ref($corpora{$c}{mono}) eq 'HASH'){
	    my %trg=();
	    if (ref($corpora{$c}{align}) eq 'HASH'){
		foreach my $s (sort keys %{$corpora{$c}{align}}){
		    if (ref($corpora{$c}{align}{$s}) eq 'HASH'){
			foreach (keys %{$corpora{$c}{align}{$s}}){
			    $trg{$_}=1;
			}
		    }
		}
	    }
	    push (@rows,&td([$c,'','',sort keys %trg]));
	    foreach my $s (sort keys %{$corpora{$c}{mono}}){
		my $n=$corpora{$c}{mono}{$s};
		my $url=&AddUrlParam($query,'corpus',$n);
		$url=&AddUrlParam($url,'user',$user);
		if ($n eq $corpus){
		    push (@rows,
			  &th([$n]).
			  &td(&ActionLinks($url,
					   'info','view',
					   'send','remove')));
		    foreach (keys %{$CorpusData{$n}}){
			push (@rows,td([$_,$CorpusData{$n}{$_}]));
		    }
		}
		else{
		    push (@rows,&th([$n]).
			  &td(&ActionLinks($url,
					   'info','view',
					   'send','remove')));
		}

#-----------------------------------------------------
# link matrix ....
#
		my @t;
		foreach (sort keys %trg){
		    if (ref($corpora{$c}{align}) ne 'HASH'){next;}
		    if (ref($corpora{$c}{align}{$s}) ne 'HASH'){next;}
		    if (defined $corpora{$c}{align}{$s}{$_}){
			my $url=&AddUrlParam($query,'corpus',
					     $corpora{$c}{align}{$s}{$_} );
			push(@t,&ActionLinks($url,'view'));
		    }
		    else{push(@t,'');}
		}
		$rows[-1].=&th(['align']).&td([@t]);
	    }
	}
#----------------------------------------------------
    }

    return &table({},caption(''),&Tr(\@rows));
}



#-------------------------------------------------------------------------

sub ViewCorpus{
    my ($owner,
	$corpus,
	$doc,
	$url,
	$pos,
	$style,
	$params,
	$links)=@_;

    my $DocConfig=&Uplug::Web::Corpus::GetCorpusInfo($owner,$corpus,$doc);
    if (not defined $$DocConfig{file}){return undef;}
    my $file=$$DocConfig{file};
    my $data;

    my $priv='user';                     # default: user privileges
    if ($owner eq 'pub'){$priv='all';}   # for public data: restricted access!
    if ($$DocConfig{format}=~/align/){
	if ($$DocConfig{status}=~/word/){
	    $data=new Uplug::Web::BitextLinks($priv,$file);
	}
	else{
	    $data=new Uplug::Web::Bitext($priv,$file);
	}
    }
    else{$data=new Uplug::Web::Data($priv,$file);}
    return $data->view($url,$style,$pos,$params,$links);
#    my $html='['.&a({-href=>'javascript:history.go(-1)'},'back').']';
#    return $html.$data->view($url,$style,$pos,$params,$links);
}


###################################################################

sub SelectCorpusForm{
    my $user=shift;
    my $corpora=&Uplug::Web::Corpus::Corpora($user);
    my $str = &start_multipart_form;
    $str.='corpora: ';
    $str.=&popup_menu(-name=> 'c',-values => [sort keys %{$corpora}]);
    $str.= &submit(-name => 'select');
    $str.= &endform;
    return $str;
}


#------------------------------------------------------------
# sentence-align all bitexts in a given corpus

sub AlignAllDocuments{
    my ($user,$corpus)=@_;
    my $config='./systems/align/sent';

    my %docs;
    my %aligned;
    my $CorpusData=&Uplug::Web::Corpus::CorpusDocuments($user,$corpus);
    my $html;
    foreach my $c (keys %{$CorpusData}){
	if ($$CorpusData{$c}{language}=~/^(.+)\-(.+)$/){   # aligned corpora
	    $aligned{$$CorpusData{$c}{corpus}}{$1}{$2}=1;  # (save lang pairs)
	    next;
	}
	if ($$CorpusData{$c}{status}!~/(tag|tok|chunk)/){  # check status
	    $html.="$c is not tokenized yet! Run pre-processing first!".&br();
	    next;
	}
	$docs{$$CorpusData{$c}{corpus}}{$$CorpusData{$c}{language}}=$c;
    }
    my $count=0;
    foreach my $c (keys %docs){
	my @lang=sort keys %{$docs{$c}};
	while (@lang){
	    my $s=shift(@lang);
	    foreach my $t (@lang){
		if ($aligned{$c}{$s}{$t}){next;}   # skip if already aligned!
		if ($aligned{$c}{$t}{$s}){next;}   # (even if source->target)
		my %para=('input:source text:stream name' => $docs{$c}{$s},
			  'input:target text:stream name' => $docs{$c}{$t});
		&Uplug::Web::Process::MakeUplugProcess($user,$corpus,
						       $config,\%para);
		$count++;
	    }
	}
    }
    return $html.
	&h3("$count sentence alignment processes added to the queue!");
}

sub Process{
    my $query=shift;
    my ($user,$corpus,$name,$params)=@_;

    if (not defined $corpus){              # if no corpus selected:
	return &SelectCorpusForm($user);   #   return corpus-select-form
    }
    if (not defined $name){$name='main';}  # default-module = main

    #-----------------------------------------------
    # 'submit'
    #     create a uplug-process in the process-queue

    if ((ref($params) eq 'HASH') and (defined $$params{submit})){
	my $proc=&Uplug::Web::Process::MakeUplugProcess($user,$corpus,
							$name,$params);
	my $html="job $proc added to queue!<hr />";
	$html.=&UplugSystemForm($query,$user,$corpus,$name);
	return $html;
    }

    #-----------------------------------------------
    # 'save'
    #    save configuration

    elsif ((ref($params) eq 'HASH') and (defined $$params{save})){
	if (&Uplug::Web::Process::SaveUplugSettings($user,$name,$params)){
	    return 
#		&h3($name).
		&UplugSystemForm($query,$user,$corpus,$name).
		&p().&b('settings saved!');
	}
    }

    #-----------------------------------------------
    # 'reset'
    #    restore default parameters

    elsif ((ref($params) eq 'HASH') and (defined $$params{reset})){
	&Uplug::Web::Process::ResetUplugSettings($user,$name,$params);
    }
    return &UplugSystemForm($query,$user,$corpus,$name);
}


###################################################################



sub ProcessTable{
    my $query=shift;
    my $user=shift;
    my $type=shift;
    my $process=shift;
    my @actions=@_;

    my $url=&Uplug::Web::AddUrlParam($query,'y',$type);
    my $html;
    if (defined $user){$html=&h3($type);}
    else{$html=&h3($type.' '.&ActionLinks($url,'clear'));}
    my @proc=&Uplug::Web::Process::GetProcesses($type);
    if (not @proc){
	return "No process in $type-processes-stack!".&br();
    }
    my @rows;
    my $count=0;
    foreach (@proc){
	$count++;
	chomp;
	my ($u,$p,@c)=split(/\:/);
	if ((defined $user) and ($user ne $u)){next;}
	$url=&Uplug::Web::AddUrlParam($url,'p',$p);
	$url=&Uplug::Web::AddUrlParam($url,'u',$u);
	push (@rows,
	      &td([$count.')']).
	      &th([$u]).
	      &td([$p.&Uplug::Web::ActionLinks($url,@actions)]));
	if ($process eq $p){
	    push (@rows,&td(['',@c]));
	}
    }
    return $html.&table({},caption(''),&Tr(\@rows));
}

sub ShowProcessInfo{
    my $query=shift;
    my $user=shift;
    my $process=shift;
    my $admin=shift;
    my $html;

    if (not $admin){
	$html.= &ProcessTable($query,$user,'todo',$process,'view','remove');
	$html.= &ProcessTable($query,$user,'queued',$process,'view');
	$html.= &ProcessTable($query,$user,'working',$process,'view');
	$html.= &ProcessTable($query,$user,'done',$process,'view','remove');
	$html.= &ProcessTable($query,$user,'failed',$process,
			      'view','remove','restart');
	return $html;
    }

    #-----------------------------------
    # administrator view!!!
    #
    $html.= &ProcessTable($query,undef,'todo',$process,'view','remove');
    $html.= &ProcessTable($query,$user,'queued',$process,'view','remove');
    $html.= &ProcessTable($query,undef,'working',$process,'view','remove');
    $html.= &ProcessTable($query,undef,'done',$process,
			  'view','remove','restart');
    $html.= &ProcessTable($query,undef,'failed',$process,
			  'view','remove','restart');
    return $html;
}



###################################################################





sub MakeSubmoduleLinks{
    my $url=shift;
    my $user=shift;
    my $module=shift;
    my @mod=&Uplug::Web::Process::GetSubmodules($user,$module);

    my @links=();
    while (@mod){
	my $m=shift(@mod);
	$m=~s/^(\S+)\s.*$/$1/;
	my $n=shift(@mod);
	my $query=&AddUrlParam($url,'m',$m);
	push (@links,&a({-href => $query},$n));
    }
    return wantarray ? @links : join &br(),@links;
}


sub UplugSystemForm{
    my $url=shift;
    my $user=shift;
    my $corpus=shift;
    my $name=shift;

    my %config;
    if (not &Uplug::Web::Process::GetConfiguration(\%config,$user,$name)){
	print "Cannot find $name!",&p();
	return undef;
    }

    my $shortcuts=$config{shortcuts};
    if (ref($config{arguments}) eq 'HASH'){
	$shortcuts=$config{arguments}{shortcuts};
    }

    my $back=&a({-href=>'javascript:history.go(-1)'},'back');
    my $html.=$config{description}.&p();
#    $html=~s/\n/\<br\>/gs;
#    $html=~s/ /\&nbsp\;/gs;
    if (ref($config{module}) eq 'HASH'){
	if (defined $config{module}{name}){
	    $html=&h3($config{module}{name}).$html;
	}
	else{$html=&h3($name).$html;}
	$html.=&MakeSubmoduleLinks($url,$user,$config{module}).&p();
    }

    my $form= &startform;
    my ($widgets,$msg)=
	&MakeWidgetForm($user,$corpus,$config{widgets},\%config,$shortcuts);
    if (not $widgets){return $back.&p().$msg.$html;}
    $form.= $widgets;
    $form.= &p();
    $form.= &submit(-name => 'reset',-value => 'reset');
    $form.= &submit(-name => 'save',-value => 'save settings');
    if (ref($config{widgets}{input}) eq 'HASH'){
	if (keys %{$config{widgets}{input}}){
	    $form.= &submit(-name => 'submit',-value => 'add job');
	}
    }
    $form.= &endform;
    return $back.$html.$form;
}

sub MakeWidgetForm{
    my $user=shift;
    my $corpus=shift;
    my $config=shift;
    my $defaults=shift;
    my $shortcuts=shift;
    my $menu=shift;

    if (ref($config) ne 'HASH'){return;}

    my @rows=();
    foreach my $p (sort keys %{$config}){
	my $name=$p;
	if (defined $menu){$name="$menu:$p";}
	my $def;
	if (ref($defaults) eq 'HASH'){$def=$$defaults{$p};}
	if (ref($$config{$p}) eq 'HASH'){
	    push (@rows,&th([$p]));
	    my ($form,$msg)=&MakeWidgetForm($user,
					    $corpus,
					    $$config{$p}, # sub-menu config
					    $def,         # default value
					    $shortcuts,   # shortcuts hash
					    $name);       # sub-menu name
	    if (not $form){return (undef,$msg);}
	    push (@rows,&td([$form]));
	}
	else{
	    if (ref($shortcuts) eq 'HASH'){
		my ($short)=grep ($$shortcuts{$_} eq $name,keys %{$shortcuts});
		if ($short){$name='-'.$short;}
	    }
	    my ($widget,$msg)=&MakeWidget($user,$corpus,
					  $name,$$config{$p},$def);
	    if (not $widget){return (undef,$msg);}
	    push (@rows,&td([$p,$widget]));
	}
    }
    if (not @rows){return (undef,'empty?!');}
    return (&table({},&Tr(\@rows)));
}


sub MakeWidget{
    my $user=shift;
    my $corpus=shift;
    my $name=shift;
    my $config=shift;
    my $default=shift;

    if ($config=~/stream\s*\((.*)\)/){
	my %para=split(/\s*[\,\=]\s*/,$1);
#	my @streams=&Uplug::Web::Corpus::GetCorpusStreams($user,%para);
	my @streams=
	    &Uplug::Web::Corpus::MatchingDocuments($user,$corpus,%para);
	if (not @streams){
	    my $msg="No appropriate document found in this corpus ($corpus)!";
	    $msg.=&p();
	    foreach (keys %para){
		$msg.="$_=$para{$_}".&br;
	    }
	    return (undef,$msg);
	}
	return (&td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort @streams])]));
    }
    elsif($config=~/optionmenu\s*\((.*)\)/){
	my @options=split(/\s*\,\s*/,$1);
	return (&td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort @options])]));
    }
    elsif($config=~/scale\s*\((.*)\)/){
	my ($start,$end,$steps,$bigsteps)=split(/\s*\,\s*/,$1);
	my @options;my $i;
	for ($i=$start;$i<=$end;$i+=$bigsteps){
	    push (@options,$i);
	}
	if ((defined $default) and (not grep ($_==$default,@options))){
	    push (@options,$default);
	}
	return (&td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort {$a <=> $b} @options])]));
    }
    elsif($config=~/checkbox/){
	return (&radio_group(-name=>$name,
			     -values=>['0','1'],
                             -default=>$default,
			     -labels=> {'1' => 'on','0' => 'off'}));

#	if ($default){
#	    return &checkbox(-name=>$name,
#			     -checked=>'checked',
#			     -value=>'1',-label=>'');
#	}
#	return &checkbox(-name=>$name,-value=>'1',-label=>'');
    }
    return (&td([&textfield(-name => $name,-default=>$default)]));
}








sub DelUrlParam{
    my ($url,$name)=@_;

    $url=~s/([\;\?])$name\=[^\;]*(\;|\Z)/$1/;
    return $url;
}




sub AddUrlParam{
    my ($url,$name,$val)=@_;
    $val=escape($val);
    if ($url!~/[\?\;]$name\=/){
	if ($url!~/\?/){$url.="\?$name=$val";}
	else{$url.="\;$name=$val";}
    }
    else{$url=~s/$name\=[^\;]*(\;|\Z)/$name=$val$1/;}
    return $url;
}

sub ActionLinks{
    my $url=shift;
    my @action;
    if (ref($_[0]) eq 'ARRAY'){@action=@{$_[0]};}
    else{@action=@_;}

    my @links;
    foreach (@action){
	push (@links,'['.&a({-href => &AddUrlParam($url,'t',$_)},$_).']');
    }
    return wantarray ? @links : join '',@links;
}


sub TaskLinks{

    my %para=();
    my $url;
    my $key='t';                                      # default url-attr: t

    if (ref($_[0]) eq 'HASH'){                        # first arg = HASH ref?
	%para=%{$_[0]};shift;                         # -> parameter hash
	$url=$para{url};                              #    get URL parameter
    }
    else{                                             # otherwise:
	$url=shift;                                   #    URL=first arg
	$key=shift;                                   #    URL-attr=second arg
    }

    if (exists $para{key}){$key=$para{key};}          # check key parameter
    my $selected=$para{selected};                     # selected 'task'

    my @tasks;                                        # tasks:
    if (ref($_[0]) eq 'ARRAY'){@tasks=@{$_[0]};}      #  array reference
    else{@tasks=@_;}                                  #  or all remaining args

    my @links;
    foreach my $t (@tasks){
	if ($t eq $selected){
	    push (@links,'['.$t.']');
	}
	elsif (defined $key){
	    push (@links,'['.&a({-href=>&AddUrlParam($url,$key,$t)},$t).']');
	}
	else{
	    push (@links,'['.&a({-href=>$url},$t).']');
	}
    }
    return wantarray ? @links : join '',@links;
}






# http://ftp.ics.uci.edu/pub/ietf/http/related/iso639.txt
# Technical contents of ISO 639:1988 (E/F)
# "Code for the representation of names of languages".
#
# Typed by Keld.Simonsen@dkuug.dk 1990-11-30  <ftp://dkuug.dk/i18n/ISO_639>
# Minor corrections, 1992-09-08 by Keld Simonsen
# Sundanese corrected, 1992-11-11 by Keld Simonsen
# Telugu corrected, 1995-08-24 by Keld Simonsen
# Hebrew, Indonesian, Yiddish corrected 1995-10-10 by Michael Everson
# Inuktitut, Uighur, Zhuang added 1995-10-10 by Michael Everson
# Sinhalese corrected, 1995-10-10 by Michael Everson
# Faeroese corrected to Faroese, 1995-11-18 by Keld Simonsen
# Sangro corrected to Sangho, 1996-07-28 by Keld Simonsen
# 
# Two-letter lower-case symbols are used.
# The Registration Authority for ISO 639 is Infoterm, Osterreichisches
# Normungsinstitut (ON), Postfach 130, A-1021 Vienna, Austria.

my %ISO639=( qw(
aa Afar
ab Abkhazian
af Afrikaans
am Amharic
ar Arabic
as Assamese
ay Aymara
az Azerbaijani

ba Bashkir
be Byelorussian
bg Bulgarian
bh Bihari
bi Bislama
bn Bengali;Bangla
bo Tibetan
br Breton

ca Catalan
co Corsican
cs Czech
cy Welsh

da Danish
de German
dz Bhutani

el Greek
en English
eo Esperanto
es Spanish
et Estonian
eu Basque

fa Persian
fi Finnish
fj Fiji
fo Faroese
fr French
fy Frisian

ga Irish
gd Scots_Gaelic
gl Galician
gn Guarani
gu Gujarati

ha Hausa
he Hebrew
hi Hindi
hr Croatian
hu Hungarian
hy Armenian

ia Interlingua
id Indonesian
ie Interlingue
ik Inupiak
is Icelandic
it Italian
iu Inuktitut

ja Japanese
jw Javanese

ka Georgian
kk Kazakh
kl Greenlandic
km Cambodian
kn Kannada
ko Korean
ks Kashmiri
ku Kurdish
ky Kirghiz

la Latin
ln Lingala
lo Laothian
lt Lithuanian
lv Latvian,Lettish

mg Malagasy
mi Maori
mk Macedonian
ml Malayalam
mn Mongolian
mo Moldavian
mr Marathi
ms Malay
mt Maltese
my Burmese

na Nauru
ne Nepali
nl Dutch
no Norwegian

oc Occitan
om (Afan)Oromo
or Oriya

pa Punjabi
pl Polish
ps Pashto,Pushto
pt Portuguese

qu Quechua

rm Rhaeto-Romance
rn Kirundi
ro Romanian
ru Russian
rw Kinyarwanda

sa Sanskrit
sd Sindhi
sg Sangho
sh Serbo-Croatian
si Sinhalese
sk Slovak
sl Slovenian
sm Samoan
sn Shona
so Somali
sq Albanian
sr Serbian
ss Siswati
st Sesotho
su Sundanese
sv Swedish
sw Swahili

ta Tamil
te Telugu
tg Tajik
th Thai
ti Tigrinya
tk Turkmen
tl Tagalog
tn Setswana
to Tonga
tr Turkish
ts Tsonga
tt Tatar
tw Twi

ug Uighur
uk Ukrainian
ur Urdu
uz Uzbek

vi Vietnamese
vo Volapuk

wo Wolof

xh Xhosa

yi Yiddish
yo Yoruba

za Zhuang
zh Chinese
zu Zulu
		));


sub iso639_menu{
    my $name=shift;
    my $default=shift;
    return &popup_menu(-name=>'lang',
		       -values => [sort {$ISO639{$a} cmp $ISO639{$b}} 
				   keys %ISO639], 
		       -labels => \%ISO639,
		       -default => $default);
}



my %Encodings=();

if ($]>=5.008){
    eval { require Encode; };
    if (not $@){
	my @enc=Encode->encodings(":all");
	foreach (@enc){$Encodings{$_}=$_;}
    }
}
else{
    %Encodings=('utf8' => 'Unicode UTF8',
		'iso-8859-1' => 'iso-8859-1 (latin 1)',
		'iso-8859-2' => 'iso-8859-2 (latin 2)');
}



sub encodings_menu{
    my $name=shift;
    my $default=shift;
    return &popup_menu(-name=>$name,
		       -values => [sort {$Encodings{$a} cmp $Encodings{$b}} 
				   keys %Encodings], 
		       -labels => \%Encodings,
		       -default => $default);
}










#############################################################################
#############################################################################
#############################################################################
#
# classes for reading datafiles
#
# Uplug::Web::Data ......... read text files (e.g. XML as plain text)
# Uplug::Web::Bitext ....... read sentence aligned bitexts
# Uplug::Web::BitextLinks .. read word aligned bitexts
#

package Uplug::Web::Data;

use CGI qw/:standard escapeHTML escape/;

sub new{
    my $class=shift;
    my $priv=shift;
    my $file=shift;
    my $self={};
    bless $self,$class;
    $self->{FILE}=$file;
    $self->{PRIV}=$priv;
    $self->{STYLES}=&Uplug::Web::AccessMode($priv,$class);
#    print @{$self->{STYLES}};
#    print $self->{STYLES};
    return $self;
}

sub view{
    my $self=shift;
    my ($url,$style,$pos)=@_;

    if (not defined $style){$style='xml';}

    my $file=$self->{FILE};
    open F,"< $file";
    binmode(F,":utf8");
    if (defined $pos){
	seek (F,$pos,0);
    }
    $self->{STYLE}=$style;
    $self->{POS}=$pos;

    my $html='';
    my $skip=0;
    my $count=0;
    while (<F>){
#	if ($skip<$pos){$skip++;next;}
	$html.=escapeHTML($_);
	$html=~s/\n/\<br\>/gs;
	$html=~s/\s/\&nbsp\;\&nbsp\;/gs;
	$count++;
	if ($count>$MAXVIEWLINES){last;}
    }
    $self->{NEXT}=tell(F);
    $self->{COUNT}=$count;
    close F;

    my $links=$self->nextLinks($url);
    return $links.$html.$links;

}

sub edit{                           # no edit defined!
    my $self=shift;                 # (just view the corpus)
    return $self->view(@_);
}



sub nextLinks{
    my $self=shift;
    my $url=shift;

    my $count=$self->{COUNT};
    my $style=$self->{STYLE};
    my $pos=$self->{POS};
    my $NextPos=$self->{NEXT};
    my ($start,$prev,$next,$styles);
    if (ref($self->{STYLES}) eq 'ARRAY'){
	foreach (@{$self->{STYLES}}){
	    if ($style eq $_){next;}
	    my $link=&Uplug::Web::AddUrlParam($url,'s',$_);
	    $styles.=' ['.&a({-href => $link},$_).']';
	}
    }
    if ($styles){$styles='display style: '.$styles.&br();}
    if ($pos>0){
	my $link=&Uplug::Web::AddUrlParam($url,'x',0);
	$link=&Uplug::Web::DelUrlParam($link,'sx');
	$link=&Uplug::Web::DelUrlParam($link,'tx');
	$start='['.&a({-href => $link},'start').']';
	$prev='['.&a({-href=>'javascript:history.go(-1)'},'previous').']';
    }
    if ($count>=$MAXVIEWDATA){
	my $link=&Uplug::Web::AddUrlParam($url,'x',$NextPos);
	if ($self->{'FROMDOC-POS'}>0){
	    $link=&Uplug::Web::AddUrlParam($link,'sx',$self->{'FROMDOC-POS'});
	}
	if ($self->{'TODOC-POS'}>0){
	    $link=&Uplug::Web::AddUrlParam($link,'tx',$self->{'TODOC-POS'});
	}
	$next='['.&a({-href => $link},'next').']';
    }
#    return $styles.&p().$start.&br().$prev.&br().$next.&p();
    return $styles.&p().$start.$prev.$next.&p();
}



#############################################################################
#############################################################################
#
# sentence aligned bitext
#


package Uplug::Web::Bitext;

use CGI qw/:standard escapeHTML escape/;
use vars qw(@ISA);
@ISA = qw( Uplug::Web::Data );


sub new{
    my $class=shift;
    my $self=$class->SUPER::new(@_);
#    $self->{STYLES}=['text','xml'];
    $self->{ROOT}='link';
    return $self;
}


sub view{
    my $self=shift;
    my ($url,$style,$pos,$param)=@_;

    if (not defined $style){$style='xml';}
    $self->{STYLE}=$style;
    $self->{POS}=$pos;
    if (ref($param) eq 'HASH'){
	$self->{'FROMDOC-POS'}=$$param{sx};
	$self->{'TODOC-POS'}=$$param{tx};
    }
#    $self->{PREVIOUS}=$prev;

    my $count;my $fromDoc;my $toDoc;
    if (not $self->readLinks($pos)){return undef;}
    my $seg=$self->readSentLinks($style);
    my $html=$self->nextLinks($url);
    $html.=$seg.&p();
    $html.=$self->nextLinks($url);
    return $html;
}



sub readLinks{
    my $self=shift;
    my ($pos)=@_;

    my $file=$self->{FILE};
    open F,"< $file";
    binmode(F);
    local $/='>';

    my $parser=new XML::Parser(Handlers => {Start => \&XmlStart,
					    End => \&XmlEnd,
					    Default => \&XmlChar});
    my $handle=$parser->parse_start;
    $self->{SENTLINKS}=[];
    $self->{WORDLINKS}=[];
    $handle->{ROOT}=$self->{ROOT};
    &ParseBitextHeader(*F,$handle);      # read bitext header (get src/trg-doc)
    if ($pos>0){seek (F,$pos,0);}        # go to last file position

    my $count;
    while (&ParseXml(*F,$handle)){
	$count++;
	if ($count>$MAXVIEWDATA){last;}
	$self->{NEXT}=tell(F);
	push (@{$self->{SENTLINKS}},$handle->{DATA}->{xtargets});
	if (ref($handle->{SUBDATA}) ne 'HASH'){next;}
	if (ref($handle->{SUBDATA}->{wordLink}) ne 'ARRAY'){next;}
	my $i=$#{$self->{SENTLINKS}};
	foreach (0..$#{$handle->{SUBDATA}->{wordLink}}){
	    if (ref($handle->{SUBDATA}->{wordLink}->[$_]) ne 'HASH'){next;}
	    my $key=$handle->{SUBDATA}->{wordLink}->[$_]->{xtargets};
	    %{$self->{WORDLINKS}->[$i]->{$key}}=
		%{$handle->{SUBDATA}->{wordLink}->[$_]};
	}
    }
    if (not $handle->{FROMDOC}){print "no source document found!";return 0;}
    if (not $handle->{TODOC}){print "no target document found!";return 0;}
    close F;
    $self->{FROMDOC}=$handle->{FROMDOC};
    $self->{TODOC}=$handle->{TODOC};
    $self->{COUNT}=$count;
    return 1;
}



sub readSentLinks{
    my $self=shift;
    my $style=shift;
    my @rows=();
    foreach (@{$self->{SENTLINKS}}){
	push (@rows,$self->readBitextSegment($_,$style));
    }
    $self->{'FROMDOC-POS'}=tell $self->{'FROMDOCHANDLE'};
    $self->{'TODOC-POS'}=tell $self->{'TODOCHANDLE'};
    return &table({},caption(''),&Tr(\@rows));
}


sub readBitextSegment{
    my $self=shift;
    my $link=shift;
    my $style=shift;

    my ($src,$trg)=split(/\;/,$link);
    my @s=split(/\s+/,$src);
    my @t=split(/\s+/,$trg);

    my $srctext=$self->readSegment('FROMDOC',\@s,$style);
    my $trgtext=$self->readSegment('TODOC',\@t,$style);

    my @rows=();
    push (@rows,&th([$src,$trg]));
    push (@rows,&td([$srctext,$trgtext]));
    return @rows;
}


sub readSegment{
    my $self=shift;
    my $doc=shift;
    my $ids=shift;
    my $style=shift;

    if (not ref($self->{$doc.'HANDLE'})){$self->openDocument($doc);}
    my $fh=$self->{$doc.'HANDLE'};
    my $parser=$self->{$doc.'PARSER'};

    my $text='';
    delete $parser->{SUBDATA};
    while (@{$ids} and &ParseXml($fh,$parser,1)){
	if ($$ids[0] eq $parser->{DATA}->{id}){
	    if ($style eq 'text'){$text.=$parser->{HTMLTXT};}
	    else{$text.=$parser->{HTML};}
	    shift(@{$ids});
	}
	else{delete $parser->{SUBDATA};}
	if (not @{$ids}){last;}
    }
    if ($style ne 'text'){
	$text=~s/\n/\<br\>/sg;
	$text=~s/\s/\&nbsp;\&nbsp;/sg;
    }
    return $text;
}

#-------------------------------------------------
# open XML-documents
#   * open the file
#   * create a XML-parser-object
#   * read the XML-header and the XML-root-tag

sub openDocument{
    my $self=shift;
    my $doc=shift;

    open $self->{$doc.'HANDLE'},"< $self->{$doc}";
    $self->{$doc.'EXPAT'}=new XML::Parser(Handlers => {Start   => \&XmlStart,
						       End     => \&XmlEnd,
						       Default => \&XmlChar});
    $self->{$doc.'PARSER'}=$self->{$doc.'EXPAT'}->parse_start();
    $self->{$doc.'PARSER'}->{ROOT}='s';
    $self->{$doc.'PARSER'}->{SUBROOT}='w';

    my $fh=$self->{$doc.'HANDLE'};         # the file handle
    my $parser=$self->{$doc.'PARSER'};     # the XML-parser
    local $/='>';                          # set input boundary to '>'
    my $xml=<$fh>;                         # simply read the XML header
    eval { $parser->parse_more($xml); };   # parse XML-header
    $xml=<$fh>;                            # read the root-tag of the document
    eval { $parser->parse_more($xml); };   # ... and parse it

    if ($self->{$doc.'-POS'}>0){           # go to the last file-position
	seek ($fh,$self->{$doc.'-POS'},0); # (if > 0)
    }
}


#--------------------------------------------
# parse the header of a bitext file
#  * parse XML header and
#  * look for source and target documents

sub ParseBitextHeader{
    my ($fh,$p)=@_;

    delete $p->{DATA};
    delete $p->{OPEN};
    delete $p->{SUBOPEN};
    delete $p->{COMPLETE};
    delete $p->{INSIDE};
    delete $p->{BEFORE};
    delete $p->{INSIDETXT};
    delete $p->{BEFORETXT};
    delete $p->{HTML};
    delete $p->{HTMLTXT};
    delete $p->{FROMDOC};
    delete $p->{TODOC};

    while (<$fh>){
 	eval { $p->parse_more($_); };
	if ($@){print "problems when parsing ($@)!\n";return 0;}
	if ($p->{FROMDOC} and $p->{TODOC}){return 1;}
    }
    return 0;
}


#------------------------------------------------
# parse XML until a complete ROOT-subtree is found

sub ParseXml{
    my ($fh,$p,$keepSubData)=@_;

    delete $p->{DATA};
    delete $p->{OPEN};
    delete $p->{SUBOPEN};
    delete $p->{COMPLETE};
    delete $p->{INSIDE};
    delete $p->{BEFORE};
    delete $p->{INSIDETXT};
    delete $p->{BEFORETXT};
    delete $p->{HTML};
    delete $p->{HTMLTXT};
    if (not $keepSubData){delete $p->{SUBDATA};}

    local $/='>';                              # set input boundary to '>'
    my $pos=tell $fh;                          # save the current file position
    while (<$fh>){                             # go to next ROOT-tag
	if (/\<$p->{ROOT}(\s|\>)/){last;}      # (avoid not welformed XML
	$pos=tell $fh;                         #  when jumping within the file)
    }
    seek ($fh,$pos,0);

    while (<$fh>){                             # read from the file
 	eval { $p->parse_more($_); };          # and parse the XML-string
	if ($@){
	    s/</&lt;/g;s/</&gt;/g;
	    print "problems when parsing ($@)! XML-string: $_\n";
	    return 0;
	}
	if ($p->{COMPLETE}){return 1;}
    }
    return 0;
}


#-----------------------------------------------------------------------
# XML-parser subroutines
#   XmlStart .... XML-start-tag
#   XmlEnd ...... XML-end-tag
#   XmlChar ..... everything else

sub XmlStart{
    my ($p,$e,%attr)=@_;
    my $text=$p->recognized_string();
    if ($e eq $p->{ROOT}){
	$p->{OPEN}=1;
	%{$p->{DATA}}=%attr;
    }
    if ($p->{OPEN}){
	$p->{INSIDE}.=$text;
	$p->{HTML}.=&escapeHTML($text);
	if ($e ne $p->{ROOT}){
	    if (not ref($p->{SUBDATA})){$p->{SUBDATA}={};}
	    if (not ref($p->{SUBDATA}->{$e})){$p->{SUBDATA}->{$e}=[];}
	    my $i=@{$p->{SUBDATA}->{$e}};
	    %{$p->{SUBDATA}->{$e}->[$i]}=%attr;
	    if ($e eq $p->{SUBROOT}){
		$p->{SUBOPEN}=1;
		$p->{SUBDATA}->{$e}->[$i]->{'#text'}='';
	    }
	}
    }
    else{$p->{BEFORE}.=$p->recognized_string();}
    if (defined $attr{fromDoc}){
	$p->{FROMDOC}=$attr{fromDoc};
    }
    if (defined $attr{toDoc}){
	$p->{TODOC}=$attr{toDoc};
    }
}

sub XmlEnd{
    my ($p,$e)=@_;
    my $text=$p->recognized_string();
    if ($p->{OPEN}){
	$p->{INSIDE}.=$p->recognized_string();
	$p->{HTML}.=&escapeHTML($text);
    }
    if ($e eq $p->{ROOT}){
	delete $p->{OPEN};
	$p->{COMPLETE}=1;
    }
    elsif ($e eq $p->{SUBROOT}){
	delete $p->{SUBOPEN};
    }
}

sub XmlChar{
    my ($p)=@_;
    my $text=$p->recognized_string();
    if ($p->{OPEN}){
	$p->{INSIDE}.=$text;
	$p->{INSIDETXT}.=$text;
	$p->{HTML}.=&escapeHTML($text);
	$p->{HTMLTXT}.=&escapeHTML($text);
	if ($p->{SUBOPEN}){
	    $p->{SUBDATA}->{$p->{SUBROOT}}->[-1]->{'#text'}.=$text;
	}
    }
    else{
	$p->{BEFORETXT}.=$text;
	$p->{BEFORE}.=$text;
    }
}




#############################################################################
#############################################################################
#
# word-aligned bitexts
#


package Uplug::Web::BitextLinks;

use CGI qw/:standard escapeHTML escape/;
use vars qw(@ISA);
@ISA = qw( Uplug::Web::Bitext );

sub new{
    my $class=shift;
    my $self=$class->SUPER::new(@_);
#    $self->{STYLES}=['text','xml','matrix','edit'];
    $self->{ROOT}='link';
    return $self;
}



sub view{
    my $self=shift;
    my ($url,$style,$pos,$prev,$params,$links)=@_;

    if (ref($params) eq 'HASH'){
	if ($$params{edit} eq 'change'){
	    Uplug::Web::Data::ChangeWordLinks($self->{FILE},$links,$params);
	      $url=Uplug::Web::DelUrlParam($url,'seg');
	      $url=Uplug::Web::DelUrlParam($url,'links');
	      $url=Uplug::Web::DelUrlParam($url,'edit');
	  }
    }

    if (not $style){$style='text';}
    if ($style eq 'xml'){
	return $self->Uplug::Web::Data::view($url,$style,$pos,$prev);
    }
    return $self->SUPER::view($url,$style,$pos,$prev);
}



sub readSentLinks{
    my $self=shift;
    my $style=shift;

    my @rows=();
    foreach my $l (0..$#{$self->{SENTLINKS}}){
	push (@rows,$self->readBitextSegment($self->{SENTLINKS}->[$l],
					     $self->{WORDLINKS}->[$l],
					     $style));
	if ($style eq 'text'){
	    push (@rows,$self->viewWordLinks($self->{WORDLINKS}->[$l]));
	}
    }
    $self->{'FROMDOC-POS'}=tell $self->{'FROMDOCHANDLE'};
    $self->{'TODOC-POS'}=tell $self->{'TODOCHANDLE'};
    if ($style=~/(matrix|edit)/){return join '<hr>',@rows;}
    else{return &table({},caption(''),&Tr(\@rows));}
}

sub viewWordLinks{
    my $self=shift;
    my $links=shift;
    if (ref($links) ne 'HASH'){$links={};}
    my @rows=();
    foreach (sort {$$links{$b}{certainty} <=> $$links{$a}{certainty}} 
	     keys %{$links}){
	if (ref($$links{$_}) ne 'HASH'){next;}
	my ($src,$trg)=split(';',$$links{$_}{lexPair});
	my $score=sprintf "%1.5f",$$links{$_}{certainty};
	push (@rows,
	      &td({-align => 'right'},[$src.'&nbsp;&nbsp;']).
	      &td(['&nbsp;&nbsp;'.$trg,$score]))
    }
    return @rows;
}


sub readBitextSegment{
    my $self=shift;
    my $sentLink=shift;
    my $wordLinks=shift;
    my $style=shift;

    my ($src,$trg)=split(/\;/,$sentLink);
    my @s=split(/\s+/,$src);
    my @t=split(/\s+/,$trg);

    my $srctext=$self->readSegment('FROMDOC',\@s,$style);
    my $trgtext=$self->readSegment('TODOC',\@t,$style);

    if ($style eq 'matrix'){
	return $self->linkMatrix($wordLinks,$sentLink);
    }
    if ($style eq 'edit'){
	return $self->linkMatrix($wordLinks,$sentLink,1);
    }
    else{
	my @rows=();
	push (@rows,&th([$src,$trg]));
	push (@rows,&td([$srctext,$trgtext]));
	return @rows;
    }
}




sub linkMatrix{
    my $self=shift;
    my ($links,$id,$form)=@_;

    my $src=$self->{FROMDOCPARSER};
    my $trg=$self->{TODOCPARSER};
    if (ref($links) ne 'HASH'){$links={};}

    my $srcTok=$src->{SUBDATA}->{$src->{SUBROOT}};
    my $trgTok=$trg->{SUBDATA}->{$trg->{SUBROOT}};

    my %matrix=();
    foreach (keys %{$links}){
	my ($srcX,$trgX)=split(/\;/,$_);
	my @src=split(/\+/,$srcX);
	my @trg=split(/\+/,$trgX);
	foreach my $s (@src){
	    foreach my $t (@trg){
		$matrix{$s}{$t}=1;
	    }
	}
    }
    my @rows=();
    push (@rows,&th([$id]));
    foreach my $t (0..$#{$trgTok}){
	$rows[0].=&td($trgTok->[$t]->{'#text'});
    }
    foreach my $s (0..$#{$srcTok}){
	my $row=&td($srcTok->[$s]->{'#text'});
	foreach my $t (0..$#{$trgTok}){
	    my $value="$srcTok->[$s]->{id}:$trgTok->[$t]->{id}";
	    my $cell='';
	    if ($matrix{$srcTok->[$s]->{id}}{$trgTok->[$t]->{id}}){
		if ($form){
		    $cell=&checkbox(-name=>'links',-checked=>'checked',
				    -value=>$value,-label=>'');
		}
		$row.=&td({},[$cell]);
	    }
	    else{
		if ($form){
		    $cell=&checkbox(-name=>'links',-value=>$value,-label=>'');
		}
		$row.=&th({},[$cell]);
	    }
	}
	push (@rows,$row);
    }
    my $html='';
    if ($form){
	$html.=&startform();
	$html.=hidden(-name=>'seg',-default=>[$id]);
    }
    $html.='<div class="matrix">';
    $html.=&table({},caption(''),&Tr(\@rows));
    $html.="</div>\n";
    if ($form){
	$html.=&p().&submit(-name => 'edit',-value => 'change');
	$html.=&endform();
    }
    return $html;
}




1;
