=head1 NAME

HTML::GoogleMaps::V3 - a simple wrapper around the Google Maps API

=for html
<a href='https://travis-ci.org/G3S/html-googlemaps-v3?branch=master'><img src='https://travis-ci.org/G3S/html-googlemaps-v3.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/G3S/html-googlemaps-v3?branch=master'><img src='https://coveralls.io/repos/G3S/html-googlemaps-v3/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.03

=head1 SYNOPSIS

  use HTML::GoogleMaps::V3

  $map = HTML::GoogleMaps::V3->new;
  $map->center("1810 Melrose St, Madison, WI");
  $map->add_marker(point => "1210 W Dayton St, Madison, WI");
  $map->add_marker(point => [ 51, 0 ] );   # Greenwich

  my ($head, $map_div) = $map->onload_render;

=head1 NOTE

This module is forked from L<HTML::GoogleMaps>, it is an almost drop in
replacement requiring minimal changes to your code other than adding the ::V3
namespace. If you are using the deprecated ->render method you should change
this to ->onload_render as this version of the module removes ->render

Note that V3 of the API does not require an API key, however you can pass
one and it will be used (useful for analytics).

=head1 DESCRIPTION

HTML::GoogleMaps::V3 provides a simple wrapper around the Google Maps
API. It allows you to easily create maps with markers, polylines and
information windows. Thanks to Geo::Coder::Google you can now look
up locations around the world without having to install a local database.

=head1 CONSTRUCTOR

=over 4

=item $map = HTML::GoogleMaps::V3->new;

Creates a new HTML::GoogleMaps::V3 object. Takes a hash of options.
Valid options are:

=over 4

=item api_key => key (your Google Maps API key)

=item height => height (in pixels or using your own unit)

=item width => width (in pixels or using your own unit)

=back

=back

=head1 METHODS

=over 4

=item $map->center($point)

Center the map at a given point.

=item $map->v2_zoom($level)

Set the new zoom level (0 is corsest)

=item $map->controls($control1, $control2)

Enable the given controls. Valid controls are: B<large_map_control>,
B<small_map_control>, B<small_zoom_control> and B<map_type_control>.

=item $map->dragging($enable)

Enable or disable dragging.

=item $map->info_window($enable)

Enable or disable info windows.

=item $map->map_type($type)

Set the map type. Either B<normal>, B<satellite> or B<hybrid>. The
v1 API B<map_type> or B<satellite_type> still work, but may be dropped
in a future version.

=item $map->map_id($id)

Set the id of the map div

=item $map->add_icon(name => $icon_name,
                     image => $image_url,
                     shadow => $shadow_url,
                     icon_size => [ $width, $height ],
                     shadow_size => [ $width, $height ],
                     icon_anchor => [ $x, $y ],
                     info_window_anchor => [ $x, $y ]);

Adds a new icon, which can later be used by add_marker. All args
are required except for info_window_anchor.

=item $map->add_marker(point => $point, html => $info_window_html)

Add a marker to the map at the given point. A point can be a unique
place name, like an address, or a pair of coordinates passed in as
an arrayref: [ longituded, latitude ].

If B<html> is specified,
add a popup info window as well. B<icon> can be used to switch to
either a user defined icon (via the name) or a standard google letter
icon (A-J).

Any data given for B<html> is placed inside a 350px by 200px div to
make it fit nicely into the Google popup. To turn this behavior off 
just pass B<noformat> => 1 as well.

=item $map->add_polyline(points => [ $point1, $point2 ])

Add a polyline that connects the list of points. Other options
include B<color> (any valid HTML color), B<weight> (line width in
pixels) and B<opacity> (between 0 and 1).

=item $map->onload_render

Renders the map and returns a two element list. The first element
needs to be placed in the head section of your HTML document. The
second in the body where you want the map to appear. You will also 
need to add a call to html_googlemaps_initialize() in your page's 
onload handler. The easiest way to do this is adding it to the body
tag:

    <body onload="html_googlemaps_initialize()">

=back

=head1 BUGS

Address bug reports and comments to: L<https://github.com/G3S/html-googlemaps-v3/issues>

=head1 AUTHORS

Nate Mueller <nate@cs.wisc.edu> - Original Author

Lee Johnson <leejo@cpan.org> - Maintainer of this fork

=cut

package HTML::GoogleMaps::V3;

use strict;
use Geo::Coder::Google;

our $VERSION = '0.03';

sub new {
    my ( $class,%opts ) = @_;

    return bless( {
        %opts,
        points     => [],
        poly_lines => [],
        geocoder   => Geo::Coder::Google->new,
    }, $class );
}

sub _text_to_point {
    my ( $self,$point_text ) = @_;

    # IE, already a long/lat pair
    return [ reverse @$point_text ] if ref( $point_text ) eq "ARRAY";

    if ( my @loc = $self->{geocoder}->geocode( location => $point_text ) ) {
        if ( my $location = $loc[0] ) {
            return [
                $location->{geometry}{location}{lat},
                $location->{geometry}{location}{lng},
            ];
        }
    }

    # Unknown
    return 0;
}

sub _find_center {
    my ( $self ) = @_;

    # Null case
    return unless @{$self->{points}};

    my ( $total_lat,$total_lng,$total_abs_lng );

    foreach ( @{$self->{points}} ) {
        my ( $lat,$lng ) = @{ $_->{point} };
        $total_lat     += defined $lat ? $lat : 0;
        $total_lng     += defined $lng ? $lng : 0;
        $total_abs_lng += abs( defined $lng ? $lng : 0 );
    }

    # Latitude is easy, just an average
    my $center_lat = $total_lat/@{$self->{points}};

    # Longitude, on the other hand, is trickier. If points are
    # clustered around the international date line a raw average
    # would produce a center around longitude 0 instead of -180.
    my $avg_lng     = $total_lng/@{$self->{points}};
    my $avg_abs_lng = $total_abs_lng/@{$self->{points}};

    return [ $center_lat,$avg_lng ] # All points are on the
        if abs( $avg_lng ) == $avg_abs_lng; # same hemasphere

    if ( $avg_abs_lng > 90 ) { # Closer to the IDL
        if ( $avg_lng < 0 && abs( $avg_lng ) <= 90) {
            $avg_lng += 180;
        } elsif ( abs( $avg_lng ) <= 90 ) {
            $avg_lng -= 180;
        }
    }

    return [ $center_lat,$avg_lng ];
}

sub center {
    my ( $self,$point_text ) = @_;

    my $point = $self->_text_to_point( $point_text )
        || return 0;

    $self->{center} = $point;
    return 1;
}

sub controls {
    my ( $self,@controls ) = @_;

    my %valid_controls = map { $_ => 1 } qw(
        large_map_control
        small_map_control
        small_zoom_control
        map_type_control
    );

    return 0 if grep { !$valid_controls{$_} } @controls;

    $self->{controls} = [ @controls ];
}

sub dragging    { $_[0]->{dragging}    = $_[1]; }
sub info_window { $_[0]->{info_window} = $_[1]; }
sub map_id      { $_[0]->{id}          = $_[1]; }
sub zoom        { $_[0]->{zoom}        = 17 - $_[1]; }
sub v2_zoom     { $_[0]->{zoom}        = $_[1]; }

sub map_type {
    my ( $self,$type ) = @_;

    $type = {
        normal         => 'G_NORMAL_MAP',
        map_type       => 'G_NORMAL_MAP',
        satellite_type => 'G_SATELLITE_MAP',
        satellite      => 'G_SATELLITE_MAP',
        hybrid         => 'G_HYBRID_MAP',
    }->{ $type } || return 0;

    $self->{type} = $type;
}

sub add_marker {
    my ( $self,%opts ) = @_;

    return 0 if $opts{icon} && $opts{icon} !~ /^[A-J]$/
        && !$self->{icon_hash}{$opts{icon}};

    my $point = $self->_text_to_point($opts{point})
        || return 0;

    push( @{$self->{points}}, {
        point  => $point,
        icon   => $opts{icon},
        html   => $opts{html},
        format => !$opts{noformat}
    } );
}

sub add_icon {
    my ( $self,%opts ) = @_;

    return 0 unless $opts{image} && $opts{shadow} && $opts{name};

    $self->{icon_hash}{$opts{name}} = 1;
    push( @{$self->{icons}},\%opts );
}

sub add_polyline {
    my ( $self,%opts ) = @_;

    my @points = map { $self->_text_to_point($_) } @{$opts{points}};
        return 0 if grep { !$_ } @points;

    push( @{$self->{poly_lines}}, {
        points  => \@points,
        color   => $opts{color} || "\#0000ff",
        weight  => $opts{weight} || 5,
        opacity => $opts{opacity} || .5 }
    );
}

