classdef QueryResult < handle
    
    properties(Access = private)
        Series;
    end
    
    methods
        % Constructor
        function obj = QueryResult(series)
            obj.Series = series;
        end
        
        % List names of the series
        function names = names(obj)
            names = {obj.Series.name()};
        end
        
        % Find serie position
        function idx = indexOf(obj, name)
            match = strcmp(obj.names(), name);
            idx = find(match, 1, 'first');
        end
        
        % Test if serie is present
        function present = isPresent(obj, name)
            present = ~isempty(obj.indexOf(name));
        end
        
        % Get a serie by name
        function series = series(obj, name)
            idx = obj.indexOf(name);
            assert(~isempty(idx), ['series "' name '" is not present']);
            series = obj.Series(idx);
        end
    end
    
    methods(Static)
        % Convert a response to objects
        function objs = from(response)
            assert(~isempty(response.results), 'the response contains no results');
            objs = arrayfun(@(x) QueryResult.wrap(x), response.results);
        end
    end
    
    methods(Static, Access = private)
        % Wrap series results in a query result
        function obj = wrap(result)
            assert(isfield(result, 'series'), 'the result contains no series');
            series = arrayfun(@(x) SeriesResult.from(x), result.series);
            obj = QueryResult(series);
        end
    end
    
end
