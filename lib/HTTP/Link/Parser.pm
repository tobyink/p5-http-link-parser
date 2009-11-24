package HTTP::Link::Parser;

use 5.006000;
use strict;
no warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
	'all' => [ qw(parse_links_to_list parse_links_to_rdfjson parse_links_into_model relationship_uri) ],
	'standard' => [ qw(parse_links_to_list parse_links_to_rdfjson parse_links_into_model) ]
	);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = ( );

our $VERSION = '0.02';

use RDF::Trine;
use URI;
use URI::Escape;

sub relationship_uri
{
	my $str = shift;

	if ($str =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $str;
	}

	return 'http://www.iana.org/assignments/relation/' . (lc $str);

	my $url = url (lc $str), 'http://www.iana.org/assignments/relation/';
	return $url->abs->as_string;

	return undef;
}

sub parse_header
{
	my $hdrv = shift;
	my $base = shift;
	my $rv   = {};
	
	my $uri  = undef;
	if ($hdrv =~ /^(\s*<([^>]*)>\s*)/)
	{
		$uri  = $2;
		$hdrv = substr($hdrv, length($1));
	}
	else
	{
		return $rv;
	}
	
	$rv->{'URI'} = URI->new_abs($uri, $base);
	
	while ($hdrv =~ /^(\s*\;\s*(\/|[a-z0-9-]+)\s*\=\s*("[^"]*"|'[^']*'|[^\s\'\"\;\,]+)\s*)/i)
	{
		$hdrv = substr($hdrv, length($1));
		my $key = lc $2;
		my $val = $3;
	
		$val =~ s/(^"|"$)//g if ($val =~ /^".*"$/);
		$val =~ s/(^'|'$)//g if ($val =~ /^'.*'$/ && $3 !~ /^".*"$/);
			
		if ($key eq 'rel')
		{
			$val =~ s/(^\s+)|(\s+$)//g;
			$val =~ s/\s+/ /g;
			
			my @rels = split / /, $val;
			foreach my $rel (@rels)
				{ push @{ $rv->{'rel'} }, $rel; }
		}
		elsif ($key eq 'rev')
		{
			$val =~ s/(^\s+)|(\s+$)//g;
			$val =~ s/\s+/ /g;
			
			my @rels = split / /, $val;
			foreach my $rel (@rels)
				{ push @{ $rv->{'rev'} }, $rel; }
		}
		elsif ($key eq 'anchor')
		{
			$rv->{'anchor'} = URI->new_abs($val, $base);
		}
		else
		{
			$rv->{ $key } = $val;
		}
	}
	
	return $rv;
}

sub parse_links_to_list
{
	my $response = shift;
	my $rv       = [];
	my $base     = URI->new($response->base);
	
	foreach my $header ($response->header('link'))
	{
		push @$rv, parse_header($header, $base);
	}
	
	return $rv;
}

sub parse_links_into_model
{
	my $response =  shift;
	my $model    =  shift
	             || RDF::Trine::Model->new( RDF::Trine::Store::DBI->temporary_store );
	
	my $json = parse_links_to_rdfjson($response);

	foreach my $s (keys %$json)
	{
		my ($ts, $tp, $to);
		
		if ($s =~ /^_:(.*)$/)
		{
			$ts = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$ts = RDF::Trine::Node::Resource->new($s);
		}
		
		foreach my $p (keys %{ $json->{$s} })
		{
			$tp = RDF::Trine::Node::Resource->new($p);
			
			foreach my $o (@{ $json->{$s}->{$p} })
			{
				if ($o->{'type'} eq 'bnode')
				{
					$to = RDF::Trine::Node::Blank->new((substr $o->{'value'}, 2));
				}
				elsif ($o->{'type'} eq 'uri')
				{
					$to = RDF::Trine::Node::Resource->new($o->{'value'});
				}
				else
				{
					$to = RDF::Trine::Node::Literal->new($o->{'value'}, $o->{'lang'}, $o->{'datatype'});
				}
				
				if ($ts && $tp && $to)
				{
					my $st = RDF::Trine::Statement->new($ts, $tp, $to);
					$model->add_statement($st);
				}
			}
		}
	}
	
	return $model;
}

sub parse_links_to_rdfjson
{
	my $response = shift;
	my $base     = URI->new($response->base);
	my $links    = parse_links_to_list($response);
	my $rv       = {};
	
	foreach my $link (@$links)
	{
		my $subject = $base;
		
		$subject = $link->{'anchor'}
			if defined $link->{'anchor'};
		
		my $object = $link->{'URI'};
		
		foreach my $r (@{ $link->{'rel'} })
		{
			my $r1 = relationship_uri($r);
			push @{ $rv->{ $subject }->{ $r1 } },
				{
					'value'    => "$object",
					'type'     => 'uri',
				};
		}

		foreach my $r (@{ $link->{'rev'} })
		{
			my $r1 = relationship_uri($r);
			push @{ $rv->{ $object }->{ $r1 } },
				{
					'value'    => "$subject",
					'type'     => 'uri',
				};
		}
		
		if (defined $link->{'title'})
		{
			push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/title' } },
				{
					'value'    => $link->{'title'},
					'type'     => 'literal',
				};
		}
		
		if (defined $link->{'hreflang'})
		{
			push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/language' } },
				{
					'value'    => 'http://www.lingvoj.org/lingvo/' . uri_escape(lc $link->{'hreflang'}),
					'type'     => 'uri',
				};
		}
		
		if (defined $link->{'type'} && $link->{'type'} =~ m?([A-Z0-9\!\#\$\&\.\+\-\^\_]{1,127})/([A-Z0-9\!\#\$\&\.\+\-\^\_]{1,127})?i)
		{
			my $type    = lc $1;
			my $subtype = lc $2;
			push @{ $rv->{ $object }->{ 'http://purl.org/dc/terms/format' } },
				{
					'value'    => 'http://www.iana.org/assignments/media-types/'.uri_escape($type).'/'.uri_escape($subtype),
					'type'     => 'uri',
				};
		}
	}
	
	return $rv;
}


1;
__END__

=head1 NAME

HTTP::Link::Parser - Perl extension for parsing HTTP Link headers

=head1 VERSION

0.02

=head1 SYNOPSIS

  use HTTP::Link::Parser qw(:standard);
  use LWP::UserAgent;
  
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get("http://example.com/foo");
  
  # Link headers can be parsed into an arrayref of hashrefs.
  my $links = parse_links_to_list($response);
  foreach my $link (@$links)
  {
     printf("Link to <%s> with rel=\"%s\".\n",
        $link->{URI},
        join ' ', @{ $link->{'rel'} }
        );
  }
  
  # Or into a subject -> predicate -> arrayref-of-objects structure
  my $rdf = parse_links_to_rdf($response);
  printf("The next page is <%s>\n",
     $rdf->{'http://example.com/foo'}                        #s
         ->{'http://www.iana.org/assignments/relation/next'} #p
         ->[0]->{'value'}                                    #o
     );

=head1 DESCRIPTION

HTTP::Link::Parser parses HTTP "Link" headers found in an
HTTP::Response object. Headers should conform to the format
described in the forthcoming IETF specification.

=over 8

=item $model = parse_links_into_model($response, [$existing_model]);

C<$model> is an RDF::Trine::Model. Dublin Core is used to encode
'hreflang', 'title' and 'type' link parameters.

=item $rdf = parse_links_to_rdfjson($response);

C<$rdf> is a hashref with a structure inspired by the RDF/JSON
specification. Short forms of relationships are returned in long
form (as predicate URIs). Dublin Core is used to encode 'hreflang',
'title' and 'type' link parameters.

=item $list = parse_links_to_list($response);

C<$list> is an arrayref of hashrefs. Each hashref contains keys
corresponding to the link parameters of the link, and a key called
'URI' corresponding to the target of the link.

The 'rel' and 'rev' keys are arrayrefs containing lists of
relationships. If the Link used the short form of a registered
relationship, then the short form is present on this list. Short
forms can be converted to long forms (URIs) using the
C<HTTP::Link::Parser::relationship_uri()> function.

=item $long = HTTP::Link::Parser::relationship_uri($short);

This function is not exported by default. It may be used to convert
short strings identifying relationships, such as "next" and "prev",
into longer URIs identifying the same relationships, such as
"http://www.iana.org/assignments/relation/next" and
"http://www.iana.org/assignments/relation/prev".

=back

=head1 BUGS

Does not (yet) support the "title*" (internationalised title)
link parameter.

=head1 SEE ALSO

http://www.mnot.net/drafts/draft-nottingham-http-link-header-07.txt

L<RDF::Trine>

http://n2.talis.com/wiki/RDF_JSON_Specification

=head1 AUTHOR

Toby Inkster, E<lt>mail@tobyinkster.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Toby Inkster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
