#!/usr/bin/perl
#-*-perl-*-

use Test::More;
use File::Compare;

use Uplug;


my $UPLUG = 'uplug';
my $DATA  = 'data';

my $input    = $DATA.'/1988de.txt';
my $expected = $DATA.'/1988de.xml';

my $null = "2> /dev/null >/dev/null";

system("$UPLUG pre/de-all -ci iso-8859-1 -in $input -out annotated.xml $null");
is( compare( "annotated.xml", $expected ),0, "annotate text" );
unlink("annotated.xml");


done_testing;
