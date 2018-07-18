InfluxDB MATLAB [under development]
===================================

#### [MATLAB][matlab] client for interacting with [InfluxDB][influxdb].

This library has been developed with `InfluxDB 1.5` and `MATLAB R2018a`.
It may work with earlier versions but they have not been tested. 

Notice that this library is **under development**.
The current version is usable but it is not feature-complete and may contain bugs.
Also, beware that the library may undergo significant changes until the initial release.


Installation
------------

Clone or download the repository and add the `influxdb-client` directory to the path:

```matlab
% Add the library to the path
addpath('path/to/influxdb-client');
```


Usage
-----

Create an InfluxDB client instance and use it to interact with the server:

```matlab
% Build an InfluxDB client
URL = 'http://localhost:8086';
USER = 'user';
PASS = 'password';
DATABASE = 'server_stats';
influxdb = InfluxDB(URL, USER, PASS, DATABASE);

% Check the status of the InfluxDB instance
[ok, ping] = influxdb.ping()

% Show the databases
dbs = influxdb.databases()

% Change the current database
influxdb.use('weather_stations');
```

If you plan on doing very large requests you may need to adjust the timeouts:

```matlab
% Configure timeouts
influxdb.setReadTimeout(10);
influxdb.setWriteTimeout(10);
```


Writing data
------------

Use the `Series` builder to prepare the data, then write it using the client:

```matlab
% Create a series with a single sample
series1 = Series('weather') ...
    .tags('city', 'barcelona', 'country', 'catalonia') ...
    .fields('temperature', 24.3, 'humidity', 70.4) ...
    .time(datetime('today', 'TimeZone', 'local'));

% Create a series with many samples
series2 = Series('weather') ...
    .tags('city', 'copenhagen', 'country', 'denmark') ...
    .fields('temperature', [12.6; 11.8], 'humidity', [45.7; 46.3]) ...
    .time(datetime('now', 'TimeZone', 'local') - [0; 1] / 24);

% Create a series from an existing timetable
series3 = Series('weather') ...
    .tags('city', 'helsinki', 'country', 'finland') ...
    .import(my_timetable);

% Create an array of series
series_array = [series4, series5, etc];

% Save all the series in a batch
influxdb.writer() ...
    .append(series1, series2, series3) ...
    .append(series_array) ...
    .execute();
```

The parameters of a write request can optionally be customized as follows:

```matlab
% Customize a write request
influxdb.writer() ...
    .database('another_database') ...
    .precision('ms') ...
    .retention('two_weeks') ...
    .consistency('quorum') ...
    .append(series, etc) ...
    .execute();
```


Querying data
-------------

The client supports reading data from InfluxDB using query strings:

```matlab
% Manually written query
str = 'SELECT temperature FROM weather WHERE humidity > 60 LIMIT 100';
result = influxdb.runQuery(str);
```

Additionally, a query builder is provided to help generate them:

```matlab
% Dynamically generated query
result = influxdb.query('weather') ...
    .fields('temperature', 'humidity') ...
    .tags('city', 'barcelona') ...
    .tagsLike('station', '^(foo|bar)[0-9]{3}') ...
    .before(datetime('today', 'TimeZone', 'local')) ...
    .after(datetime('2018-01-01', 'TimeZone', 'local')) ...
    .where('temperature > 20 AND humidity > 60') ...
    .execute();

% Another example with more options
result = influxdb.query('weather') ...
    .fields('mean(temperature)', 'sum(rain)') ...
    .groupByTags('country', 'city') ...
    .groupByTime('3h', 'linear') ...
    .limit(100) ...
    .execute();
```

The parameters of a query request can optionally be customized as follows:

```matlab
% Customize a query request
result = influxdb.query('weather') ...
    .database('another_database') ...
    .epoch('m') ...
    .execute();
```

The result of a query is an object that provides additional functionalities:

```matlab
% Check which series are present in a result
series_names = result.names()

% Get series with matching name
weather = result.series('weather')

% When grouping by tags, get series with matching tags
weather_bcn = result.series('weather', 'city', 'barcelona')
weather_cph = result.series('weather', 'city', 'copenhagen')

% Check which fields are present in a series
field_names = weather.fields()

% Plot a field
time = weather.time('Europe/Amsterdam');
temperature = weather.field('temperature');
plot(time, temperature);

% Convert a series to a table or timetable
mytable = weather.table();
mytable = weather.timetable('Europe/Paris');
```

Notice that the `time()` and `timetable()` methods take an optional timezone argument.

Other commands
--------------

Use `runCommand(command, [database], [requiresPost])` for executing arbitrary commands:

```matlab
% Show databases then create one
influxdb.runCommand('SHOW DATABASES')
influxdb.runCommand('CREATE DATABASE "example"', true)

% Show measurements and tag keys
influxdb.runCommand('SHOW MEASUREMENTS', 'example')
influxdb.runCommand('SHOW TAG KEYS', 'example')

% Create a retention policy that keeps data for one day
influxdb.runCommand('CREATE RETENTION POLICY "one_day" ON "example" DURATION 1d REPLICATION 1', true)

% Convert a command result to a table
result = influxdb.runCommand('SHOW RETENTION POLICIES', 'example')
policies = result.series().table()
```

See the [InfluxDB documentation][influxdb-docs] for more schema exploration and management commands.


Contributing
------------

Feedback or contributions are welcome!

Please create an issue to discuss it first :)


License
-------

    MIT License

    Copyright (c) 2018 Enric Sala

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.


 [matlab]: https://en.wikipedia.org/wiki/MATLAB
 [influxdb]: https://en.wikipedia.org/wiki/InfluxDB
 [influxdb-docs]: https://docs.influxdata.com/influxdb
