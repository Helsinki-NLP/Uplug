#!/usr/bin/perl
#
# convert srt files (movie subtitles) to tokenized XML (utf8)
# (very simple tokenization & sentence splitting)
#
# usage: ./srt2xml [-l lang-code] srt-file > xmlfile
#


use strict;

use Getopt::Std;
use IPC::Open3;
use FindBin qw($Bin);
use Encode;

use vars qw/$opt_l/;

$opt_l = 'unknown';
getopts('l:');


my $PAUSETHR1 = 1;       # > 1 second --> most probably new sentence
my $PAUSETHR2 = 3;       # > 3 second --> definitely new sentence


if ($opt_l eq 'chi'){
    $ENV{UPLUGHOME} = $ENV{HOME}.'/projects/Uplug/uplug';
    require "$ENV{UPLUGHOME}/ext/chinese/segment/segmenter.pl";
}

## read (non-breaking) abbreviations (if the file exists)
my %NONBREAKING=();
read_non_breaking($Bin.'/nonbreaking_prefix.'.$opt_l,\%NONBREAKING);


## get the appropriate language code for a given language (iso639-3)

sub LangEncoding{
    my $lang = shift;

# supported by Perl Encode:
# http://perldoc.perl.org/Encode/Supported.html

    return 'iso-8859-4' if ($lang=~/^(ice)$/);
    ## what is scc?
    return 'cp1250' if ($lang=~/^(alb|bos|cze|pol|rum|scc|scr|slv|hrv)$/); 
#    return 'iso-8859-2' if ($lang=~/^(alb|bos)$/);
    return 'cp1251' if ($lang=~/^(bul|mac|rus|bel)$/);
#    return 'cp1252' if ($lang=~/^(dan|dut|epo|est|fin|fre|ger|hun|ita|nor|pob|pol|por|spa|swe)$/);
    return 'cp1253' if ($lang=~/^(ell|gre)$/);
    return 'cp1254' if ($lang=~/^(tur)$/);
    return 'cp1255' if ($lang=~/^(heb)$/);
    return 'cp1256' if ($lang=~/^(ara)$/);
    return 'cp1257' if ($lang=~/^(lat|lit)$/);  # correct?
    return 'big5-eten' if ($lang=~/^(chi)$/);
    return 'shiftjis' if ($lang=~/^(jpn)$/);
#    return 'cp932' if ($lang=~/^(jpn)$/);
    return 'euc-kr' if ($lang=~/^(kor)$/);
#    return 'cp949' if ($lang=~/^(kor)$/);
    return 'cp1252';
#    return 'iso-8859-6' if ($lang=~/^(ara)$/);
#    return 'iso-8859-7' if ($lang=~/^(ell|gre)$/);
#    return 'iso-8859-1';

## unknown: haw (hawaiian), hrv (crotioan), amh (amharic) gai (borei)
##          ind (indonesian), max (North Moluccan Malay), may (Malay?)
}





my $enc=LangEncoding($opt_l);

#use IO::File;
#use POSIX qw(tmpnam);
#my $tmpfile;
#my $uplug=$ENV{HOME}.'/projects/Uplug/uplug/uplug';
#if ($opt_l eq 'jpn'){
#    my $fh;
#    do {$tmpfile=tmpnam();}
#    until ($fh=IO::File->new($tmpfile,O_RDWR|O_CREAT|O_EXCL));
#    $fh->close();
#    *OUT = *STDOUT;
#    open STDOUT,">$tmpfile";
#}

# binmode(STDIN,':encoding(iso-8859-1)');
binmode(STDIN,":encoding($enc)");
binmode(STDOUT,':encoding(utf8)');


print_xml_header();

my $sid = 1;
print "  <s id=\"$sid\">\n";
$sid++;
my $s_ended = 0;

my $s_start = '([\"\']?[\¿\¡\p{Lu}])';
my $s_start_maybe = '(\-?\s*[\"\']?[\p{N}\p{Ps}])';
my $s_end = "([^\.]\.[\"\']?|[\.\!\?\:][\"\']?)";
my $s_end_maybe = "([^\.]\.[\"\'\]\}\)]?\-?\s*|[\.\!\?\:][\"\'\]\}\)]?\-?\s*)";

my $start=undef;
my $end=undef;
my $lastend = undef;
my $id=undef;
my $wid = 0;

my $newchunk = 0;

my @opentags=();
my @closedtags=();


