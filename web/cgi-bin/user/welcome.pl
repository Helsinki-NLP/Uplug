#!/usr/bin/perl
#---------------------------------------------------------------------------
# corpus.pl - a simple corpus manager
#
#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

require 5.002;
use strict;

use CGI qw/:standard/;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use UplugUser;
use UplugWeb;

my $user = &remote_user;

######################################################################

print &header(-charset => 'utf-8');
print &start_html(-title => 'Uplug welcome page',
		  -author => 'Joerg Tiedemann',
		  -base=>'true',
		  -dtd=>1,
		  -style=>{'src'=>$CSS},
		  -encoding => 'utf-8',
		  -head=>meta({-http_equiv=>'Content-Type',
			       -content=>'text/html;charset=utf-8'}));

my %UserData=();
&UplugUser::ReadUserInfo(\%UserData,$user);

print &h2("$UserData{$user}{Name} - Welcome to UplugWeb"),&hr();
print '
UplugWeb is a collection of web interfaces and tools for managing and
processing parallel corpora. It includes two main components:

<ul>
<li><a href="http://stp.ling.uu.se/cgi-bin/joerg/uplug2/user/corpus.pl">Corpus 
Manager</a> - Monolingual and bilingual corpora can be
added to your personal repository. The corpus manager includes tools
for updating the repository and inspecting corpus data in your collection.
<li><a href="http://stp.ling.uu.se/cgi-bin/joerg/uplug2/user/process.pl?task=main">Task 
Manager</a> - The task manager allows to run
applications on registered corpora. Several tools are integrated which
can be used to process monolingual and bilingual corpora. Jobs are
queued on the local system and results will be send by mail and added
to the personal data collection.
</ul>

Several tools have been integrated in Uplug. pre-processing tools
include a sentence splitter, tokenizer and external part-of-speech
tagger and shallow parsers. 
The following external tools are used: The <a href="http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger/DecisionTreeTagger.html">TreeTagger</a>
  for English, French, Italian, and German,
  the <a href="http://www.coli.uni-sb.de/~thorsten/tnt/">TnT
  tagger</a> for English, German and Swedish,
  the <a href="http://grok.sourceforge.net/">Grok system</a> for
  English, and
  the morphological analyzer 
  <a href="http://chasen.aist-nara.ac.jp/">ChaSen</a> for Japanese.
<br>
Translated documents can be sentence
aligned using the length-based approach by 
<a href="http://citeseer.nj.nec.com/gale91program.html">Gale&amp;Church</a>.
Words and phrases can be aligned using the 
<a href="/~joerg/paper/eacl03.pdf">clue
alignment</a> approach and the toolbox for statistical machine translation 
<a href="http://www-i6.informatik.rwth-aachen.de/web/Software/GIZA++.html">GIZA++</a>.
<hr>
Note that
<ul>
<li>UplugWeb is provided free of charge as it is. No warrantees, no guarantees
are given for anything!
<li>UplugWeb and all its services may be changed or removed without any prior
notice. This includes data which have been submitted to the server.
<li>Support is not generally provided but feedback is very welcome!
<li>Help and
support may be found in the collection of 
<a href="http://stp.ling.uu.se/cgi-bin/joerg/faq/uplug">frequently 
asked questions</a>
which is on the way to be constructed. Questions, recommendations and other
feedback can be posted to this
<a href="http://stp.ling.uu.se/cgi-bin/joerg/faq/uplug">F.A.Q.</a>
or sent to <a href="mailto:&#106;&#111;&#101;&#114;&#103;&#64;&#115;&#116;&#112;&#46;&#108;&#105;&#110;&#103;&#46;&#117;&#117;&#46;&#115;&#101;">&#106;&#111;&#101;&#114;&#103;&#64;&#115;&#116;&#112;&#46;&#108;&#105;&#110;&#103;&#46;&#117;&#117;&#46;&#115;&#101;</a>.
<li>Users may be banned from UplugWeb without warnings if this is necessary
for any reason.
<li>Data which have been submitted to the UplugWeb server are public if no
other regulations have been agreed to between the provider of UplugWeb and
its user.
</ul>
<hr>
';


print &end_html;

