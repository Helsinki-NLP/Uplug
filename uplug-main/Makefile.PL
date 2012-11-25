use inc::Module::Install;

name          'Uplug';
license       'gpl';
all_from      'lib/Uplug.pm';

install_script 'uplug';

install_script 'bin/uplug-tok';
install_script 'bin/uplug-sent';
install_script 'bin/uplug-malt';
install_script 'bin/uplug-parse-sv';
install_script 'bin/uplug-coocstat';
install_script 'bin/uplug-hunalign';
install_script 'bin/uplug-ngramstat';
install_script 'bin/uplug-tokext';
install_script 'bin/uplug-chunk';
install_script 'bin/uplug-coocstat-slow';
install_script 'bin/uplug-linkclue';
install_script 'bin/uplug-sentalign';
install_script 'bin/uplug-toktag';
install_script 'bin/uplug-convert'; 
install_script 'bin/uplug-markphr'; 
install_script 'bin/uplug-split';   
install_script 'bin/uplug-coocfreq';
install_script 'bin/uplug-giza';
install_script 'bin/uplug-markup';  
install_script 'bin/uplug-strsim';  
install_script 'bin/uplug-wordalign';
install_script 'bin/uplug-coocfreq-slow';
install_script 'bin/uplug-gma';
install_script 'bin/uplug-ngramfreq';
install_script 'bin/uplug-tag';

install_script 'bin/evalalign.pl';
install_script 'bin/uplugalign.pl';

install_share;

requires 'XML::Parser'     => 0;
requires 'XML::Simple'     => 0;
requires 'File::ShareDir'  => 0;

WriteAll;
