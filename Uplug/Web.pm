
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
package Uplug::Web;

use strict;
use Exporter;
use CGI qw/:standard escapeHTML escape/;
use vars qw(@ISA @EXPORT);
use Uplug::Web::Corpus;
use Uplug::Web::Process;
use Uplug::Web::User;
use XML::Parser;

@ISA=qw( Exporter);
@EXPORT = qw( $CSS &ShowUserInfo &AddUrlParam &ActionLinks );

our $CSS = "/~joerg/uplug2/menu.css";
my $CWBREG='/corpora/OPUS/uplug2-cwb/reg/';
my $MAXVIEWLINES=40;
my $MAXVIEWDATA=10;
my $GUNZIP='/usr/bin/gzip -cd';      # gunzip to STDOUT!!!
binmode(STDOUT, ":utf8");            # set UTF8 for STDOUT

my %DataAccess=
    (admin => {corpus => ['info','view','send','remove'],
	       user => ['info','edit','remove']},
     user => {corpus => ['info','view','send','remove'],
	      'Uplug::Web::Corpus' => ['xml'],
	      'Uplug::Web::Bitext' => ['text','xml'],
	      'Uplug::Web::BitextLinks' => ['text','xml','matrix','edit'],
	      user => ['info','edit']},
     all => {corpus => ['info','view'],
	     'Uplug::Web::Corpus' => ['xml'],
	     'Uplug::Web::Bitext' => ['text','xml'],
	     'Uplug::Web::BitextLinks' => ['text','xml','matrix'],
	     user => ['info']});



sub AccessMode{
    my $user=shift;
    my $owner=shift;
    my $type=shift;

    if ($user eq $Uplug::Web::User::UplugAdmin){
	if (defined $DataAccess{admin}{$type}){
	    return $DataAccess{admin}{$type};
	}
    }
    if ($user eq $owner){return $DataAccess{user}{$type};}
    else{return $DataAccess{all}{$type};}
#    print $DataAccess{user}{$type};

}

sub ShowUserInfo{
    my $query=shift;
    my $UserData=shift;
    my $user=shift;
    my $name=shift;

    my @rows=();
    foreach my $u (keys %{$UserData}){
	my $url=&AddUrlParam($query,'name',$u);
	if (keys %{$$UserData{$u}} > 1){
	    push (@rows,
		  &th([$u]).
		  &td(&ActionLinks($url,&AccessMode($user,$u,'user'))));
	    foreach (keys %{$$UserData{$u}}){
		push (@rows,td([$_,$$UserData{$u}{$_}]));
	    }
	}
	else{
	    push (@rows,
		  &th([$u]).
		  &td(&ActionLinks($url,&AccessMode($user,$u,'user'))));
	}
    }
    return &table({},caption(''),&Tr(\@rows));
}


#--------------------------------------------------------------------


