#!/usr/bin/perl


use strict;
use CGI qw/:standard escapeHTML escape/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugUser;
use UplugProcess;

BEGIN { 
    use CGI::Carp qw(carpout);
#    open L, ">>/tmp/uplugWeb.log" || die ("could not open log\n");
#    carpout(*L);
}

my $user = &remote_user;
my $css = "/~joerg/uplug2/menu.css";
my $HtmlHome = "/~joerg/uplug2/";

my @stat=stat('menu.pl');
my $mtime=scalar(localtime($stat[9]));

my @menu = 
    ('General', 
     [
      'Home' , $HtmlHome.'home.html',
      'Publications' , $HtmlHome.'home.html#publications',
#      'System architecture' , $HtmlHome.'uplug.gif'
      ]
     );

if ($UplugUser::UplugAdmin eq $user){
push (@menu,(
	     'Uplug administration',
	     [
	      'User manager' , '../admin/user.pl',
	      'Corpus manager' , '../admin/corpus.pl',
	      'Task manager' , '../admin/process.pl',
	      ],
	     ));
}
push (@menu,(
	     'User management' , 
	     [
	      'Change password' , undef
	      ],
	     'Corpus management' , 
	     [
	      'My corpora' , 'corpus.pl?owner='.$user,
	      'Add corpus' , 'corpus.pl?action=add',
	      'Index/query' , 'index.pl?owner='.$user,
	      'All corpora' , 'corpus.pl',
	      'Query' , 'index.pl',
	      ],
	     'Task Management'
	     ));

my @apps=('Main' , 'process.pl?task=main');
my %main=();
my @main=&UplugProcess::GetSubmodules($user,'main');
while (@main){
    my $mod=shift(@main);
    my $name=shift(@main);
    push (@apps,('- '.$name,'process.pl?task='.escape($mod)));
}

push (@menu,[@apps]);
push (@menu,(
	     'Documentation/Links' , 
	     [
#      'UplugWeb' , $HtmlHome.'../uplug/UplugWeb/',
#	      "PWA User's Guide" , '/plug/pwa/pwa_manual.html',
      'F.A.Q.' => 'http://stp.ling.uu.se/cgi-bin/joerg/faq/uplug',
	      'PLUG' , '/plug/',
	      'PWA' , '/plug/pwa/'
	      ],
	     'Status' , 
	     [
      &address('&#106;&#111;&#101;&#114;&#103;&#64;&#115;&#116;&#112;&#46;&#108;&#105;&#110;&#103;&#46;&#117;&#117;&#46;&#115;&#101;') , 'mailto:&#106;&#111;&#101;&#114;&#103;&#64;&#115;&#116;&#112;&#46;&#108;&#105;&#110;&#103;&#46;&#117;&#117;&#46;&#115;&#101;',
	      $mtime , undef
	      ],
	     ));


print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug home page',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$css},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));


print &img({-src => "$HtmlHome/img/uplug.gif"});
print &p();

my @rows=();

while (@menu){
    my $header=shift(@menu);
    my $submenu=shift(@menu);
    push (@rows,th([$header]));
    while (@{$submenu}){
	my $name=shift(@{$submenu});
	my $target='main';
	if ($$submenu[0] eq '_top'){$target=shift(@{$submenu});}
	my $link=shift(@{$submenu});
	if (defined $link){
	    push (@rows,td([&a({-target => $target,-href => $link},$name)]));
	}
	else{
	    push (@rows,td([$name]));
	}
    }
}



print &table({width => '100%'},caption(''),Tr(\@rows));
print &end_html;
