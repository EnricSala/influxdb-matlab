clear; clc;

% Add the library to the path
addpath('influxdb-client');

% Run all the tests
import matlab.unittest.TestSuite;
suite = TestSuite.fromFolder('tests');
result = suite.run();
