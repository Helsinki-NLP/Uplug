use inc::Module::Install;

name          'Uplug';
version       '0.1';
license       'gpl';

abstract    'Japanese language pack for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';

requires              'Uplug'     => 0;
# requires_external_bin 'chasen';

# auto_install;
install_share;

WriteAll;
