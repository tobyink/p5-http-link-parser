use lib "lib";
use HTTP::Link::Parser ':all';

foreach my $f (qw(parse_links_to_list parse_links_to_rdfjson parse_links_into_model parse_single_link relationship_uri jumpy))
{
	eval { print $f, " : ", eval('defined &'.$f.';'), "\n"; };
}