while (my $line = <>){
    if (not defined $id){
	if ($line=~/^([0-9]+)$/){
	    $id = $1;
	    next;
	}
    }
    elsif (not defined $start){
	if ($line=~/^([0-9:,]+) --> ([0-9:,]+)/){
	    $start = $1;
	    $end = $2;
#	    print "    <time id=\"start$id\" value=\"$start\" />\n";
	    $newchunk = 1;
	    if ($lastend){
		if (time2sec($start)-time2sec($lastend) > $PAUSETHR1){
		    if (not $s_ended){$s_ended = 2;}
		    elsif ($s_ended < 3){$s_ended++;}
#		$s_ended = 2;
		}
		if (time2sec($start)-time2sec($lastend) > $PAUSETHR2){
		    $s_ended = 3;
		}
	    }
	    next;
	}
    }

    if ($line=~/^\s*$/){
	if ($end){
	    print "    <time id=\"T${id}E\" value=\"$end\" />\n";
	    $lastend = $end;
	    $id=undef;
	    $start=undef;
	    $end=undef;
	    ## new fragment -> always a possible sentence end!
	    if (not $s_ended){$s_ended = 1;}
	}
    }
    else{

	$line = fix_punctuation($line);
	if ($opt_l eq 'en' || $opt_l eq 'eng'){
	    $line = fix_eng_ocr_errors($line);
	}

	## ignore formatting tags!
	my $plain = $line;
	$plain =~s/\<[^\>]+\>//gs;

	## if a sentence has been ended before

	if ($s_ended){

	    if ($s_ended == 3){
		closetags();
		print "  </s>\n";
		print "  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }

	    elsif ($plain=~/^\s*([\"\'\[]?|[\*\#\']*\s*)[\¿\¡\p{Lu}l]/){
		closetags();
		print "  </s>\n";
		print "  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }
#	    elsif (($s_ended==2) && 
#		   ($plain=~/^(\-?\s*[\"\']?[\p{N}\p{Ps}\p{Lu}l])/)){
	    elsif (($s_ended==2) && 
		   ($plain=~/^(\s*[\-\#\*\']*\s*[\"\'\[]?[\p{N}\p{Ps}\p{Lu}l])/)){

		closetags();
		print "  </s>\n";
		print "  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }

	    ## new sentence if previous sentence ended with '...'
	    ## and this one starts with bullets of quotes
	    elsif (($s_ended==1) && ($plain=~/^\s*[\-\#\*\'\"]/)){
		closetags();
		print "  </s>\n";
		print "  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }

	    elsif ($opt_l=~/^(chi|kor|jpn)$/){
		closetags();
		print "  </s>\n";
		print "  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }
	}
	if ($newchunk && $start){
	    print "    <time id=\"T${id}S\" value=\"$start\" />\n";
	}
	$newchunk=0;

	## if there are sentence boundaries within one line:
	## - add sentence boundaries
	## - tokenize and print text from previous sentence

	while ($line=~/^(.*?[.!?:\]])([^.!?:].*)$/){

	    my $before=$1;
	    my $after=$2;

	    my $plain_before = $before;
	    my $plain_after = $after;

	    $plain_before =~s/\<[^\>]+\>//gs;
	    $plain_after =~s/\<[^\>]+\>//gs;

	    my $sentence_boundary = 0;
	    if ($plain_before=~/([^.]\.|[!?:])[\'\"]?\s*$/){
#		if ($plain_after=~/^\s+\-?\s*[\"\']?[\p{N}\p{Ps}\p{Lu}]/){
		if ($plain_after=~/^\s+[\-\*\#]*\s*[\"\'\[]?[\p{N}\p{Ps}\p{Lu}]/){
		    $sentence_boundary = 1;
		}
	    }
	    elsif ($plain_before=~/([.!?:])[\"\'\]\}\)]?\-?\s*$/){
		if ($plain_after=~/^\s+[\"\']?[\¿\¡\p{Lu}]/){
		    $sentence_boundary = 1;
		}
	    }
	    elsif ($plain_before=~/\s*\]\s*$/){
		if ($plain_after=~/^\s*[\-\*\#]*\s*[\"\']?[\p{N}\p{Ps}\p{Lu}]/){		    
		    $sentence_boundary = 1;
		}
	    }
	    elsif ($plain_before=~/^\s*[\-\*\#]*\s*\[.{0,20}\]\s*$/s){
		$sentence_boundary = 1;
	    }


	    ## for chinese/korean/japanese -> always split
	    if ($opt_l=~/^(chi|kor|jpn)$/){
		$sentence_boundary = 1;
	    }

	    ## tokenize
	    my $last_token='';
	    ($wid,$last_token) = print_tokens($before,$sid-1,$wid);

	    # check if last token is a non-breaking one
	    # --> don't start a new sentence!
	    $last_token=~s/\.$//;
	    if (exists $NONBREAKING{$last_token}){
		$sentence_boundary = 0;
	    }

	    $line = $after;
	    if ($sentence_boundary){
		closetags();
		print "  <\/s>\n  <s id=\"$sid\">\n";
		reopentags();
		$sid++;
		$wid=0;
	    }
	}


	## background info --> keep separate

	if ($plain=~/^\s*[\-\*\#]*\s*\[.{0,20}\]\s*$/){
	    $s_ended = 3;
	}

	# sentence-end detected at end-of-string:
	# - either
	#   + non-dot followed by a dot
	#   + one of the following punctuations: [!?:]
	# - possibly followed by quotes or closing brackets ["'\]\}\)]?
	# - followed by 0 or more spaces before end-of-string

	elsif ($plain=~/([^.]\.|[!?:])[\'\"]?\s*$/){
	    $s_ended=2;
#	    print "=================ended $1\n";
	}

	## very weak sentence ending: '...'
	elsif ($plain=~/\.\.\.\s*$/){
	    $s_ended=1;
	}

	# possible sentence ending:
	# - one of the punctutation characters [.!?:]
	# - possibly followed by quotes or closing brackets ["'\]\}\)]?
	# - possibly followed by a hyphen
	# - followed by 0 or more spaces before end-of-string
	elsif ($plain=~/([.!?:\]])[\"\'\]\}\)]?\-?\s*$/){
	    $s_ended=2;
#	    print "===============maybe ended $1\n";
	}

	else{
	    $s_ended=0;
	}

	## tokenize and print remaining text

	my $last_token='';
	($wid,$last_token) = print_tokens($line,$sid-1,$wid);
	# check if last token is a non-breaking one
	# --> don't start a new sentence!
	$last_token=~s/\.$//;
	if (exists $NONBREAKING{$last_token}){
	    $s_ended = 0;
	}
#	print;
    }
}

closetags();
print "  </s>\n";

print_xml_footer();

#if ($opt_l eq 'jpn'){
#    print OUT `$uplug pre/ja/toktag -in $tmpfile`;
#    unlink $tmpfile;
#}


####################################################################


sub closetags{
    while (my $tag=pop(@opentags)){
	print "    </$tag>\n";
	push(@closedtags,$tag);
    }
}

sub reopentags{
    while (my $tag=pop(@closedtags)){
	print "    <$tag>\n";
	push(@opentags,$tag);
    }
}


sub print_word{
    my ($w,$sid,$wid)=@_;
    $w=~s/&/&amp;/g;
    $w=~s/</&lt;/g;
    $w=~s/>/&gt;/g;
    print "    <w id=\"$sid.$wid\">",$w,"</w>\n";
}


sub print_tokens{
    my ($string,$sid,$wid)=@_;

    # chinese tokenization
    if ($opt_l=~/^chi$/){
	return print_chinese_tokens($string,$sid,$wid);
    }
    # no japanese tokenization (leave it to Uplug and ChaSen)
    if ($opt_l=~/^jpn$/){
	$string=~s/&/&amp;/g;
	$string=~s/</&lt;/g;
	$string=~s/>/&gt;/g;
	print $string;
	return ($wid,$string);
    }

    my @tokens=();

    # Dutch tokenization using Alpino
    if (($opt_l eq 'dut') && 
	(-e "$ENV{ALPINO_HOME}/Tokenization/tokenize.sh")){
	@tokens = tokenize_dutch($string);
    }

    # all other languages .... (which is most probably very bad!)
    else{ 
	@tokens = tokenize($string);
    }

    foreach my $t (@tokens){

	## it's an opening tag --> store in open-tags
	if ($t =~/^\<([^\/]\S*)(\s.*)?\>$/){
#	    print "found opening tag: $1\n";
	    push(@opentags,$1);
	    print "    ".$t."\n";
	}
	## it's a closing tag --> close open tags if they are not the same
	elsif ($t =~/^\<\/(\S+)\>$/){
#	    print "found closing tag: $1\n";
	    my $tagname=$1;
	    my $tag=pop(@opentags);
	    while ($tag && $tagname ne $tag){  # while not the same
		print "    </$tag>\n";         # print closing tag!
		$tag=pop(@opentags);
		if (not $tag){last;}        # no more tag open anymore -> bad!
	    }
	    if ($tagname ne $tag){          # last tag is not the one we need:
		print "    <$tagname>\n";   # create an opening tag (ugly!)
	    }
	    print "    ".$t."\n";           # finally: print closing tag
	}
	else{
	    $wid++;
	    print "    <w id=\"$sid.$wid\">".$t."</w>\n";
	}
    }
    return ($wid,$tokens[-1]);
}


sub print_chinese_tokens{
    my ($string,$sid,$wid)=@_;

#    $ENV{UPLUGHOME} = $ENV{HOME}.'/projects/Uplug/uplug';
#    require "$ENV{UPLUGHOME}/ext/chinese/segment/segmenter.pl";

    ## segmenter works with big5 coded strings ....
    require Encode;
    my $big5 = Encode::encode( 'big5', $string );

    my $seg = segmentline($big5);
    my @tok = split(/\s+/,$seg);
    foreach my $t (@tok){
	next if not $t;
	$wid++;
	$t=~s/&/&amp;/g;
	$t=~s/</&lt;/g;
	$t=~s/>/&gt;/g;

	## decode from big5
	my $t = Encode::decode( 'big5', $t );

	my $pos = index($string,$t);  # find the chunk
	if ($pos>0){                  # if there's something before chunk
	    my $before = substr($string,0,$pos);
	    if ($before=~/\S/){
		$wid++;
		print "      <w id=\"$sid.$wid\">",$before,"</w>\n";
	    }
	}
	$string = substr($string,$pos+length($t));

	print "      <w id=\"$sid.$wid\">",$t,"</w>\n";
    }
    if ($string=~/\S/){
	$wid++;
	print "      <w id=\"$sid.$wid\">",$string,"</w>\n";
    }
    return ($wid,$string);
}







sub print_xml_header{
    print '<?xml version="1.0" encoding="utf-8"?>'."\n";
    print "<document>\n";
}


sub print_xml_footer{
    print "</document>\n";
}


sub tokenize{
    my $string=shift;

    ## some special formatting tags used in srt-files:
    ## <i>, <b>, <font ...>
    ## convert them to '[...]' and convert them back later (quite a hack ..)
    ##
    ## (now done in split_on_whitespace)

#    $string=~s/<(\/?[ib])>/ [$1] /gs;
#    $string=~s/<(\/?font[^>]*?)>/ [$1] /gs;


    # \p{P} ==> punctuations
    # \P{P} ==> non-punctuations

    # non-P + P + (P or \s or \Z)
    $string=~s/(\P{P})(\p{P}[\p{P}\s]|\p{P}\Z)/$1 $2/gs;  
    # (\A or P or \s) + P + non-P
    $string=~s/(\A\p{P}|[\p{P}\s]\p{P})(\P{P})/$1 $2/gs;
    # special treatment for ``
    $string=~s/(``)(\S)'/$1 $2/;    # '

    # separate punctuations if they are not the same
    # (use negative look-ahead for that!)

    $string=~s/(\p{P})(?!\1)/$1 $2/gs;

    # delete multiple spaces
    $string=~s/\s+/ /;
    $string=~s/^\s*//;
    $string=~s/\s*$//;

    $string=~s/&/&amp;/g;
    $string=~s/</&lt;/g;
    $string=~s/>/&gt;/g;

    ## convert formatting tags back to 'normal'

    $string=~s/\[\s*(\/?)\s*([ib])\s*\]/<$1$2>/gs;
    $string=~s/\[\s*(\/?)\s*(font[^>]*?)\s*\]/<$1$2>/gs;

    return split_on_whitespaces($string);
}


sub split_on_whitespaces{
    my $string = shift;

    ## remove spaces in formatting tags
    ## (quite a hack)
    $string=~s/<\s*(\/?)\s*([ib])\s*>/ <$1$2> /gs;
    $string=~s/<\s*(\/?)\s*(font[^>]*?)\s*>/ <$1$2> /gs;

    ## space within tags are not token delimiters!
    ## --> change them to '&nbsp;' (another hack)
    do{}
    until (not $string=~s/\<([^>]*)\s([^>]*)\>/<$1&nbsp;$2>/gs);

    ## split on whitespaces
    my @tokens = split(/\s+/,$string);

    ## change '&nbsp;' back to spaces 
    map ($_=~s/\&nbsp;/ /,@tokens);

    ## merge (nonbreaking) abbreviations with following '.'
    my @tokens2=();
    while (@tokens){
	my $tok = shift(@tokens);
	if ((exists $NONBREAKING{$tok}) && ($tokens[0] eq '.')){
	    if ($NONBREAKING{$tok} == 2){
		if ($tokens[1]=~/^[0-9\.\,\s]+$/){
		    shift(@tokens);
		    push(@tokens2,$tok.'.');
		}
		else{
		    push(@tokens2,$tok);
		}
	    }
	    else{
		shift(@tokens);
		push(@tokens2,$tok.'.');
	    }
	}
	else{
	    push(@tokens2,$tok);
	}
    }
    return @tokens2;
}



## see http://perldoc.perl.org/Encode.html#Handling-Malformed-Data
sub escape_wide{sprintf "\\u%04X", shift}

sub tokenize_dutch{
    my $text=shift;

    my $TOKCOMMAND = "$ENV{ALPINO_HOME}/Tokenization/tokenize.sh";
    my ($TOKIN,$TOKOUT,$TOKERR);
    my $TOKPID=open3($TOKIN,$TOKOUT,$TOKERR,$TOKCOMMAND);
    binmode($TOKIN, ":encoding(iso-8859-1)");
    binmode($TOKOUT, ":encoding(iso-8859-1)");

    ## some europarl specific pre-preprocessing
    $text =~ s/\' ([a-zA-Z][^a-zA-Z])/\'$1/gs;
    $text =~ s/\n\n+/\n/sg;
    $text =~ s/^\(Applaus\)(.*)/\(Applaus\)\n$1/gs;

    ## escape wide unicode characters
    ## using reference to existing subroutines avoids memory leak!
    my $octets = encode('iso-8859-1', $text,\&escape_wide);
    $text = decode('iso-8859-1', $octets);

    print $TOKIN $text;
    close $TOKIN;
    $text = '';
	
    while (my $l = <$TOKOUT>){

	## some europarl specific post-processing
	$l=~s/ \' ([a-zA-Z][a-zA-Z]*\'-)/ \'$1/g;
	$l=~s/\( ([a-zA-Z][a-zA-Z]*\))/\($1/g;
	# from $ALPINO_HOME/Tokenize/streepjes;
	if ($l=~/[ ][-]([^ ][^-]*[^ ])[-][ ]/) {
	    my $prefix=$`;
	    my $middle=$1;
	    my $suffix=$';   # '
	    if ($prefix !~ /(en |of )$/ &&
		$suffix !~ /^(en |of )/) {
		$l = "$prefix - $middle - $suffix";
	    } 
	}

	$text.=$l;
    }
    
    close $TOKOUT;
    close $TOKERR if ref($TOKERR);
    waitpid $TOKPID,0;

    return split_on_whitespaces($text);
}
## end of Alpino tokenizer ....
##--------------------------------------------------------------------





sub time2sec{
    my $time=shift;
    my ($h,$m,$s,$ms)=split(/[^0-9\-]/,$time);
    my $sec = 3600*$h+60*$m+$s+$ms/1000;
    return $sec;
}





## in some english subtitle files 'I' is confused with 'l'
## in I'm and even for It!
## (e.g. in en/2003/1114-v1.srt.gz

sub fix_eng_ocr_errors{
    my $line=shift;
    $line=~s/(\A|\s+|[\"\'\[\(\-\#\*])l(t?)(\'[a-z]{1,2}|\s+|,\s+|\.\.\.)/$1I$2$3/gs;

    ## some cases in eng/Comedy/1994/3965_82856_110413_postino_il.xml
    $line=~s/([^aeiuo])[lI]{3}/$1ill/gs;    # stlll, wlll (too general?)
    $line=~s/([^AEIOUaeiuo\s])ll/$1il/gs;   # exlled
    $line=~s/I(ove[d\s])/l$1/gs;            # Ioved
    $line=~s/llke/like/gs;                  # llke --> like
    $line=~s/([a-zA-Z])I([^I\sl])/$1l$2/gs; # onIy, AIfredo
    return $line;
}

sub fix_punctuation{
    my $line = shift;
    ## replace 2x single quote with double quotes
    $line=~s/\'\'/\"/g;
    ## found in eng/Comedy/1995/1690_84526_112988_four_rooms.xml.gz:
    ## 2 double quotes ... 
    $line=~s/\"\"+/\"/g;
    return $line;
}



sub read_non_breaking{
    my $file = shift;
    my $hash = shift;
    if (-e "$file") {
	open(PREFIX, "<:utf8", "$file");
	while (<PREFIX>) {
	    my $item = $_;
	    chomp($item);
	    if (($item) && (substr($item,0,1) ne "#")) {
		if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) {
		    $$hash{$1} = 2;
		} else {
		    $$hash{$item} = 1;
		}
	    }
	}
	close(PREFIX);
    }
}
