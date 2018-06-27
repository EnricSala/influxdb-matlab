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
            N = length(obj.Series);
            names = cell(1, N);
            for i = 1:N
                names{i} = obj.Series(i).name();
            end
        end
        
        % Find serie position
        function idx = indexOf(obj, name)
            match = strcmp(obj.names(), name);
            idx = find(match, 1, 'first');
        end
        
        % Check if the result contains these series
        function present = contains(obj, varargin)
            check = @(x) ~isempty(obj.indexOf(x));
            present = arrayfun(check, varargin);
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
