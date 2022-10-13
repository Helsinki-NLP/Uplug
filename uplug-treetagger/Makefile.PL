#-*-perl-*-

use lib '.';
use inc::Module::Install;
use LWP::Simple;
use File::Basename;

name        'Uplug';
version     '0.3.10';

abstract    'TreeTagger add-on for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';

my $TaggerLicense = "https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/Tagger-Licence";

# TreeTagger downloads

my $DownloadHome = 'https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/';
my $TaggerVersion = '3.2.2';

# https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/tree-tagger-MacOSX-3.2.2.tar.gz

my %TaggerBinaries = (
    'Linux'       =>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'.tar.gz',
    'Linux.x86_86'=>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'-64bit.tar.gz',
    #'Linux.old'   =>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'-old.tar.gz',
    'Linux.old'   =>$DownloadHome.'tree-tagger-linux-3.2-old5.tar.gz',
    # 'Darwin'      =>$DownloadHome.'tree-tagger-MacOSX-'.$TaggerVersion.'-intel.tar.gz',
    'Darwin'      =>$DownloadHome.'tree-tagger-MacOSX-'.$TaggerVersion.'.tar.gz',
    'MacOSX.PPC'  =>$DownloadHome.'tree-tagger-MacOSX-'.$TaggerVersion.'.tar.gz',
    'Solaris'     =>$DownloadHome.'tree-tagger-'.$TaggerVersion.'.tar.gz',
    'Windows'     =>$DownloadHome.'tree-tagger-windows-'.$TaggerVersion.'.zip' 
    );

# https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/tagger-scripts.tar.gz

my $TaggerScripts   = $DownloadHome.'tagger-scripts.tar.gz';
my $TaggerInstaller = $DownloadHome.'install-tagger.sh';

# available parameter files (see https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/)

my %TaggerModels = ();
@{$TaggerModels{'Linux'}} = (
    $DownloadHome.'bulgarian.par.gz',
    $DownloadHome.'catalan.par.gz',
    $DownloadHome.'czech.par.gz',
    $DownloadHome.'danish.par.gz',
    $DownloadHome.'dutch.par.gz',
    $DownloadHome.'dutch2.par.gz',
    $DownloadHome.'english.par.gz',
    $DownloadHome.'english-bnc.par.gz',
    $DownloadHome.'estonian.par.gz',
    $DownloadHome.'finnish.par.gz',
    $DownloadHome.'french.par.gz',
    $DownloadHome.'old-french.par.gz',
    $DownloadHome.'galician.par.gz',
    $DownloadHome.'german.par.gz',
    $DownloadHome.'german-spoken.par.gz',
    $DownloadHome.'middle-high-german.par.gz',
    $DownloadHome.'greek.par.gz',
    $DownloadHome.'ancient-greek.par.gz',
    $DownloadHome.'italian.par.gz',
    $DownloadHome.'italian2.par.gz',
    $DownloadHome.'korean.par.gz',
    $DownloadHome.'latin.par.gz',
    $DownloadHome.'latinIT.par.gz',
    $DownloadHome.'mongolian.par.gz',
    $DownloadHome.'norwegian.par.gz',
    $DownloadHome.'polish.par.gz',
    $DownloadHome.'portuguese.par.gz',
    $DownloadHome.'portuguese-finegrained.par.gz',
    $DownloadHome.'portuguese2.par.gz',
    $DownloadHome.'romanian.par.gz',
    $DownloadHome.'russian.par.gz',
    $DownloadHome.'slovak.par.gz',
    $DownloadHome.'slovak2.par.gz',
    $DownloadHome.'slovenian.par.gz',
    $DownloadHome.'spanish.par.gz',
    $DownloadHome.'spanish-ancora.par.gz',
    $DownloadHome.'swahili.par.gz',
    $DownloadHome.'swedish.par.gz'
    );
$TaggerModels{'Darwin'} = $TaggerModels{'Linux'};
$TaggerModels{'Windows'} = $TaggerModels{'Linux'};

