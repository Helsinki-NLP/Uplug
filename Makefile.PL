use ExtUtils::MakeMaker;

my @bin_files = <bin/*.pl>;
push @bin_files, "uplug";

WriteMakefile(
        NAME            => 'Uplug',
        VERSION_FROM    => 'Uplug.pm',
	INSTALLBIN      => 'bin/bin',
        EXE_FILES => \@bin_files
);
