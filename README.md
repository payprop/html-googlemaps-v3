# NAME

HTML::GoogleMaps::V3 - a simple wrapper around the Google Maps API

# SYNOPSIS

     use HTML::GoogleMaps::V3

     $map = HTML::GoogleMaps::V3->new;
     $map->center("1810 Melrose St, Madison, WI");
     $map->add_marker(point => "1210 W Dayton St, Madison, WI");
     $map->add_marker(point => [ 51, 0 ] );   # Greenwich
    
     my ($head, $map_div) = $map->onload_render;

# NOTE

This modules is forked from [HTML::GoogleMaps](https://metacpan.org/pod/HTML::GoogleMaps), it is a drop in
replacement requiring no changes to your code other than adding the
::V3 namespace. Note that V3 of the API does not require an API key
so any key passed to this module will be ignored

# DESCRIPTION

HTML::GoogleMaps::V3 provides a simple wrapper around the Google Maps
API.  It allows you to easily create maps with markers, polylines and
information windows.  Thanks to Geo::Coder::Google you can now look
up locations around the world without having to install a local database.

# CONSTRUCTOR

- $map = HTML::GoogleMaps::V3->new;

    Creates a new HTML::GoogleMaps::V3 object.  Takes a hash of options.
    Valid options are:

    - height => height (in pixels or using your own unit)
    - width => width (in pixels or using your own unit)

# METHODS

- $map->center($point)

    Center the map at a given point.

- $map->v2\_zoom($level)

    Set the new zoom level (0 is corsest)

- $map->controls($control1, $control2)

    Enable the given controls.  Valid controls are: **large\_map\_control**,
    **small\_map\_control**, **small\_zoom\_control** and **map\_type\_control**.

- $map->dragging($enable)

    Enable or disable dragging.

- $map->info\_window($enable)

    Enable or disable info windows.

- $map->map\_type($type)

    Set the map type.  Either **normal**, **satellite** or **hybrid**.  The
    v1 API **map\_type** or **satellite\_type** still work, but may be dropped
    in a future version.

- $map->map\_id($id)

    Set the id of the map div

- $map->add\_icon(name => $icon\_name,
                     image => $image\_url,
                     shadow => $shadow\_url,
                     icon\_size => \[ $width, $height \],
                     shadow\_size => \[ $width, $height \],
                     icon\_anchor => \[ $x, $y \],
                     info\_window\_anchor => \[ $x, $y \]);

    Adds a new icon, which can later be used by add\_marker.  All args
    are required except for info\_window\_anchor.

- $map->add\_marker(point => $point, html => $info\_window\_html)

    Add a marker to the map at the given point. A point can be a unique
    place name, like an address, or a pair of coordinates passed in as
    an arrayref: \[ longituded, latitude \].

    If **html** is specified,
    add a popup info window as well.  **icon** can be used to switch to
    either a user defined icon (via the name) or a standard google letter
    icon (A-J).

    Any data given for **html** is placed inside a 350px by 200px div to
    make it fit nicely into the Google popup.  To turn this behavior off 
    just pass **noformat** => 1 as well.

- $map->add\_polyline(points => \[ $point1, $point2 \])

    Add a polyline that connects the list of points.  Other options
    include **color** (any valid HTML color), **weight** (line width in
    pixels) and **opacity** (between 0 and 1).

- $map->render

    **DEPRECATED -- please use onload\_render intead, it will give you
    better javascript.**

    Renders the map and returns a three element list.  The first element
    needs to be placed in the head section of your HTML document.  The
    second in the body where you want the map to appear.  The third (the 
    Javascript that controls the map) needs to be placed in the body,
    but outside any div or table that the map lies inside of.

- $map->onload\_render

    Renders the map and returns a two element list.  The first element
    needs to be placed in the head section of your HTML document.  The
    second in the body where you want the map to appear.  You will also 
    need to add a call to html\_googlemaps\_initialize() in your page's 
    onload handler.  The easiest way to do this is adding it to the body
    tag:

        <body onload="html_googlemaps_initialize()">

# SEE ALSO

[http://www.google.com/apis/maps](http://www.google.com/apis/maps)
[http://geocoder.us](http://geocoder.us)

# BUGS

Address bug reports and comments to: [https://github.com/leejo/html-googlemaps-v3/issues](https://github.com/leejo/html-googlemaps-v3/issues)

# AUTHORS

Nate Mueller <nate@cs.wisc.edu> - Original Author

Lee Johnson <leejo@cpan.org> - Maintainer of this fork
