use strict;
use warnings;

use inc::Module::Install;

my $dist = 'HTTP-Link-Parser';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'mit';

requires            'Encode'             => 0;
requires            'RDF::Trine'         => '0.126';
requires            'Scalar::Util'       => 0;
test_requires       'Test::More'         => '0.61';
requires            'URI'                => '1.30';
requires            'URI::Escape'        => '3.00';

resources(
	'homepage'   => "https://metacpan.org/release/$dist",
	'repository' => "http://goddamn.co.uk/svn-web/perlmods/browse/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);

keywords(qw(RFC5988 Link HTTP RDF Semantics Relationships Rel));

write_doap_changes;
write_doap_changes_xml;

include 'Test::Signature';
auto_install;

WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
