#
# $Id$

package Text::ChaSen;

=head1 NAME

Text::ChaSen - ChaSen library module for perl

=head1 SYNOPSIS

 use Text::ChaSen;

 $res = Text::ChaSen::getopt_argv('chasen-perl', '-j', '-F', '%m ');
 $str = Text::ChaSen::sparse_tostr("���ܸ��ʸ����");

=head1 DESCRIPTION

���Υ⥸�塼��ϡ�������ü�ʳص�����ؤ���ȯ�������ܸ�����ǲ���
���եȥ�����"���"��perl����Ȥ�����Τ�ΤǤ��롣

=over 4

=item getopt_argv($arg1, $arg2, ...)

��䦤˥��ץ������Ϥ����������Ԥ������ץ����ϡ�chasen���ޥ��
�˻���Ǥ����Τ˽ऺ�뤬��C<-s>��C<-D>�ʤɤΥ����Ф䥯�饤����Ȥ˴ؤ���
���ץ��������ѤǤ��ʤ���
�ޤ������ֺǽ�Υ��ץ����ϥץ����Υե�����̾�Ǥ��롣

=back

�㤨�С����Τ褦�ʰ����Ǽ¹Ԥ���chasen���ޥ�ɤ����롣

$ chasen C<-j> C<-F> '%m '

�����Ʊ����ư�򤵤���ˤϡ����Τ褦�ʰ�����getopt_argv��ƤӽФ���

getopt_argv('chasen', 'C<-j>', 'C<-F>', '%m ');

=item sparse_tostr($str)

�����ǲ��Ϥ�Ԥ�����̤�ʸ����Ȥ����֤���

=item sparse_tostr_long($str)

�����ǲ��Ϥ�Ԥ�����̤�ʸ����Ȥ����֤������δؿ��ϡ������ΥС������
�Ȥθߴ����Τ��������¸�ߤ��롣

=head1 COPYRIGHT

Copyright(c) 1998, 1999 NOKUBI Takatsugu <knok@daionet.gr.jp>
Copyright(c) 1997 Nara Institute of Science and Technorogy.
All Rights Reserved.

Use, reproduction, and distribution of this software is permitted.
Any copy of this software, whether in its original form or modified,
must include both the above copyright notice and the following
paragraphs.

Nara Institute of Science and Technology (NAIST),
the copyright holders, disclaims all warranties with regard to this
software, including all implied warranties of merchantability and
fitness, in no event shall NAIST be liable for
any special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an
action of contract, negligence or other tortuous action, arising out
of or in connection with the use or performance of this software.

The Japanese morphological dictionary included in this system
originates from ICOT Free Software.  The following conditions for ICOT
Free Software applies to the morphological dictionary of the system.

Each User may also freely distribute the Program, whether in its
original form or modified, to any third party or parties, PROVIDED
that the provisions of Section 3 ("NO WARRANTY") will ALWAYS appear
on, or be attached to, the Program, which is distributed substantially
in the same form as set out herein and that such intended
distribution, if actually made, will neither violate or otherwise
contravene any of the laws and regulations of the countries having
jurisdiction over the User or the intended distribution itself.

NO WARRANTY

The program was produced on an experimental basis in the course of the
research and development conducted during the project and is provided
to users as so produced on an experimental basis.  Accordingly, the
program is provided without any warranty whatsoever, whether express,
implied, statutory or otherwise.  The term "warranty" used herein
includes, but is not limited to, any warranty of the quality,
performance, merchantability and fitness for a particular purpose of
the program and the nonexistence of any infringement or violation of
any right of any third party.

Each user of the program will agree and understand, and be deemed to
have agreed and understood, that there is no warranty whatsoever for
the program and, accordingly, the entire risk arising from or
otherwise connected with the program is assumed by the user.

Therefore, neither ICOT, the copyright holder, or any other
organization that participated in or was otherwise related to the
development of the program and their respective officials, directors,
officers and other employees shall be held liable for any and all
damages, including, without limitation, general, special, incidental
and consequential damages, arising out of or otherwise in connection
with the use or inability to use the program or any product, material
or result produced or otherwise obtained by using the program,
regardless of whether they have been advised of, or otherwise had
knowledge of, the possibility of such damages at any time during the
project or thereafter.  Each user will be deemed to have agreed to the
foregoing by his or her commencement of use of the program.  The term
"use" as used herein includes, but is not limited to, the use,
modification, copying and distribution of the program and the
production of secondary products from the program.

In the case where the program, whether in its original form or
modified, was distributed or delivered to or received by a user from
any person, organization or entity other than ICOT, unless it makes or
grants independently of ICOT any specific warranty to the user in
writing, such person, organization or entity, will also be exempted
from and not be held liable to the user for any such damages as noted
above as far as the program is concerned.

=cut

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(getopt_argv sparse_tostr fparse_tostr sparse_tostr_long);
%EXPORT_TAGS = (all => [qw(getopt_argv sparse_tostr fparse_tostr
 sparse_tostr_long)]);

$VERSION = '1.03';

bootstrap Text::ChaSen $VERSION;

1;
__END__
                pos = (unsigned char *) "";
