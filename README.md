#  OpenStreetMap Golf courses


An experiment with OSM Overpass to display golf courses in Japan on a map.


### Currently

Using a json file (/Resources/japan.json) obtained from running the Python preprocessor at: 
"https://github.com/workingDog/osm-golf-courses" as the source of data for all golf clubs/courses.

Modified the python code to generate most features (see full-feature branch), including:

"green", "tee", "fairway", "bunker", "water_hazard", "lateral_water_hazard", "pin"

python3 build.py --fetch


Particularly interested in "pin" location to display the distance between the golfer and the pin.



### Previous experiment

Initially (see OSMContentView) directly using:

EndPoint "https://overpass-api.de/api/interpreter"


## References

Browser based see "https://overpass-turbo.eu/"

Overpass doc see "https://dev.overpass-api.de/overpass-doc/en/index.html"

See also "https://overpass-api.de/"

Should look at using: "https://github.com/V4ulthunt3r/SwiftOverpassAPI"