sub CorpusIndexerForm{
    my ($user)=@_;
    my %corpora=();
    &GetCorpusData(\%corpora,$user);
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

sub CorpusQueryForm{
    my ($user,$owner,$corpus,$lang,$aligned)=@_;


    my %index=();
    &Uplug::Web::Corpus::GetIndexedCorpora(\%index,$owner,$corpus);

    my $form= &startform();
    my $query;
    my @row=();

    if (not $owner){
#	if ((scalar keys %index) == 1){($owner)=each %index;}
#	else{
	    $form.='Select a user!'.&p();;
	    push (@row,&popup_menu(-name=> 'owner',
				   -values => [sort keys %index]));
#	}
    }
    elsif (not $corpus){
	$form.='Select a corpus!'.&p();
	push (@row,$owner.' '.&hidden(-name=>'owner',-default=>[$owner]));
	push (@row,&popup_menu(-name=> 'corpus',
			       -values => [sort keys %{$index{$owner}}]));
    }
    elsif (not $lang){
	$form.='Select a language!'.&p();
	push (@row,$owner.' '.&hidden(-name=>'owner',-default=>[$owner]));
	push (@row,$corpus.' '.&hidden(-name=>'corpus',-default=>[$corpus]));
	push (@row,&popup_menu(-name=> 'lang',
			       -values => 
			       [sort keys %{$index{$owner}{$corpus}}]));
    }
    else{
	$form.='Type a query using the ';
	$form.=&a({-href=>'http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQPSyntax.html'},'CQP syntax');
	$form.=' of the ';
	$form.=&a({-href=>'http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/index.html'},'Corpus Work Bench');
	$form.='!'.&p();
	push (@row,$owner.' '.&hidden(-name=>'owner',-default=>[$owner]));
	push (@row,$corpus.' '.&hidden(-name=>'corpus',-default=>[$corpus]));
	push (@row,$lang.' '.&hidden(-name=>'lang',-default=>[$lang]));

	$query=&textfield(-size=>'50',-name => 'query',
			  -default=>'[word="Government" & pos="NN.*"]').&br();
	$query.='cqp-query (';
	$query.=&a({-href=>'http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQPSyntax.html'},'cqp syntax').',';
	$query.=&a({-href=>'http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQPExamples.html'},'sample queries').',';
	$query.=&a({-href=>'http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/index.html'},'cwb');
	$query.=')'.&p();
	if (ref($index{$owner}{$corpus}{$lang}{align}) eq 'ARRAY'){
	    my @lang=sort @{$index{$owner}{$corpus}{$lang}{align}};
	    my $align=&checkbox_group(-name=>'alg',
				      -values=>\@lang,
				      -default=>\@lang);
	    push (@row,$align);
	    $query.=&radio_group(-name=>'style',
				 -values=>['vertical','horizontal'],
				 -default=>'vertical',
				 -labels=>{vertical=>'vertical',
					   horizontal=>'horizontal'});
	}

    }
    my @head=('&nbsp;user','&nbsp;corpus','&nbsp;language','&nbsp;alignment');
    $form.=&table({},caption(''),&Tr([&th(\@head),&td(\@row)]));
    $form.=&p().$query.&p();
    $form.= &submit(-name => 'action',-value => 'select');
    $form.= &endform();
    return $form;
}


sub CorpusQuery{

    use lib ('/home/staff/joerg/user_local/lib/perl5/site_perl/5.8.0/');
    use WebCqp::Query;

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



#-----------------------------
# ShowCorpusInfo:
#    * list all corpora of a certain owner
#    * if no owner specified: list all corpora of all users

sub ShowCorpusInfo{
    my $user=shift;
    my $owner=shift;
    my $corpus=shift;
    my $query=shift;

    my %CorpusData=();

    #----------------------------------------
    # no owner: get corpora of all users!

    if (not $owner){
	my %UserData=();
	&Uplug::Web::User::ReadUserInfo(\%UserData);
	my $html='';
	foreach my $u (keys %UserData){
	    $html.=&h3($u);
	    $html.=&ShowCorpusInfo($user,$u,$corpus,$query);
	}
	return $html;
    }
    #----------------------------------------

    &GetCorpusData(\%CorpusData,$owner);
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
		    my $url=&AddUrlParam($query,'corpus',$n);
		    $url=&AddUrlParam($url,'owner',$owner);
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
    &GetCorpusData(\%CorpusData,$user);

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
    my ($user,$owner,$name,$url,$pos,$style,$params,$links)=@_;

    my $html;
    my %CorpusData=&Uplug::Web::Corpus::GetCorpusInfo($owner,$name);
    if (not defined $CorpusData{file}){return undef;}
    my $file=$CorpusData{file};
    my $corpus;
    if ($CorpusData{format}=~/align/){
	if ($CorpusData{status}=~/word/){
	    $corpus=new Uplug::Web::BitextLinks($user,$owner,$file);
	}
	else{
	    $corpus=new Uplug::Web::Bitext($user,$owner,$file);
	}
    }
    else{$corpus=new Uplug::Web::Corpus($user,$owner,$file);}
    return $corpus->view($url,$style,$pos,$params,$links);
}


###################################################################

sub ShowApplications{
    my $query=shift;
    my ($user,$name,$params)=@_;
    if (not defined $name){$name='main';}
    if ((ref($params) eq 'HASH') and (defined $$params{submit})){
	my $proc=&Uplug::Web::Process::MakeUplugProcess($user,$name,$params);
	return "job $proc added to queue!";
    }
    elsif ((ref($params) eq 'HASH') and (defined $$params{save})){
	if (&Uplug::Web::Process::SaveUplugSettings($user,$name,$params)){
	    return 
		&h3($name).
		&Uplug::Web::UplugSystemForm($query,$user,$name).
		&p().'settings saved!';
	}
    }
    elsif ((ref($params) eq 'HASH') and (defined $$params{reset})){
	&Uplug::Web::Process::ResetUplugSettings($user,$name,$params);
    }
    return &Uplug::Web::UplugSystemForm($query,$user,$name);
}


###################################################################



sub ProcessTable{
    my $query=shift;
    my $user=shift;
    my $type=shift;
    my $process=shift;
    my @actions=@_;

    my $url=&Uplug::Web::AddUrlParam($query,'type',$type);
    my $html;
    if (defined $user){$html=&h3($type);}
    else{$html=&h3($type.' '.&ActionLinks($url,'clear'));}
    my @proc=&Uplug::Web::Process::GetProcesses($type);
    if (not @proc){
	return "No process in $type stack!".&br();
    }
    my @rows;
    my $count=0;
    foreach (@proc){
	$count++;
	chomp;
	my ($u,$p,@c)=split(/\:/);
	if ((defined $user) and ($user ne $u)){next;}
	$url=&Uplug::Web::AddUrlParam($url,'process',$p);
	$url=&Uplug::Web::AddUrlParam($url,'user',$u);
	push (@rows,
	      &td([$count.')']).
	      &th([$u]).
	      &td([$p.&Uplug::Web::ActionLinks($url,@actions)]));
	if ($process eq $p){
	    push (@rows,&td(['','',@c]));
	}
    }
    return $html.&table({},caption(''),&Tr(\@rows));
}

sub ShowProcessInfo{
    my $query=shift;
    my $user=shift;
    my $process=shift;

    if (defined $user){
	my $html.= &ProcessTable($query,$user,'todo',$process,'view','remove');
	$html.= &ProcessTable($query,$user,'queued',$process,'view');
	$html.= &ProcessTable($query,$user,'working',$process,'view');
	$html.= &ProcessTable($query,$user,'done',$process,'view','remove');
	$html.= &ProcessTable($query,$user,'failed',$process,
			      'view','remove','restart');
	return $html;
    }

    #-----------------------------------
    # no user --> administrator view!!!
    #
    else{
	my $html.= &ProcessTable($query,undef,'todo',$process,
			      'view','run','remove');
	$html.= &ProcessTable($query,$user,'queued',$process,
			      'view','remove');
	$html.= &ProcessTable($query,undef,'working',$process,
			      'view','remove');
	$html.= &ProcessTable($query,undef,'done',$process,
			      'view','remove','restart');
	$html.= &ProcessTable($query,undef,'failed',$process,
			      'view','remove','restart');
	return $html;
    }

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
	my $query=&AddUrlParam($url,'task',$m);
	push (@links,&a({-href => $query},$n));
    }
    return wantarray ? @links : join &br(),@links;
}


sub UplugSystemForm{
    my $url=shift;
    my $user=shift;
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

    my $back=&a({-href=>'javascript:',onclick=>'history.go(-1)'},'back');
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
    my $widgets=&MakeWidgetForm($user,$config{widgets},\%config,$shortcuts);
    if (not $widgets){return $back.$html;}
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
	    my $form=&MakeWidgetForm($user,
				     $$config{$p}, # sub-menu config
				     $def,         # default value
				     $shortcuts,   # shortcuts hash
				     $name);       # sub-menu name
	    if (not $form){return undef;}
	    push (@rows,&td([$form]));
	}
	else{
	    if (ref($shortcuts) eq 'HASH'){
		my ($short)=grep ($$shortcuts{$_} eq $name,keys %{$shortcuts});
		if ($short){$name='-'.$short;}
	    }
	    my $widget=&MakeWidget($user,$name,$$config{$p},$def);
	    if (not $widget){return undef;}
	    push (@rows,&td([$p,$widget]));
	}
    }
    if (not @rows){return undef;}
    return &table({},&Tr(\@rows));
}


