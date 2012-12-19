Polychart2.js
=============

Polychart2.js is an easy-to-use yet powerful JavaScript graphing library. It
takes many ideas from the Grammar of Graphics and the R library ggplot2, and
adds interactive elements to take full advantage of the web.

Key Features
------------

### H3 Static Charts

Charts are defined in Polychart2 by providing a combinations of 

* one or more _layers_, defining the "mark" or "chart type" to be used
* one or more _aesthetic mappings_, defining which data columns will map to
  which visible features like position or color (these are known as
  _aesthetics_)
* _scales_, definining how data columns will map to aesthetics (e.g. linear or 
  log scale? what numeric values map to which colour?)
* _coordinates_, defining which coordinate sytem to plot the chart in (typically
  cartesian or polar)

The full list of supported layers, aesthetics, scales and coordinates and how
they are specified can be found in the documentations.

### H3 Data Processing

The Polychart2 library can perform simple statistical calculations based on
existing data. For example, it is possible to plot the total number of sales
per region by assigning the x-mapping to `region` and y-mapping to
`sum(sales)`.

These statistical calculations can happen in the front-end, right in the
browser, can be done in the backend with a server that can communicate with
the front end.

The full list of supported operations and integration details are provided in
the documentations.

### H3 Interaction

Charts created by Polychart2 is interactive by nature, and uses an event-based
model for interaction. Events are thrown when the underlying data changes, or 
when a user interacts with the chart. Charts can be modified as a response to 
events. See the documentations for more details.

Downloads
---------

* polychart2.js - The full version of Polychart2.js
* polychart2.min.js - The minified version of Polychart2.js
* polychart2.standalone.js - The minified version, including dependencies

Dependencies
------------

Polychart2.js uses the following libraries internally.
* [underscore.js](http://documentcloud.github.com/underscore/)
* [raphael.js](http://raphaeljs.com/)
* [moment.js](http://momentjs.com/)

Other libraries in the lib/ directory are included for the test and example
scripts.

License
-------

For non-commercial use, Polychart2.js is licensed under Creative Commons 3.0
Attribution & Non-commercial ([Link](http://creativecommons.org/licenses/by-nc/3.0/)).

Contact lisa@polychart.com for licensing inquiries & commercial usage.

