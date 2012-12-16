use inc::Module::Install;

name          'Uplug';
version       '0.2';
license       'gpl';

abstract    'Catalan language pack for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';

# make sure that SVMTagger scripts are in your path
my $tagger = `which SVMTagger.pl`;
chomp $tagger;
unless (-e $tagger){
  install_script 'bin/SVMTagger.pl';
  install_script 'bin/SVMTagger_utf8.pl';
}

requires 'Uplug'     => 0;
requires 'SVMTool'   => '1.3.2';

# auto_install;
install_share;

WriteAll;