sub MakeWidget{
    my $user=shift;
    my $name=shift;
    my $config=shift;
    my $default=shift;

    if ($config=~/stream\s*\((.*)\)/){
	my %para=split(/\s*[\,\=]\s*/,$1);
	my @streams=&Uplug::Web::Corpus::GetCorpusStreams($user,%para);
	if (not @streams){
	    print "No appropriate input corpora found!",&p;
	    foreach (keys %para){
		print "$_=$para{$_}",&br;
	    }
	    return undef;
	}
	return &td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort @streams])]);
    }
    elsif($config=~/optionmenu\s*\((.*)\)/){
	my @options=split(/\s*\,\s*/,$1);
	return &td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort @options])]);
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
	return &td([&popup_menu(-name=> $name,
				-default => $default,
				-values => [sort {$a <=> $b} @options])]);
    }
    elsif($config=~/checkbox/){
	return &radio_group(-name=>$name,
			     -values=>['0','1'],
                             -default=>$default,
			     -labels=> {'1' => 'on','0' => 'off'});

#	if ($default){
#	    return &checkbox(-name=>$name,
#			     -checked=>'checked',
#			     -value=>'1',-label=>'');
#	}
#	return &checkbox(-name=>$name,-value=>'1',-label=>'');
    }
    return &td([&textfield(-name => $name,-default=>$default)]);
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
	push (@links,'['.&a({-href => &AddUrlParam($url,'action',$_)},$_).']');
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


