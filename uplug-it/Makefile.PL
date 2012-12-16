use inc::Module::Install;

name          'Uplug';
version       '0.1';
license       'gpl';

abstract    'Italian language pack for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';

requires 'Uplug'     => 0;

# auto_install;
install_share;

WriteAll;
