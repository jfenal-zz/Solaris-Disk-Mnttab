use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Solaris::Disk::Mnttab',
#   PREREQ_PM    => { undef },
    PM           => {
                        map { ( "lib/$_.pm" => "\$(INST_LIBDIR)/" . (split /\//)[-1] . ".pm" ) }
                        qw(
                            Solaris/Disk/Mnttab
                        )
                    },
    VERSION_FROM => 'lib/Solaris/Disk/Mnttab.pm',
#   EXE_FILES    => [ ],
    PL_FILES     => {},
    AUTHOR       => 'Jérôme Fenal <jfenal@free.fr>',
    ABSTRACT     => 'Module to read Solaris /etc/mnttab',
    clean        => {FILES => '*/*/*~'},
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