package Uplug::Web::Corpus;

use CGI qw/:standard escapeHTML escape/;

sub new{
    my $class=shift;
    my $user=shift;
    my $owner=shift;
    my $file=shift;
    my $self={};
    bless $self,$class;
    $self->{FILE}=$file;
    $self->{USER}=$user;
    $self->{OWNER}=$owner;
    $self->{STYLES}=&Uplug::Web::AccessMode($user,$owner,$class);
#    print @{$self->{STYLES}};
#    print $self->{STYLES};
    return $self;
}

sub view{
    my $self=shift;
    my ($url,$style,$pos)=@_;

    if (not defined $style){$style='xml';}
    $self->{STYLE}=$style;
    $self->{POS}=$pos;

    my $file=$self->{FILE};
    if ($file=~/\.gz$/){open F,"$GUNZIP < $file |";}
    else{open F,"< $file";}
    binmode(F,":utf8");
#    binmode(F);

    my $html='';
    my $skip=0;
    my $count=0;
    while (<F>){
	if ($skip<$pos){$skip++;next;}
	$html.=escapeHTML($_);
	$html=~s/\n/\<br\>/gs;
	$html=~s/\s/\&nbsp\;\&nbsp\;/gs;
	if ($count>$MAXVIEWLINES){last;}
	$count++;
    }
    close F;
    $self->{COUNT}=$count;

    my $links=$self->PrevNextLinks($url);
    return $links.$html;

}

sub edit{                           # no edit defined!
    my $self=shift;                 # (just view the corpus)
    return $self->view(@_);
}



