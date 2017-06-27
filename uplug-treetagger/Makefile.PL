#-*-perl-*-

use inc::Module::Install;
use LWP::Simple;
use File::Basename;

name        'Uplug';
version     '0.3.2';

abstract    'TreeTagger add-on for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';


my $TaggerLicense = "http://www.ims.uni-stuttgart.de/~schmid/Tagger-Licence";

# TreeTagger downloads

my $DownloadHome = 'http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/';
my $TaggerVersion = '3.2.1';

my %TaggerBinaries = (
'Linux'       =>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'.tar.gz',
'Linux.x86_86'=>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'-64bit.tar.gz',
'Linux.old'   =>$DownloadHome.'tree-tagger-linux-'.$TaggerVersion.'-old.tar.gz',
'Darwin'      =>$DownloadHome.'tree-tagger-MacOSX-'.$TaggerVersion.'-intel.tar.gz',
'MacOSX.PPC'  =>$DownloadHome.'tree-tagger-MacOSX-'.$TaggerVersion.'.tar.gz',
'Solaris'     =>$DownloadHome.'tree-tagger-'.$TaggerVersion.'.tar.gz',
'Windows'     =>$DownloadHome.'tree-tagger-windows-'.$TaggerVersion.'.zip' 
    );

my $TaggerScripts   = $DownloadHome.'tagger-scripts.tar.gz';
my $TaggerInstaller = $DownloadHome.'install-tagger.sh';

my %TaggerModels = ();
@{$TaggerModels{'Linux'}} = (
    $DownloadHome.'bulgarian-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'dutch-par-linux-3.2-utf8.bin.gz',
#    $DownloadHome.'dutch2-par-linux-3.1.bin.gz',
    $DownloadHome.'english-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'french-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'german-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'italian-par-linux-3.2-utf8.bin.gz',
#    $DownloadHome.'italian-par2-linux-3.1.bin.gz',
    $DownloadHome.'spanish-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'estonian-par-linux-3.2-utf8.bin.gz',
    $DownloadHome.'swahili-par-linux-3.2.bin.gz',
    $DownloadHome.'latin-par-linux-3.2.bin.gz',
    $DownloadHome.'mongolian-par-linux-3.2.bin.gz'
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

    print "remove temporary downloads ....\n";
    system( 'rm -f *.gz *.zip' );
    print "Done!\n\n";

    chdir($pwd);
}


# get data from the ftp-server
# in case LWP::Simpledoesn't work: try to call wget

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
