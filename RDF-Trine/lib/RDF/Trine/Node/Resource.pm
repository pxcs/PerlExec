# RDF::Trine::Node::Resource
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Trine::Node::Resource - RDF Node class for resources

=cut

package RDF::Trine::Node::Resource;

use strict;
use warnings;
no warnings 'redefine';
use base qw(RDF::Trine::Node);

use URI;
use Data::Dumper;
use Scalar::Util qw(blessed reftype);
use Carp qw(carp croak confess);
use Unicode::Escape;

######################################################################

our ($VERSION, $debug);
BEGIN {
	$debug		= 0;
	$VERSION	= 0.107;
}

######################################################################

=head1 METHODS

=over 4

=cut

=item C<new ( $iri, [ $base ] )>

Returns a new Resource structure.

=cut

sub new {
	my $class	= shift;
	my $uri		= shift;
	
	my @uni;
	my $count	= 0;
	while ($uri =~ /([\x{00C0}-\x{EFFFF}]+)/) {
		my $text	= $1;
		push(@uni, $text);
		$uri		=~ s/$1/',____rq' . $count . '____,'/e;
		$count++;
	}
	
	if (defined($_[0])) {
		my $base	= shift;
		### We have to work around the URI module not accepting IRIs. If there's
		### Unicode in the IRI, pull it out, leaving behind a breadcrumb. Turn
		### the URI into an absolute URI, and then replace the breadcrumbs with
		### the Unicode.
		
		my $abs			= URI->new_abs( $uri, $base->uri_value );
		$uri			= $abs->as_string;
	}

	while ($uri =~ /,____rq(\d+)____,/) {
		my $num	= $1;
		my $i	= index($uri, ",____rq${num}____,");
		my $len	= 12 + length($num);
		substr($uri, $i, $len)	= shift(@uni);
	}
	
	return bless( [ 'URI', $uri ], $class );
}

=item C<< uri_value >>

Returns the URI/IRI value of this resource.

=cut

sub uri_value {
	my $self	= shift;
	return $self->[1];
}

=item C<< uri ( $uri ) >>

Returns the URI value of this resource, optionally updating the URI.

=cut

sub uri {
	my $self	= shift;
	if (@_) {
		$self->[1]	= shift;
	}
	return $self->[1];
}

=item C<< sse >>

Returns the SSE string for this resource.

=cut

sub sse {
	my $self	= shift;
	my $context	= shift;
	my $uri		= $self->uri_value;
	
	if (ref($uri) and reftype($uri) eq 'ARRAY') {
		my ($ns, $local)	= @$uri;
		$ns	= '' if ($ns eq '__DEFAULT__');
		return join(':', $ns, $local);
	} else {
		my $ns		= $context->{namespaces} || {};
		while (my ($k, $v) = each(%$ns)) {
			if (index($uri, $v) == 0) {
				my $qname	= join(':', $k, substr($uri, length($v)));
				return $qname;
			}
		}
		
		my $qname	= 0;
		my $string	= qq(${uri});
		foreach my $n (keys %$ns) {
			if (substr($uri, 0, length($ns->{ $n })) eq $ns->{ $n }) {
				$string	= join(':', $n, substr($uri, length($ns->{ $n })));
				$qname	= 1;
				last;
			}
		}
		
		my $escaped	= Unicode::Escape::escape( $string );
		$escaped	=~ s/\\u([0-9a-fA-F]{4})/"\\u" . uc($1)/ge;
		if ($qname) {
			return $escaped;
		} else {
			return '<' . $escaped . '>';
		}
	}
}

=item C<< as_string >>

Returns a string representation of the node.

=cut

sub as_string {
	my $self	= shift;
	return '<' . $self->uri_value . '>';
}

=item C<< type >>

Returns the type string of this node.

=cut

sub type {
	return 'URI';
}

=item C<< equal ( $node ) >>

Returns true if the two nodes are equal, false otherwise.

=cut

sub equal {
	my $self	= shift;
	my $node	= shift;
	return 0 unless (blessed($node) and $node->isa('RDF::Trine::Node'));
	return 0 unless ($self->type eq $node->type);
	return ($self->uri_value eq $node->uri_value);
}

1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut
