#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use HTML::GoogleMaps::V3;

any '/map/#center/#marker/' => sub {
	my ( $c ) = @_;

	# random API key, not actually required by testing its use here
	my $map = HTML::GoogleMaps::V3->new();# api_key => 'AIzaSyjds04j4DSjfjnvkd003JFksjsncskslvI' );
	$map->center( $c->param( 'center' ) );
	$map->add_marker( point => $c->param( 'marker' ) );

	my ( $head,$map_div ) = $map->onload_render;

	$c->render(
		template => 'map',
		head     => $head,
		map      => $map_div,
	);
};

app->start;

__DATA__
@@ map.html.ep
<html>
	<head>
		<%== $head %>
	</head>
	<body onload="html_googlemaps_initialize()">
		<%== $map %>
	</body>
</html>
