use ExtUtils::MakeMaker;
my $mm = $ExtUtils::MakeMaker::VERSION;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::GoogleMaps::V3',
    VERSION_FROM      => 'lib/HTML/GoogleMaps/V3.pm',
    PREREQ_PM         => {
      'Geo::Coder::Google' => .16,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/GoogleMaps/V3.pm',
       AUTHOR         => 'Lee Johnson <leejo@cpan.org>') : ()),
    (
        $mm < 6.46
        ? ()
        : (
            META_MERGE => {
                requires  => { perl => '5.005' },
                resources => {
                    homepage   => 'https://metacpan.org/module/HTML/GoogleMaps/V3',
                    repository => 'https://github.com/G3S/html-googlemaps-v3',
                    bugtracker => 'https://github.com/G3S/html-googlemaps-v3/issues',
                },
                no_index => { directory => [qw/t/] },
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
);