@{$TaggerModels{'Solaris'}} = (
    $DownloadHome.'bulgarian-par-3.1.bin.gz',
    $DownloadHome.'dutch-par-3.1.bin.gz',
#    $DownloadHome.'dutch2-par-3.1.bin.gz',
    $DownloadHome.'english-par-3.2.bin.gz',
    $DownloadHome.'french-par-3.2.bin.gz',
    $DownloadHome.'german-par-3.2.bin.gz',
    $DownloadHome.'italian-par-3.1.bin.gz',
#    $DownloadHome.'italian-par2-3.1.bin.gz',
    $DownloadHome.'spanish-par-3.1.bin.gz'
    );
$TaggerModels{'MacOSX.PPC'} = $TaggerModels{'Solaris'};


requires 'Uplug'     => '0';

my @argv = @ARGV;
@ARGV = ();
install_treetagger() unless ($ARGV[0] eq 'skip-compile');
@ARGV = @argv;

# auto_install;
install_share;

WriteAll;





sub install_treetagger{
    my $system = `uname -s`;chomp($system);
    my $architecture = `uname -m`;chomp($architecture);

    use Cwd;
    my $pwd = getcwd;
    mkdir('share/ext/') unless (-d 'share/ext/');
    mkdir('share/ext/tree-tagger') unless (-d 'share/ext/tree-tagger');
    chdir('share/ext/tree-tagger/');

    my $url;
    if ( exists $TaggerBinaries{"$system.$architecture"} ){
	$url = $TaggerBinaries{"$system.$architecture"};
    }
    elsif ( exists $TaggerBinaries{$system} ){
	$url = $TaggerBinaries{$system};
    }
    else{
	die "cannot find any binaries that match you environment!\n";
    }

    my $models = [];
    if ( exists $TaggerModels{"$system.$architecture"} ){
	$models = $TaggerModels{"$system.$architecture"};
    }
    elsif ( exists $TaggerModels{$system} ){
	$models = $TaggerModels{$system};
    }

    my $license = get($TaggerLicense);
    print $license;
    print "\n-----------------------------------------\n";
    print "Do you agree with the license above? (y/n)";
    print "\n-----------------------------------------\n";
    my $answer = <>;
    exit 1 unless ($answer eq "y\n");

    # download binaries, scriprts and all model files

    print "Download binaries and scripts ....\n";
    print "fetch $url\n";
    unlink('install-tagger.sh');
    unlink('tagger-scripts.tar.gz');
    my_getstore($url, basename($url));
    my_getstore($TaggerScripts, 'tagger-scripts.tar.gz');
    my_getstore($TaggerInstaller, 'install-tagger.sh');

    print "Download tagging models ....\n";
    foreach my $m (@{$models}){
	print " - $m\n";
	my_getstore($m,basename($m));
    }

    # install (using the provided install script)

    print "Unpack all archives ....\n";
    system( 'chmod +x install-tagger.sh' );
    system( './install-tagger.sh' );

    # sometimes we can get kernel problems
    # --> try an older version
    if ($system eq 'Linux'){
	if (! -e 'bin/tree-tagger' ){
	    my $tarfile = basename($url);
	    system("tar -xzf $tarfile");
	    system( './install-tagger.sh' );
	    system('chmod +x bin/*');
	    system('chmod +x cmd/*');
	}
    	my $testrun = `bin/tree-tagger 2>&1`;
    	if ($testrun!~/USAGE/s){
    	     my $oldurl = $TaggerBinaries{'Linux.old'};
    	     print "fetch $oldurl\n";
    	     my_getstore($oldurl, basename($oldurl));
    	     rename(basename($oldurl),basename($url));
    	     system( './install-tagger.sh' );
	     $testrun = `bin/tree-tagger 2>&1`;
	     unless ($testrun=~/USAGE/s){
		 die "Problems with tree-tagger binaries!";
	     }
    	}
    }

    print "remove temporary downloads ....\n";
    system( 'rm -f *.gz *.zip' );
    print "Done!\n\n";

    chdir($pwd);
}


# get data from the ftp-server
# in case LWP::Simple doesn't work: try to call wget

sub my_getstore{
  my $url = shift;
  my $status = getstore($url, basename($url) );
  unless ( is_success($status)){
    system("wget $url");
  }
  unless (-e basename($url)){
    die "cannot fetch $url!\n";
  }
  return 1;
}
