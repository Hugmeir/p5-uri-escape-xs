use strict;
use warnings;
use ExtUtils::MakeMaker;

use if $] < 5.014, "Devel::CallChecker";
use if $] < 5.014, "IO::File";

write_header('callchecker0.h', &Devel::CallChecker::callchecker0_h) if $] < 5.014;

sub write_header {
    my ($header, $content) = @_;
    my $fh = IO::File->new($header, 'w') or die $!;
    $fh->print($content) or die $!;
    $fh->close or die $!;
}

WriteMakefile(
    NAME          => 'URI::Escape::XS',
    AUTHOR        => 'Dan Kogai <dankogai+cpan@gmail.com>',
    VERSION_FROM  => 'lib/URI/Escape/XS.pm',
    ABSTRACT_FROM => 'lib/URI/Escape/XS.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => { 'Test::More' => 0, },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'URI-Escape-XS-*' },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/dankogai/p5-uri-escape-xs.git',
                web => 'https://github.com/dankogai/p5-uri-escape-xs',
            },
        },
    },
);