sub PrevNextLinks{
    my $self=shift;
    my $url=shift;

    my $count=$self->{COUNT};
    my $style=$self->{STYLE};
    my $pos=$self->{POS};

    my ($next,$prev,$styles);
    if (ref($self->{STYLES}) eq 'ARRAY'){
	foreach (@{$self->{STYLES}}){
	    if ($style eq $_){next;}
	    my $link=&Uplug::Web::AddUrlParam($url,'style',$_);
	    $styles.=' ['.&a({-href => $link},$_).']';
	}
    }
    if ($styles){$styles='display style: '.$styles.&br();}
    if ($pos){
	my $link=&Uplug::Web::AddUrlParam($url,'pos',$pos-$count);
	$prev=&a({-href => $link},'previous');
    }
    if ($count>=$MAXVIEWDATA){
	my $link=&Uplug::Web::AddUrlParam($url,'pos',$pos+$count);
	$next=&a({-href => $link},'next');
    }
    return $styles.&p().$prev.&br().$next.&p();
}



#############################################################################


package Uplug::Web::Bitext;

use CGI qw/:standard escapeHTML escape/;
use vars qw(@ISA);
@ISA = qw( Uplug::Web::Corpus );


sub new{
    my $class=shift;
    my $self=$class->SUPER::new(@_);
#    $self->{STYLES}=['text','xml'];
    $self->{ROOT}='link';
    return $self;
}


sub view{
    my $self=shift;
    my ($url,$style,$pos)=@_;

    if (not defined $style){$style='xml';}
    $self->{STYLE}=$style;
    $self->{POS}=$pos;

    my $count;my $fromDoc;my $toDoc;
    if (not $self->readLinks($pos)){return undef;}
    my $html=$self->PrevNextLinks($url);
    $html.=$self->readSentLinks($style);
    return $html;
}



sub readLinks{
    my $self=shift;
    my ($pos)=@_;

    my $file=$self->{FILE};
    if ($file=~/\.gz$/){open F,"$GUNZIP < $file |";}
    else{open F,"< $file";}
    binmode(F);
    local $/='>';

    my $parser=new XML::Parser(Handlers => {Start => \&XmlStart,
					    End => \&XmlEnd,
					    Default => \&XmlChar});
    my $handle=$parser->parse_start;
    $self->{SENTLINKS}=[];
    $self->{WORDLINKS}=[];
    $handle->{ROOT}=$self->{ROOT};

    my $count;my $skipped;
    while (&ParseXml(*F,$handle)){
	if ($skipped<$pos){$skipped++;next;}
	if ($count>=$MAXVIEWDATA){last;}
	$count++;
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


sub openDocument{
    my $self=shift;
    my $doc=shift;

    if ($self->{$doc}=~/\.gz/){
	open $self->{$doc.'HANDLE'},"$GUNZIP < $self->{$doc} |";
    }
    else{open $self->{$doc.'HANDLE'},"< $self->{$doc}";}
    $self->{$doc.'EXPAT'}=new XML::Parser(Handlers => {Start => \&XmlStart,
							End => \&XmlEnd,
							Default => \&XmlChar});
    $self->{$doc.'PARSER'}=$self->{$doc.'EXPAT'}->parse_start();
    $self->{$doc.'PARSER'}->{ROOT}='s';
    $self->{$doc.'PARSER'}->{SUBROOT}='w';
}


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

    while (<$fh>){
 	eval { $p->parse_more($_); };
	if ($@){print "problems when parsing ($@)!\n";return 0;}
	if ($p->{COMPLETE}){return 1;}
    }
    return 0;
}


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
    my ($url,$style,$pos,$params,$links)=@_;

    if (ref($params) eq 'HASH'){
	if ($$params{edit} eq 'change'){
	    Uplug::Web::Corpus::ChangeWordLinks($self->{FILE},$links,$params);
	      $url=Uplug::Web::DelUrlParam($url,'seg');
	      $url=Uplug::Web::DelUrlParam($url,'links');
	      $url=Uplug::Web::DelUrlParam($url,'edit');
	  }
    }

    if (not $style){$style='text';}
    if ($style eq 'xml'){
	return $self->Uplug::Web::Corpus::view($url,$style,$pos);
    }
    return $self->SUPER::view($url,$style,$pos);
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
