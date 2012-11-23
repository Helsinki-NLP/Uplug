%define prefix /usr
%define PACKAGE chasen
%define VERSION 2.2.9
%define RELEASE 1

Summary: Japanese Morphological Analysis System, ChaSen
Name: %{PACKAGE}
Version: %{VERSION}
Release: %{RELEASE}
Source: %{name}-%{version}.tar.gz
Copyright: 1999 Nara Institute of Science and Technology, Japan.
URL: http://chasen.aist-nara.ac.jp/
BuildRoot: /var/tmp/%{name}-%{version}-root
Group: Extensions/Japanese
Provides: chasen
Vendor: ��䥴�����ȯô���Խ���
Distribution: ��䥴�����ȯô���Խ���
Packager: Taku Kudoh <taku-ku@is.aist-nara.ac.jp>

%description
�׻����ˤ�����ܸ�β��Ϥˤ����ơ����Ƥθ���β��Ϥ���٤Ƥޤ�����ˤʤ��
�˼���2��������ޤ�����ĤϷ����ǲ��Ϥ�����Ǥ�����ɥץ��å�����ڤʤ�
�ˤ�ä����ܸ�����Ϥˤ��礭�����꤬�ʤ��ʤ�ޤ��������׻����ˤ�����ܸ��
�ϤǤϡ��ޤ�����ʸ��θġ��η����Ǥ�ǧ������ɬ�פ�����ޤ�������ˤϼ��Ѥ�
�Ѥ�����������礭�ʼ����ɬ�פǤ��ꡤ�����ǡ�����������뤫�Ȥ��������
Ʊ����¸�ߤ��ޤ����⤦��Ĥ�����Ȥ��ơ����ܸ�ˤϹ���ǧ����Ʊ�դ������
��ʸˡ���ʤ�����ʸˡ�Ѹ줬�ʤ��Ȥ������¤Ǥ����ع�ʸˡ��ñ��ʬ�प���ʸˡ
�Ѹ�ϰ��̤ˤϹ����Τ��Ƥ��ޤ���������Ԥδ֤ǤϤ��ޤ�ɾȽ���褯����ޤ�
�󤷡��׻��������ǤϤ���ޤ���

���ܸ�β��Ϥ˿������ɬ�פʷ����ǲ��ϥ����ƥ�ϡ�¿���θ��楰�롼�פˤ��
�ƴ��˳�ȯ���쵻��Ū�����꤬�����Ф���Ƥ���ˤⷸ��餺�����̤Υġ���Ȥ�
���������ή�ۤ��Ƥ����ΤϤ���ޤ��󡥷׻������ɤ����ܸ켭��ˤĤ��Ƥ�Ʊ
�ͤǤ��� 

�ܥ����ƥ�ϡ��׻����ˤ�����ܸ�β��Ϥθ�����ܻؤ�¿���θ���Ԥ˶��̤˻�
��������ǲ��ϥġ�����󶡤��뤿��˳�ȯ����ޤ��������κݡ��������ܤ���
���ѼԤˤ�ä�ʸˡ�������ñ��֤���³�ط�������ʤɤ��ưפ��ѹ�
�Ǥ���褦����θ���ޤ�����

��ؤǾ��Ϳ��ǳ�ȯ���������ƥ�Ǥ��ꡤ�����������Դ�������ʬ������Ȼפ���
������ǽ�ʸ¤�缡���ɤ�Ťͤ�ͽ��Ǥ������ͤδ��Ƥ����Ѥ򤪴ꤤ�������ޤ��� 


����䥥����ƥ�θ����ϡ��������Ĺ�����漼�����������ü�ʳص�����ر����
���ܸ��漼�ˤ����Ƴ�ȯ���줿���ܸ�����ǲ��ϥ����ƥ�JUMAN(version2.0)�Ǥ���
JUMAN�ϡ�������ؤ����������ü�ʳص�����ر���ؤΥ����åդ����¿���γ���
�ζ��Ϥ����ƺ���������ΤǤ����ޤ�������˴ؤ��Ƥϡ�Wnn���ʴ����Ѵ������ƥ�
�μ��񡤤���ӡ�ICOT����������줿���ܸ켭������Ѥ����ȼ��˽�����ä��ޤ�
����JUMAN 2.0��Ȥ�˳�ȯ����������ؤι������פ��󡤸��ߥ���Υ��̳��̯��
͵����ˤ��ä˴��դ������ޤ���

