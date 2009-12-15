use strict;
use warnings;

use inc::Module::Install;

license             'mit';

name                'HTTP-Link-Parser';
author              'Toby Inkster <tobyink@cpan.org>';
perl_version_from   'lib/HTTP/Link/Parser.pm';
version_from        'lib/HTTP/Link/Parser.pm';
abstract_from       'lib/HTTP/Link/Parser.pm';
readme_from         'lib/HTTP/Link/Parser.pm';

test_requires       'Test::More' => '0.61';

requires            'Encode'             => 0;
requires            'RDF::Trine'         => '0.112';
requires            'URI'                => '1.30';
requires            'URI::Escape'        => '3.00';

auto_set_homepage;
auto_set_bugtracker;

include 'Test::Signature';
auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
