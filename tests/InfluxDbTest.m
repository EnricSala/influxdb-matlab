classdef InfluxDbTest < matlab.unittest.TestCase
    
    properties(Access = private)
        Client, Database
    end
    
    methods(TestMethodSetup)
        function beforeEach(test)
            url = 'http://localhost:8086';
            user = 'user';
            password = 'password';
            test.Database = ['test_', num2str(randi(1E15))];
            test.Client = InfluxDB(url, user, password, test.Database);
            
            disp(['Creating database: ', test.Database]);
            test.Client.runCommand(['CREATE DATABASE "', test.Database, '"'], true);
            
            dbs = test.Client.databases();
            assert(any(strcmp(test.Database, dbs)), 'Failed to create test database');
        end
    end
    
    methods(TestMethodTeardown)
        function afterEach(test)
            disp(['Dropping database: ', test.Database]);
            test.Client.runCommand(['DROP DATABASE "', test.Database, '"'], true);
        end
    end
    
    methods(Test, TestTags = {'integration'})
        function basic_write_and_read(test)
            time = datetime('now', 'TimeZone', 'local') + [0; 1] / 24;
            temperature = [22.5; 23.4];
            humidity = [60.7; 61.8];
            
            series = Series('weather') ...
                .tags('city', 'amsterdam') ...
                .field('temperature', temperature) ...
                .field('humidity', humidity) ...
                .time(time);
            
            test.Client.writer().append(series).execute();
            
            result = test.Client.query('weather').execute();
            
            test.verifyEqual(result.names(), {'weather'});
            weather = result.series('weather');
            
            test.verifyEqual(weather.fields(), {'city', 'humidity', 'temperature'});
            test.verifyEqual(weather.field('temperature'), temperature);
            test.verifyEqual(weather.field('humidity'), humidity);
        end
        
        function handles_timezones_correctly(test)
            time = datetime('now', 'TimeZone', 'Europe/Paris') + [0; 1] / 24;
            temperature = [22.5; 23.4];
            humidity = [60.7; 61.8];
            
            series = Series('weather') ...
                .tags('city', 'amsterdam') ...
                .field('temperature', temperature) ...
                .field('humidity', humidity) ...
                .time(time);
            
            test.Client.writer().append(series).execute();
            
            result = test.Client.query('weather').execute();
            weather = result.series('weather');
            
            test.verifyEqual(datestr(weather.time('Europe/Paris')), datestr(time));
        end
        
        function supports_multiple_queries_per_request(test)
            time = datetime('now', 'TimeZone', 'local') + [0; 1] / 24;
            series_1 = Series('a').field('value', [2, 4]).time(time);
            series_2 = Series('b').field('value', [1, 5]).time(time);
            
            test.Client.writer().append([series_1, series_2]).execute();
            
            result = test.Client.runQuery({...
                'select mean(value) from a', ...
                'select sum(value) from b'});
            
            test.verifyEqual(length(result), 2)
            test.verifyEqual(result(1).names(), {'a'});
            test.verifyEqual(result(2).names(), {'b'});
            
            test.verifyEqual(result(1).series('a').field('mean'), 3);
            test.verifyEqual(result(2).series('b').field('sum'), 6);
        end
    end
    
end
