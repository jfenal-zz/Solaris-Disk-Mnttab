use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Solaris::Disk::Mnttab',

    #   PREREQ_PM    => { undef },
    PM => {
        map {
            ( "lib/$_.pm" => "\$(INST_LIBDIR)/" . ( split /\// )[-1] . ".pm" )
          } qw(
          Solaris/Disk/Mnttab
          )
    },
    VERSION => '0.04',

    #   EXE_FILES    => [ ],
    PL_FILES => {},
    AUTHOR   => 'Jérôme Fenal <jfenal@free.fr>',
    ABSTRACT => 'Read Solaris list of mounted devices',
    clean    => { FILES => '*/*/*~' },
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