JUMAN��ȯ�Τ��ä������äƲ����ä��������Ĺ���������˴��դ��ޤ���JUMAN��
ȯ�˴ؤ����͡��ʷ��Ƕ��Ϥ��Ƥ���������������ü�籧��Ϥ��λ�˴��դ��ޤ���
������ü�����ǰ�����ˤϡ���䥥����ƥ�γ�ȯ�˴ؤ���¿���ν����򤤤�����
�ޤ�����
������ü��߳ػ��κ��콤�ᡤ��¼ͧ����ˤ����1.0�γ�ȯ�κݤ˼�ν�
�Ϥ򤤤������ޤ�����ξ�ᤪ�����䥤γ�ȯ�˶��Ϥ������������ܸ��漼�Υ�
��С��˿������դ��ޤ���
������ü��μ���������������ɽ�Ȥ�������ܸ�ǥ����ơ�����
����ܥ��եȥ������γ�ȯ�ץ��롼�פ������ˤϡ�IPA�ʻ��ηϼ����������
������ԤäƤ��������ޤ������äˡ�����Ϥ����������Żҵ�����縦����
��ƣ�ᡤASTEM�λ����ƻ�˴��դ������ޤ���
�ޤ�����Ͱ�ͤ�̾��󤲤뤳�ȤϤǤ��ޤ��󤬡�JUMAN�����ƥप���
��䥥����ƥ���Ф���¿���Υ����Ȥȼ���򤤤����������ѼԤ������˴��դ��ޤ���


�ܥ����ƥ�˴ؤ��뤪�䤤��碌�ϰʲ��ˤ��ꤤ���ޤ���

��630-0101
���ɸ�����Թ⻳Į8916-5
������ü�ʳص�����ر����
����ʳظ���� ���ܸ��漼
��䥴�����ȯô���Խ���
Tel: (0743)72-5240, Fax: (0743)72-5249
E-mail: chasen@cl.aist-nara.ac.jp

%package devel
Summary: Libraries and header files for ChaSen developers
Group: Development/Libraries
Requires: %name = %{VERSION}

%package perl
Summary: ChaSen Perl Module
Group: Extensions/Japanese
Requires: perl >= 5.6
Requires: %name = %{VERSION}

%description devel
Libraries and header files for ChaSen developers.
��䥤Υ饤�֥��ȥإå��ե�����Ǥ�.

%description perl
ChaSen Perl Module.
���Υ⥸�塼��ϡ�������ü�ʳص�����ؤ��������������ǲ��ϥ��եȥ�����
����䥡פ�perl���鰷������Τ�ΤǤ�.

%prep

%setup

%build
./configure --prefix=%{prefix}
make CFLAGS="$RPM_OPT_FLAGS"

cd perl; perl Makefile.PL
make INC="-I../src -I%{prefix}/include -I/usr/include" \
     LDDLFLAGS="-shared -Wl,-rpath -Wl,%{prefix}/lib -L../lib/.libs -lchasen"
     CCFLAGS="$CCFLAGS -Dna=PL_na -Dsv_undef=PL_sv_undef"
cd ..

%install
make prefix=$RPM_BUILD_ROOT%{prefix} install

cd perl
make PREFIX=$RPM_BUILD_ROOT%{prefix} INSTALLMAN3DIR=$RPM_BUILD_ROOT%{prefix}/man/man3 install
cd ..

%clean
rm -rf $RPM_BUILD_ROOT

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files 
%defattr(-,root,root,-)
%doc doc/*.tex doc/*.pdf
%{prefix}/bin/*
%{prefix}/lib/*.so.*
%{prefix}/share/chasen/prolog/*
%{prefix}/libexec/chasen/*

%files devel
%defattr(-,root,root,-)
%{prefix}/include/*
%{prefix}/lib/*.so
%{prefix}/lib/*.a
%{prefix}/lib/*.la

%files perl
%defattr(-,root,root,-)
%doc perl/README
%{prefix}/lib/perl5/site_perl/*
%{prefix}/man/*
