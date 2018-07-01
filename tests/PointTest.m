classdef PointTest < matlab.unittest.TestCase
    
    methods(Test)
        function build_fails_when_empty_name(test)
            f = @() Point('').toLine();
            test.verifyError(f, 'toLine:emptyName');
        end
        
        function build_fails_when_empty_fields(test)
            f = @() Point('weather').toLine();
            test.verifyError(f, 'toLine:emptyFields');
        end
        
        function single_field(test)
            p = Point('weather').fields('temperature', 24.3);
            exp = 'weather temperature=24.3';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function supports_fields_with_integer_values(test)
            p = Point('weather').fields('rain_drops', int64(1234567890));
            exp = 'weather rain_drops=1234567890i';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function supports_fields_with_string_values(test)
            p = Point('weather').fields('wind_direction', 'north-west');
            exp = 'weather wind_direction="north-west"';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function supports_fields_with_logical_values(test)
            p = Point('weather').fields('raining', true);
            exp = 'weather raining=true';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function multiple_fields(test)
            p = Point('weather') ...
                .fields('temperature', 24.3, 'humidity', 60.7);
            exp = 'weather temperature=24.3,humidity=60.7';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function fields_from_struct(test)
            fields = struct('temperature', 24.3, 'humidity', 60.7);
            p = Point('weather').fields(fields);
            exp = 'weather temperature=24.3,humidity=60.7';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function supports_multiple_fields_calls(test)
            p = Point('weather') ...
                .fields('temperature', 24.3) ...
                .fields('humidity', 60.7);
            exp = 'weather temperature=24.3,humidity=60.7';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function single_tag(test)
            p = Point('weather') ...
                .tags('city', 'barcelona') ...
                .fields('temperature', 24.3);
            exp = 'weather,city=barcelona temperature=24.3';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function multiple_tags(test)
            p = Point('weather') ...
                .tags('city', 'barcelona', 'station', 'a1') ...
                .fields('temperature', 24.3);
            exp = 'weather,city=barcelona,station=a1 temperature=24.3';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function tags_from_struct(test)
            tags = struct('city', 'barcelona', 'station', 'a1');
            p = Point('weather').tags(tags).fields('temperature', 24.3);
            exp = 'weather,city=barcelona,station=a1 temperature=24.3';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function supports_multiple_tags_calls(test)
            p = Point('weather') ...
                .tags('city', 'barcelona') ...
                .tags('station', 'a1') ...
                .fields('temperature', 24.3);
            exp = 'weather,city=barcelona,station=a1 temperature=24.3';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function time_is_added_in_millis_by_default(test)
            millis = 1529933525520;
            time = datetime(millis / 1000, 'ConvertFrom', 'posixtime');
            p = Point('weather') ...
                .fields('temperature', 24.3) ...
                .time(time);
            exp = 'weather temperature=24.3 1529933525520';
            test.verifyEqual(p.toLine(), exp);
        end
        
        function time_supports_different_precisions(test)
            millis = 1529933525520;
            time = datetime(millis / 1000, 'ConvertFrom', 'posixtime');
            p = Point('weather') ...
                .fields('temperature', 24.3);
            precisions = struct( ...
                'ns', '1529933525520000000', ...
                'u', '1529933525520000', ...
                'ms', '1529933525520', ...
                's', '1529933526', ...
                'm', '25498892', ...
                'h', '424982');
            names = fieldnames(precisions);
            for i = 1:length(names)
                name = names{i};
                exp = [' ', precisions.(name)];
                line = p.time(time).toLine(name);
                test.verifyTrue(endsWith(line, exp));
            end
        end
        
        function every_property_is_used(test)
            millis = 1529933525520;
            time = datetime(millis / 1000, 'ConvertFrom', 'posixtime');
            p = Point('weather') ...
                .tags('city', 'barcelona') ...
                .fields('temperature', 24.3) ...
                .time(time);
            exp = 'weather,city=barcelona temperature=24.3 1529933525520';
            test.verifyEqual(p.toLine(), exp);
        end
    end
    
end
