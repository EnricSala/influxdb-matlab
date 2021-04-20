clear; clc;
addpath('influxdb-client');

% Configure database
URL = 'http://localhost:8086';
TOKEN = 'x7sBilbi0evsHydoT6kQWRQmJdEbuhgB';
DATABASE = 'vehicle';
ORG = 'f1tenth';
influxdb = InfluxDBv2(URL, TOKEN, ORG, DATABASE);

% Check the status of the InfluxDB instance
[ok, ping] = influxdb.ping();

% Change the current database
influxdb.use('vehicle');

% Show databases
influxdb.databases()

% Write data
series1 = Series('position') ...
    .tags('city', 'antwerp', 'country', 'belgium') ...
    .fields('x', 825, 'y', 433.65) ...
    .time(datetime('now', 'TimeZone', 'local'));

influxdb.writer().append(series1).execute()

% Read data
result = influxdb.query('position').execute();
result.series('position').timetable('Europe/Paris')

