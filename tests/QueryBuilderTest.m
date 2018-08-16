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
        
        function special_chars_in_tag_values_are_allowed(test)
            q = QueryBuilder('weather').tags('city', 'bcn*', 'station', 'a1-b2');
            exp = 'SELECT * FROM weather WHERE "city"=''bcn*'' AND "station"=''a1-b2''';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Tags-like tests
        function single_tag_like(test)
            q = QueryBuilder('weather').tagsLike('city', 'barcelo');
            exp = 'SELECT * FROM weather WHERE "city"=~/barcelo/';
            test.verifyEqual(q.build(), exp);
        end
        
        function single_tag_like_multiple_values(test)
            q = QueryBuilder('weather').tagsLike('city', {'^barcelo', 'enhaguen$'});
            exp = 'SELECT * FROM weather WHERE ("city"=~/^barcelo/ OR "city"=~/enhaguen$/)';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_tags_like(test)
            q = QueryBuilder('weather').tagsLike('city', 'stock|amste', 'station', {'a1', 'b2'});
            exp = 'SELECT * FROM weather WHERE "city"=~/stock|amste/ AND ("station"=~/a1/ OR "station"=~/b2/)';
            test.verifyEqual(q.build(), exp);
        end
        
        function multiple_tags_like_from_struct(test)
            tags = struct('city', '[xyz]', 'station', {{'a1', 'b2'}});
            q = QueryBuilder('weather').tagsLike(tags);
            exp = 'SELECT * FROM weather WHERE "city"=~/[xyz]/ AND ("station"=~/a1/ OR "station"=~/b2/)';
            test.verifyEqual(q.build(), exp);
        end
        
        function mix_tags_equal_with_tags_like(test)
            q = QueryBuilder('weather').tags('city', 'barcelona').tagsLike('station', 'a1|b2');
            exp = 'SELECT * FROM weather WHERE "city"=''barcelona'' AND "station"=~/a1|b2/';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Group by tests
        function empty_group_by_tags_groups_by_all(test)
            q = QueryBuilder('weather').groupByTags();
            exp = 'SELECT * FROM weather GROUP BY *';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_tags_asterisk_groups_by_all(test)
            q = QueryBuilder('weather').groupByTags('*');
            exp = 'SELECT * FROM weather GROUP BY *';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_single_tag(test)
            q = QueryBuilder('weather').groupByTags('city');
            exp = 'SELECT * FROM weather GROUP BY "city"';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_multiple_tags(test)
            q = QueryBuilder('weather').groupByTags('city', 'station');
            exp = 'SELECT * FROM weather GROUP BY "city","station"';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time(test)
            q = QueryBuilder('weather').groupByTime('12m');
            exp = 'SELECT * FROM weather GROUP BY time(12m)';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_with_fill(test)
            q = QueryBuilder('weather').groupByTime('12m', 'linear');
            exp = 'SELECT * FROM weather GROUP BY time(12m) fill(linear)';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_with_all_tags(test)
            q = QueryBuilder('weather').groupByTime('12m').groupByTags();
            exp = 'SELECT * FROM weather GROUP BY time(12m),*';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_and_tags(test)
            q = QueryBuilder('weather').groupByTime('12m').groupByTags('city');
            exp = 'SELECT * FROM weather GROUP BY time(12m),"city"';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_with_fill_and_all_tags(test)
            q = QueryBuilder('weather').groupByTime('12m', 'linear').groupByTags();
            exp = 'SELECT * FROM weather GROUP BY time(12m),* fill(linear)';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_with_fill_and_tags(test)
            q = QueryBuilder('weather').groupByTime('12m', 'linear').groupByTags('city');
            exp = 'SELECT * FROM weather GROUP BY time(12m),"city" fill(linear)';
            test.verifyEqual(q.build(), exp);
        end
        
        function group_by_time_position(test)
            q = QueryBuilder('weather') ...
                .tags('city', 'barcelona') ...
                .groupByTime('12m', 'none') ...
                .groupByTags('station') ...
                .limit(100);
            exp = 'SELECT * FROM weather WHERE "city"=''barcelona'' GROUP BY time(12m),"station" fill(none) LIMIT 100';
            test.verifyEqual(q.build(), exp);
        end
        
        %% Time before and after tests
        function before_clause(test)
            time = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            q = QueryBuilder('weather').before(time);
            exp = 'SELECT * FROM weather WHERE time < 1529933525520ms';
            test.verifyEqual(q.build(), exp);
        end
        
        function before_equals_clause(test)
            time = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            q = QueryBuilder('weather').beforeEquals(time);
            exp = 'SELECT * FROM weather WHERE time <= 1529933525520ms';
            test.verifyEqual(q.build(), exp);
        end
        
        function after_clause(test)
            time = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            q = QueryBuilder('weather').after(time);
            exp = 'SELECT * FROM weather WHERE time > 1529933525520ms';
            test.verifyEqual(q.build(), exp);
        end
        
        function after_equals_clause(test)
            time = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            q = QueryBuilder('weather').afterEquals(time);
            exp = 'SELECT * FROM weather WHERE time >= 1529933525520ms';
            test.verifyEqual(q.build(), exp);
        end
        
        function before_and_after_are_combined_with_others(test)
            before = datetime(1529933581618 / 1000, 'ConvertFrom', 'posixtime');
            after = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            where = 'temperature > 24.3';
            q = QueryBuilder('weather') ...
                .tags('city', 'bcn', 'station', {'a1', 'b2'}) ...
                .before(before).after(after) ...
                .where(where);
            exp = ['SELECT * FROM weather WHERE' ...
                ' "city"=''bcn'' AND ("station"=''a1'' OR "station"=''b2'')' ...
                ' AND time < 1529933581618ms AND time > 1529933525520ms' ...
                ' AND temperature > 24.3'];
            test.verifyEqual(q.build(), exp);
        end
        
        function before_and_equals_support_different_precisions(test)
            time = datetime(1529933525520 / 1000, 'ConvertFrom', 'posixtime');
            precisions = struct( ...
                'ns', '1529933525520000000ns', ...
                'u', '1529933525520000u', ...
                'ms', '1529933525520ms', ...
                's', '1529933526s', ...
                'm', '25498892m', ...
                'h', '424982h');
            names = fieldnames(precisions);
            for i = 1:length(names)
                name = names{i};
                value = precisions.(name);
                % Before
                q = QueryBuilder('weather').before(time, name);
                test.verifyTrue(endsWith(q.build(), ['time < ' value]));
                % BeforeEquals
                q = QueryBuilder('weather').beforeEquals(time, name);
                test.verifyTrue(endsWith(q.build(), ['time <= ' value]));
                % After
                q = QueryBuilder('weather').after(time, name);
                test.verifyTrue(endsWith(q.build(), ['time > ' value]));
                % AfterEquals
                q = QueryBuilder('weather').afterEquals(time, name);
                test.verifyTrue(endsWith(q.build(), ['time >= ' value]));
            end
        end
    end
    
end
