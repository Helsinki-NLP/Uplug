#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

use Uplug;

my $UPLUG = $Bin.'/../uplug';
my $DATA  = 'data';

my $null = "2> /dev/null >/dev/null";

#-------------------------------------------------
# sentence alignment with align2

system("$UPLUG align/sent -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -out align.xml $null");

# ignore certainties (may vary on different OSs)
system("sed 's/certainty=\"[-0-9]*\"//' $DATA/xml/de-en/1988.sent.xml > gold.xml");
system("sed 's/certainty=\"[-0-9]*\"//' align.xml > system.xml");

is( compare( "system.xml", "gold.xml" ),0, "sentence alignment (de-en)" );

unlink('align.xml');
unlink('gold.xml');
unlink('system.xml');

#-------------------------------------------------
# sentence alignment with hunalign

system("$UPLUG align/hun -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -out align.xml $null");
is( compare( "align.xml", "$DATA/xml/de-en/1988.hun.xml" ),0, "hunalign (de-en)" );

system("$UPLUG align/hun -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -b -out align.xml $null");
is( compare( "align.xml", "$DATA/xml/de-en/1988.bisent.xml" ),0, "hunalign bisent mode (de-en)" );


unlink('align.xml');


# sentence alignment with gmaalign

system("$UPLUG align/gma -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -out align.xml $null");

is( compare( "align.xml", "$DATA/xml/de-en/1988.gma.xml" ),0, "gma (de-en)" );

unlink('align.xml');



done_testing;

