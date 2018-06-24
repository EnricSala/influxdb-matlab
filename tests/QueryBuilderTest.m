classdef QueryBuilderTest < matlab.unittest.TestCase
    
    methods(Test)
        %% Constructor tests
        function empty_builder_fails(test)
            f = @() QueryBuilder().build();
            test.verifyError(f, 'build:emptySeries');
        end
        
        function single_series_in_constructor(test)
            q = QueryBuilder('weather');
            exp = 'SELECT * FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_series_in_constructor(test)
            q = QueryBuilder('weather', 'metrics');
            exp = 'SELECT * FROM weather,metrics';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_series_in_constructor_from_cell(test)
            q = QueryBuilder({'weather', 'metrics'});
            exp = 'SELECT * FROM weather,metrics';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Series tests
        function empty_series_setter_fails(test)
            f = @() QueryBuilder().series();
            test.verifyError(f, 'series:empty');
        end
        
        function single_series_setter(test)
            q = QueryBuilder().series('weather');
            exp = 'SELECT * FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_series_setter(test)
            q = QueryBuilder().series('weather', 'metrics');
            exp = 'SELECT * FROM weather,metrics';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_series_setter_from_cell(test)
            q = QueryBuilder().series({'weather', 'metrics'});
            exp = 'SELECT * FROM weather,metrics';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Fields tests
        function empty_fields_selects_everything(test)
            q = QueryBuilder('weather').fields();
            exp = 'SELECT * FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        function single_field(test)
            q = QueryBuilder('weather').fields('temperature');
            exp = 'SELECT temperature FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_fields_varargin(test)
            q = QueryBuilder('weather').fields('temperature', 'humidity');
            exp = 'SELECT temperature,humidity FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_fields_from_cell(test)
            q = QueryBuilder('weather').fields({'temperature', 'humidity'});
            exp = 'SELECT temperature,humidity FROM weather';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Tags tests
        function single_tag(test)
            q = QueryBuilder('weather').tags('city', 'bcn');
            exp = 'SELECT * FROM weather WHERE "city"=''bcn''';
            test.verifyEqual(q.build(), exp);
        end
        
        function single_tag_multiple_values(test)
            q = QueryBuilder('weather').tags('station', {'a1', 'b2'});
            exp = 'SELECT * FROM weather WHERE ("station"=''a1'' OR "station"=''b2'')';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_tags(test)
            q = QueryBuilder('weather').tags('city', 'bcn', 'station', {'a1', 'b2'});
            exp = 'SELECT * FROM weather WHERE "city"=''bcn'' AND ("station"=''a1'' OR "station"=''b2'')';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_tags_from_struct(test)
            tags = struct('city', 'bcn', 'station', {{'a1', 'b2'}});
            q = QueryBuilder('weather').tags(tags);
            exp = 'SELECT * FROM weather WHERE "city"=''bcn'' AND ("station"=''a1'' OR "station"=''b2'')';
            test.verifyEqual(q.build(), exp);
        end
    end
    
end
