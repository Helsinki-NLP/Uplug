use ExtUtils::MakeMaker;

my @bin_files = <bin/*.pl>;
push @bin_files, "uplug";

WriteMakefile(
        NAME            => 'Uplug',
        VERSION_FROM    => 'Uplug.pm',
        EXE_FILES => \@bin_files
);
