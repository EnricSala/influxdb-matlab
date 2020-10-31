classdef InfluxDbTest < matlab.unittest.TestCase
    
    properties(Access = private)
        Client, Database
    end
    
    methods(TestMethodSetup)
        function beforeEach(test)
            url = 'http://localhost:18086';
            user = 'user';
            password = 'password';
            test.Database = char(randi([97 122], [1, 32]));
            test.Client = InfluxDB(url, user, password, test.Database);
            
            disp(['Creating test database: ', test.Database]);
            test.Client.runCommand(['CREATE DATABASE "', test.Database, '"'], true);
            
            dbs = test.Client.databases();
            assert(any(strcmp(test.Database, dbs)), 'Failed to create test database');
        end
    end
    
    methods(TestMethodTeardown)
        function afterEach(test)
            disp(['Dropping test database: ', test.Database]);
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
            
            % XXX: remove this
            test.verifyEqual(2, 3);
        end
        
        function timestamp_timezone_propagation(test)
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
            
            test.verifyEqual(weather.time('Europe/Paris'), time);
        end
    end
    
end