sub onload_render {
    my ( $self ) = @_;

    # Add in all the defaults
    $self->{id}         ||= 'map';
    $self->{height}     ||= '400px';
    $self->{width}      ||= '600px';
    $self->{type}       ||= "G_NORMAL_MAP";
    $self->{zoom}       ||= 13;
    $self->{center}     ||= $self->_find_center;
    $self->{dragging}     = 1 unless defined $self->{dragging};
    $self->{info_window}  = 1 unless defined $self->{info_window};

    $self->{width}  .= 'px' if $self->{width} =~ m/^\d+$/;
    $self->{height} .= 'px' if $self->{height} =~ m/^\d+$/;

    my $header = '<script src="https://maps.google.com/maps?file=api&v=3__KEY__" '
        . 'type="text/javascript"></script>'
    ;

    my $key = $self->{api_key}
        ? "&key=@{[ $self->{api_key} ]}" : "";

    $header =~ s/__KEY__/$key/;

    my $map = sprintf(
        '<div id="%s" style="width: %s; height: %s"></div>',
        $self->{id},
        $self->{width},
        $self->{height},
    );

    $header .= <<SCRIPT;
<script type=\"text/javascript\">
    //<![CDATA[
  function html_googlemaps_initialize() {    
    if (GBrowserIsCompatible()) {
      var map = new GMap2(document.getElementById("$self->{id}"));
SCRIPT

    $header .= "      map.setCenter(new GLatLng($self->{center}[0], $self->{center}[1]));\n"
        if $self->{center};
    $header .= "      map.setZoom($self->{zoom});\n"
        if $self->{zoom};

    $header .= "      map.setMapType($self->{type});\n";

    if ($self->{controls}) {
        foreach my $control (@{$self->{controls}}) {
            $control =~ s/_(.)/uc($1)/ge;
            $control = ucfirst($control);
            $header .= "      map.addControl(new G${control}());\n";
        }
    }

    $header .= "      map.disableDragging();\n"
        if ! $self->{dragging};

    # Add in "standard" icons
    my %icons = map { $_->{icon} => 1 } 
        grep { defined $_->{icon} && $_->{icon} =~ /^([A-J])$/; } 
        @{$self->{points}};

    foreach my $icon (keys %icons) {
        $header .= "      var icon_$icon = new GIcon();
      icon_$icon.shadow = \"https://www.google.com/mapfiles/shadow50.png\";
      icon_$icon.iconSize = new GSize(20, 34);
      icon_$icon.shadowSize = new GSize(37, 34);
      icon_$icon.iconAnchor = new GPoint(9, 34);
      icon_$icon.infoWindowAnchor = new GPoint(9, 2);
      icon_$icon.image = \"https://www.google.com/mapfiles/marker$icon.png\";\n\n"
    }

    # And the rest
    foreach my $icon (@{$self->{icons}}) {
        $header .= "      var icon_$icon->{name} = new GIcon();\n";
        $header .= "      icon_$icon->{name}.shadow = \"$icon->{shadow}\"\n"
            if $icon->{shadow};
        $header .= "      icon_$icon->{name}.iconSize = new GSize($icon->{icon_size}[0], $icon->{icon_size}[1]);\n"
            if ref($icon->{icon_size}) eq "ARRAY";
        $header .= "      icon_$icon->{name}.shadowSize = new GSize($icon->{shadow_size}[0], $icon->{shadow_size}[1]);\n"
            if ref($icon->{shadow_size}) eq "ARRAY";
        $header .= "      icon_$icon->{name}.iconAnchor = new GPoint($icon->{icon_anchor}[0], $icon->{icon_anchor}[1]);\n"
            if ref($icon->{icon_anchor}) eq "ARRAY";
        $header .= "      icon_$icon->{name}.infoWindowAnchor = new GPoint($icon->{info_window_anchor}[0], $icon->{info_window_anchor}[1]);\n"
            if ref($icon->{info_window_anchor}) eq "ARRAY";
        $header .= "      icon_$icon->{name}.image = \"$icon->{image}\";\n\n";
    }

    my $i;
    foreach my $point (@{$self->{points}}) {
        $i++;

        my $icon = '';
        if (defined $point->{icon}) {
            $point->{icon} =~ s/(.+)/icon_$1/;
            $icon = ", $point->{icon}";
        }

        my $point_html = $point->{html};
        if ($point->{format} && $point->{html}) {
            $point_html = sprintf(
                '<div style="width:350px;height:200px;">%s</div>',
                $point->{html},
            );
        }

        my ( $lat,$lng ) = ( $point->{point}[0],$point->{point}[1] );
        $lat = defined $lat ? $lat : 0;
        $lng = defined $lng ? $lng : 0;
        $header .= "      var marker_$i = new GMarker(new GLatLng($lat, $lng) $icon);\n";

        if ( $point->{html} ) {
            $point_html =~ s/'/\\'/g;
            $header .= "      GEvent.addListener(marker_$i, \"click\", function () {  marker_$i.openInfoWindowHtml('$point_html'); });\n"
        }

        $header .= "      map.addOverlay(marker_$i);\n";
    }

    $i = 0;
    foreach my $polyline (@{$self->{poly_lines}}) {
        $i++;
        my $points = "[" . join(", ", map { "new GLatLng($_->[0], $_->[1])" } @{$polyline->{points}}) . "]";
        $header .= "      var polyline_$i = new GPolyline($points, \"$polyline->{color}\", $polyline->{weight}, $polyline->{opacity});\n";
        $header .= "      map.addOverlay(polyline_$i);\n";
    }

    $header .= "    }
  }
    //]]>
    </script>";

    return ( $header,$map );
}

1;

# vim: ts=4:sw=4:et
