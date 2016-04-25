#!/usr/bin/perl -w

use Test::More 'no_plan';
use strict;
use blib;

BEGIN { use_ok('HTML::GoogleMaps::V3') }
use HTML::GoogleMaps::V3;

# Autocentering
{
  my $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [0, 0]);
  is_deeply( $map->_find_center, [0, 0], "Single point 1" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [90, 0]);
  is_deeply( $map->_find_center, [0, 90], "Single point 2" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [180, 45]);
  is_deeply( $map->_find_center, [45, 180], "Single point 3" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [-90, -10]);
  is_deeply( $map->_find_center, [-10, -90], "Single point 4" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [10, 10]);
  $map->add_marker(point => [20, 20]);
  is_deeply( $map->_find_center, [15, 15], "Double point 1" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [-10, 10]);
  $map->add_marker(point => [-20, 20]);
  is_deeply( $map->_find_center, [15, -15], "Double point 2" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [10, 10]);
  $map->add_marker(point => [-10, -10]);
  is_deeply( $map->_find_center, [0, 0], "Double point 3" );

  $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->add_marker(point => [-170, 0]);
  $map->add_marker(point => [150, 0]);
  is_deeply( $map->_find_center, [0, 170], "Double point 4" );
}

# API v2 support
{
  my $map = HTML::GoogleMaps::V3->new(key => 'foo');
  my ($head, $html) = $map->onload_render;
  like( $head, qr/script.*v=2/, 'Point to v2 API' );

  $map->zoom(2);
  is( $map->{zoom}, 15, 'v1 zoom function translates' );
  $map->v2_zoom(3);
  is( $map->{zoom}, 3, 'v2 zoom function works as expected' );
    
  $map->center([12,13]);
  $map->add_marker(point => [13,14]);
  $map->add_polyline(points => [ [14,15], [15,16] ]);
  ($html, $head) = $map->onload_render;

  $map->map_type('map_type');
  ($html, $head) = $map->onload_render;
  $map->map_type('satellite_type');
  ($html, $head) = $map->onload_render;
  $map->map_type('normal');
  ($html, $head) = $map->onload_render;
  $map->map_type('satellite');
  ($html, $head) = $map->onload_render;
  $map->map_type('hybrid');
  ($html, $head) = $map->onload_render;
}

# Geo::Coder::Google
{
  my $stub_loc;
  my $map = HTML::GoogleMaps::V3->new(key => 'foo');
  no warnings 'redefine';
  no warnings 'once';
  *Geo::Coder::Google::V3::geocode = sub { +{Point => {coordinates => $stub_loc}} };
    
  $stub_loc = [3463, 3925, 0];
  $map->add_marker(point => 'result_democritean');
  my ($html, $head) = $map->onload_render;
}

# dragging
{
  my $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->dragging(0);
  my ($html, $head) = $map->onload_render;

  $map->dragging(1);
  ($html, $head) = $map->onload_render;
}

# map_id
{
  my $map = HTML::GoogleMaps::V3->new(key => 'foo');
  $map->map_id('electrometrical_nombles');
  $map->add_marker(point => [21, 31]);
  $map->add_polyline(points => [[21, 31], [22, 32]]);

  my ($head, $div) = $map->onload_render;
  like( $div, qr/id="electrometrical_nombles"/, 'Correct map ID for div' );
}

# width and height
{
   my $map = HTML::GoogleMaps::V3->new( key => 'foo', width => 11, height => 22 );
   my ($head, $div) = $map->onload_render;
   like( $div, qr/width.+11px/, 'Correct width for div' );
   like( $div, qr/height.+22px/, 'Correct height for div' );

   $map = HTML::GoogleMaps::V3->new( key => 'foo', width => '33%', height => '44em' );
   ($head, $div) = $map->onload_render;
   like( $div, qr/width.+33%/, 'Correct width for div' );
   like( $div, qr/height.+44em/, 'Correct height for div' );
}

# info window html
{
    my $map = HTML::GoogleMaps::V3->new( key => 'foo' );
    $map->add_marker( point => 'bar', html => qq|<a href="foo" title='bar'>baz</a>| );
    my ($head, $div) = $map->onload_render;
}
