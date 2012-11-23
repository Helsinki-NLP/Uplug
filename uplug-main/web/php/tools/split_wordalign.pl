#!/usr/bin/perl

my $corpus=$ARGV[0];
$corpus=~s/\.[^.]+$//;

my $isopen=0;

while (<>){

    if (/<link .*id=\"(.+?)\"/){
	if (! -e "$corpus/$1"){
	    open F,">$corpus/$1" || die "cannot open $corpus/$1!\n";
	    $isopen="$corpus/$1";
	}
	else{
	    print "warning: $corpus/$1 exists! (not overwritten)\n";
	}
    }
    if ($isopen){
	print F $_;
    }

    if (/<\/link>/){
	close F;
	chmod 0666,$isopen;
	$isopen=0;
    }

}
