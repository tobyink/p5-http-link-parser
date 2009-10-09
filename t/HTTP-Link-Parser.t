# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTTP-Link-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('HTTP::Link::Parser') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use HTTP::Response;
my $response = HTTP::Response->new( 200 );
$response->push_header("Base" => "http://example.org/subject");
$response->push_header("Link" => "<http://example.net/absolute>; rel=\"http://example.net/rel/one http://example.net/rel/two\"; title=\"absolute\"");
$response->push_header("Link" => "<relative>; rel=\"three\"; title=\"relative\"");
$response->push_header("Link" => "<nextdoc>; rel=\"next\"; title=\"relative\"; type=\"TEXT/HTML\"; hreflang=en");
$response->push_header("Link" => "<subject>; rel=\"prev\"; title=\"subject\"; anchor=\"nextdoc\"");
$response->push_header("Link" => "<author>; rev=\"made\"; title=\"author\";");

my $rdf = HTTP::Link::Parser::parse_links_to_rdf($response);

ok(defined $rdf->{'http://example.net/absolute'} , "absolute targets");
ok(defined $rdf->{'http://example.org/relative'} , "relative targets");

is(
	$rdf->{'http://example.org/subject'}->{'http://example.net/rel/one'}->['0']->{'value'} ,
	"http://example.net/absolute",
	"absolute relationships");

is(
	$rdf->{'http://example.org/subject'}->{'http://www.iana.org/assignments/relation/three'}->['0']->{'value'} ,
	"http://example.org/relative",
	"relative relationships");

is(
	$rdf->{'http://example.org/subject'}->{'http://example.net/rel/two'}->['0']->{'value'} ,
	"http://example.net/absolute",
	"space-separated relationships");

is(
	$rdf->{'http://example.org/nextdoc'}->{'http://www.iana.org/assignments/relation/prev'}->['0']->{'value'} ,
	"http://example.org/subject",
	"the 'anchor' link parameter");

is(
	$rdf->{'http://example.org/author'}->{'http://www.iana.org/assignments/relation/made'}->['0']->{'value'} ,
	"http://example.org/subject",
	"the 'rev' link parameter");

is(
	$rdf->{'http://example.org/author'}->{'http://purl.org/dc/terms/title'}->['0']->{'value'} ,
	"author",
	"the 'title' link parameter");
	
is(
	$rdf->{'http://example.org/subject'}->{'http://purl.org/dc/terms/title'}->['0']->{'value'} ,
	"subject",
	"the 'title' link parameter, with 'anchor'");

is(
	$rdf->{'http://example.org/nextdoc'}->{'http://purl.org/dc/terms/language'}->['0']->{'value'} ,
	"http://www.lingvoj.org/lingvo/en",
	"the 'hreflang' link parameter");

is(
	$rdf->{'http://example.org/nextdoc'}->{'http://purl.org/dc/terms/format'}->['0']->{'value'} ,
	"http://www.iana.org/assignments/media-types/text/html",
	"the 'type' link parameter");
