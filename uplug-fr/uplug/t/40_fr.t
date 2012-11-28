#!/usr/bin/perl
#-*-perl-*-

use Test::More;
use File::Compare;
use FindBin qw( $Bin );

use Uplug;

my $UPLUG = 'uplug';
my $DATA  = $Bin.'/data';

my $input    = $DATA.'/1988fr.txt';
my $expected = $DATA.'/1988fr.xml';

my $null = "2> /dev/null >/dev/null";

system("$UPLUG pre/fr-all -ci iso-8859-1 -in $input -out annotated.xml $null");
is( compare( "annotated.xml", $expected ),0, "annotate text" );
unlink("annotated.xml");


done_testing;

