clear; clc;

import matlab.unittest.TestRunner;
import matlab.unittest.plugins.TestRunProgressPlugin;

% Add the library to the path
addpath('influxdb-client');

% Check if running on a CI environment
CI = ~isempty(getenv('CI'));

% Initialize a test runner
runner = TestRunner.withTextOutput;
if CI
    runner.addPlugin(TestRunProgressPlugin.withVerbosity(3));
end

% Run all the tests
result = runner.run(testsuite('tests'));

% Fail the build if there are failures
if CI
    assert(all([result.Passed]), 'There are test failures!');
    
    % Display a test summary on success
    Name = {result.Name}';
    Duration = [result.Duration]';
    disp(table(Name, Duration));
end
