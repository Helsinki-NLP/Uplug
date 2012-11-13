use inc::Module::Install;

name          'Uplug';
all_from      'lib/Uplug.pm';

install_script 'uplug';

install_script 'bin/beaparse.pl';
install_script 'bin/coocstat.pl';
install_script 'bin/hunalign.pl';
install_script 'bin/ngramstat.pl';
install_script 'bin/tokext.pl';
install_script 'bin/chunk.pl';
install_script 'bin/coocstat_slow.pl';
install_script 'bin/linkclue.pl';
install_script 'bin/sentalign.pl';
install_script 'bin/toktag.pl';
install_script 'bin/convert.pl'; 
install_script 'bin/evalalign.pl';
install_script 'bin/markphr.pl'; 
install_script 'bin/split.pl';   
install_script 'bin/uplugalign.pl';
install_script 'bin/coocfreq.pl';
install_script 'bin/giza.pl';
install_script 'bin/markup.pl';  
install_script 'bin/strsim.pl';  
install_script 'bin/wordalign.pl';
install_script 'bin/coocfreq_slow.pl';
install_script 'bin/gma.pl';
install_script 'bin/ngramfreq.pl';
install_script 'bin/tag.pl';

install_share;

requires 'XML::Parser'     => 0;

WriteAll;
