use Module::Build;
my $build = Module::Build->new(
    module_name => 'Solaris::Disk::Mnttab',
    license     => 'perl',
    dist_version_from => 'lib/Solaris/Disk/Mnttab.pm',
    requires    => {
        'perl'          => '5.6.1',
    },
    recommends => {
        'Test::More' => '0',
    },
    add_to_cleanup => [ '*~', '*/*~', '*/*/*/*~' ],
    gzip => 'gzip -9f',
);
$build->create_build_script;
