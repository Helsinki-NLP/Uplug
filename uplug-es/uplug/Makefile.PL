use inc::Module::Install;

name          'Uplug';
version       '0.1';
license       'gpl';

install_script '../svmtool/bin/SVMTagger.pl';
install_script '../svmtool/bin/SVMTagger_utf8.pl';
install_script '../svmtool/bin/SVMTeval.pl';
install_script '../svmtool/bin/SVMTlearn.pl';

install_share;

requires 'Uplug'     => 0;
requires 'SVMTool'   => '1.3.2';

WriteAll;
