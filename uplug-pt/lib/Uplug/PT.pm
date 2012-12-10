
package Uplug::DE;


=head1 NAME

Uplug::PT - Uplug Language pack for Portuguese

=head1 SYNOPSIS

 # prepare some data
 uplug pre/markup -in input.txt | uplug pre/sent -l pt > sentences.xml
 uplug pre/pt/basic -in input.txt -out tokenized.xml

 # tag tokenized text in XML
 uplug pre/pt/tagHunPos -in tokenized.xml -out tagged.xml

 # parse a tagged corpus using the MaltParser
 uplug pre/pt/malt -in tagged -out parsed.xml

 # run the entire pipeline
 uplug pre/pt-all -in input.txt -out output.xml

=head1 DESCRIPTION

Note that you need to install the main components of L<Uplug> first. Download the latest version of uplug-main from L<https://bitbucket.org/tiedemann/uplug> or from CPAN and install it on your system.

The Uplug::PT package includes configuration files for running annotation tools for Portuguese. To install configuration files and models, simply run:

 perl Makefile.PL
 make
 make install

=head1 SEE ALSO

Project website: L<https://bitbucket.org/tiedemann/uplug>

CPAN: L<http://search.cpan.org/~tiedemann/uplug-main/>

=cut

1;
