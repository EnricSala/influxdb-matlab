clear; clc;

% Add the library to the path
addpath('influxdb-client');

% Run all the tests
run(testsuite('tests'));
