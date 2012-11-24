#!/usr/bin/perl
# $Id: gl_mtponct.pl 2871 2009-11-10 17:06:50Z sagot $

# grammaire locale des ponctuations multi-tokens, des "M ." et des "," en fin de phrase, des mots de type "incomp(let)" et des apostrophes qui sont des back-quotes
# ad hoc pour la campagne easy et sa segmentation l�gendaire par sa pitoyable nullit�
# mais peut toujours servir pour certifier une certaine robustesse

$| = 1;

$lang="fr";

$corpus = "";

while (1) {
    $_=shift;
    if (/^$/) {last;}
    elsif (/^-no_sw$/ || /^-no_split-words$/i) {$no_sw=1;}
    elsif (/^-l(?:ang)?=(.*)$/) {$lang=$1;} elsif (/^-l(?:ang)?$/) {$lang=shift;}
    elsif (/^-md$/) {$corpus="mondediplo";}
}

my $rctxt = qr/(?:[ ;:\?\!\(\)\[\]]|[,\.][^0-9])/;

while (<>) {
    # formattage
    chomp;
    if (/ (_XML|_MS_ANNOTATION) *$/) {
	print "$_\n";
	next;
    }

    s/^\s*/  /o;
    s/\s*$/ /o;
    # variables
    $l    = qr/[a-z����������������\��������A-Z�����������ǥ\��������]/o;
    $maj  = qr/[A-Z�����������ǥ\��������]/o;
    $min  = qr/[a-z����������������\��������]/;
    $m=qr/$l+/;
    # reconnaissance
#    s/([\!\?][\!\? ]+[\!\?])/ {$1} <<<$1>>> /go;
    s/([^\s\{\}]+)(\s+\`) / {$1$2} <<<$1\'>>> /go;
    s/(?<=[^\}])''/{''} "/go;
    if ($lang eq "fr") {      # ATTENTION : blanc non convertis en \s
      s/(?<=[^\}]) Canal \+($rctxt)/ {Canal +} Canal_Plus\1/go;
      s/(?<=[^\}]) M 6($rctxt)/ {M 6} M6\1/go;
      s/(?<=[^\}]) France( )?([2345]|24)($rctxt)/ {France$1$2} France_$2$3/go;
      s/(?<=[^\}]) G ([789]|1[0-9]|20)($rctxt)/ {G $1} G$1$2/go;
      s/(?<=[^\}]) TF 1($rctxt)/ {TF 1} TF1\1/go;
      s/(?<=[^\}]) (\S*oe) (u\S*)/ {\1 \2} \1\2 /go;
      # r�p�tition de mots-outils (d�s 2 fois)
      s/(?<=[^\}]) ((?:l[ae]|les)(?: (?:l[ea]|les|euh))+) (l[ae]|les) / {$1} _EPSILON $2 /go; # comme suivants
      for $mot (qw(vos moi il ne sa les la le qui � dans un ce en y on des et sont)) { # un? ; une une devrait donner (une une|une)
	s/(?<=[^\}]) ($mot(?: (?:$mot|euh))*) $mot / {$1} _EPSILON $mot /g; # pas d'option "o"
      }
      s/(?<=[^\}]) (de(?: (?:de|euh))*) (d[e']) / {$1} _EPSILON $2 /go; # comme pr�c�demment, mais cas sp�cial pour de/d'
      s/(?<=[^\}]) (le(?: (?:le|euh))*) (l[e']) / {$1} _EPSILON $2 /go; # comme pr�c�demment, mais cas sp�cial pour le/l'
      # r�p�tition de suites de 2 mots "non r�p�tables"
      for $mot ("c' est","il faut","on a","qu' un") {
	s/(?<=[^\}]) ($mot(?: (?:$mot|euh))*) $mot / {$1} _EPSILON $mot /g; # pas d'option "o"
      }
      # r�p�tition de suites d'au moins 3 mots
      s/(?<=[^\}]) ($m(?: $m){2,})( \1)* \1 / {$1$2} _EPSILON $1 /go;
      # mot_1 ... mot_n pas de mot_1 ... mot_n de 
      s/(?<=[^\}]) ($m(?: $m)+)( pas (?:des?|du)) \1 (des?|du) / {$1$2} _EPSILON $1 $3 /go;
      # mot_1 ... mot_n de mot_1 ... mot_n pas de 
      s/(?<=[^\}]) ($m(?: $m)+)( (?:des?|du)) \1 pas (des?|du) / {$1$2} _EPSILON $1 pas $3 /go;
      # h�sitations
      s/ ((?:euh|hein)(?: (?:euh|hein|,))*) / {$1} _EPSILON /go;
    }

#    s/^(\*|_UNDERSCORE|_)(\s+[^\s\{\}]+)/{$1} _EPSILON $2/go; # semble p�rim� depuis qu'on reconnait les _META_TEXTUAL_*
    while (s/\{([^}]+)\}\s*_EPSILON(\s*)\{([^}]+)\}\s*_EPSILON/\{$1$2$3\} _EPSILON/g) {}

    if ($lang eq "fr") {
      s/(?<=[^\}]) (\') / {$1} " /go;
      s/ ([ldnmst]) ([ae��iouy]\S+)/ {\1 \2} \1'\2/goi;
    }

    # mots de la forme incomp(let)
    if (/} *{/) {
	print STDERR "Warning: found pattern /} {/ in input line $_. Pattern deleted\n";
    }

    if ($lang eq "fr") {      # ATTENTION : blanc non convertis en \s
      s/(?<=[ \'\{\}])([^ \{\}]+) +\( +([elns]) +\)/\{$1 ( $2 )\} $1$2/go;
      s/(?<=[ \'\{\}])([^ \{\}]+) +\( +(ah|ale|and|ants|aut|bibi|ble|bution|de|dra|dustrie|ectivement|ens|�re|�ressent|es|ette|eur|glophone|iaisons|il|incipale|inte|ion|ir|iscut�|jets|jours|lait|le|les|lle|llion|monie|moyenne|nage|nations|ne|n�e|nnon�ait|ord|our|ous|ouver|pinion|que|ques|qu\'il|rait|re|registre|reil|remment|res|ri�s|rin|roupes|rs|se|sonniers|spectif|sser|stat�|ste|tancourt|te|t�ressent|tissement|tre|trices|trouverons|us|vance|ve|vez|vient|xistent) +\)/\{$1 ( $2 )\} $1$2/go;
      s/(?<=[ \'\{\}])([^ \{\}]+)( *\( *)(s|es?|nt)( *\))/\{$1$2$3$4\} $1$3/go; # pour "mot(s)", mais pas top
      s/(?<=[ {])([^ {}]+)} *{\1/$1/g; # {euh re} re ( ste ) -> {euh re} {re ( ste )} reste -> {euh re ( ste )} reste
    }

    if ($corpus eq "mondediplo") {
      # premiers mots de la phrase enti�rement en majuscule, suivi d'un mot � intiale majuscule
      my $postSB      = qr/(?:\{[^\}]*\}\s*)?(?:$maj\'?$min|M\.)/o;
      my $xmaj        = qr/[A-Z�����������ǥ\��������\-\'\"\(\)\[\]\%]/o;
      my $xxmaj       = qr/[A-Z�����������ǥ\��������\-\'\"\(\)\[\]\%\!\?\:]/o;
      my $xmajORspace = qr/[A-Z�����������ǥ\��������\-\'\"\(\)\[\]\% ]/o;
      if ($no_sw) {
	s/^\s*($xxmaj{3,})(\s+$postSB)/ $1 _SENT_BOUND$2/ ||
	  s/^\s*([A-Z�����������ǥ\��������\-\'\"]$xxmaj*\s+(?:$xmaj$xmajORspace*\s)?)($xmaj{2,})(\s+$postSB)/ $1 $2 _SENT_BOUND$3/;
      } else {
	s/^\s*($xxmaj{3,})(\s+$postSB)/ {$1} $1 {$1} ;$2/ ||
	  s/^\s*([A-Z�����������ǥ\��������\-\'\"]$xxmaj*\s+(?:$xmaj$xmajORspace*\s)?)($xmaj{2,})(\s+$postSB)/ $1 {$2} $2 {$2} ;$3/;
      }
    }


    # fl�ches
    if ($no_sw) {
      s/(?<=[^\}])\s+([\-\�_=]+(?:&gt;)+|(?:&gt;)(?:&gt;)+)\s+/ {$1} -&gt; /g;
      s/(?<=[^\}])\s+((?:&lt;)(?:&lt;)+|<+[\-\�_=]+)\s+/ {$1} &lt;- /g;
      s/(?<=[^\}])\s+((?:&lt;)+[\-\�_=]+(?:&gt;)+)\s+/ {$1} &lt;-&gt; /g;
    } else {
      s/^/!/;
      s/(?<=[^\}\s])\s*([\-\�_=]+(?:&gt;)+|(?:&gt;)(?:&gt;)+)\s*/ {$1} -&gt; /g;
      s/(?<=[^\}\s])\s*((?:&lt;)(?:&lt;)+|<+[\-\�_=]+)\s*/ {$1} &lt;- /g;
      s/(?<=[^\}\s])\s*((?:&lt;)+[\-\�_=]+(?:&gt;)+)\s*/ {$1} &lt;-&gt; /g;
      s/^!//;
    }

    while (s/<<<([^\s<>]*) +([^<>]*)>>>/<<<$1$2>>>/go) {}
    s/<<<//go;
    s/>>>//go;
    s/^ +//o;
    s/ $//o;
    print "$_\n";
}
