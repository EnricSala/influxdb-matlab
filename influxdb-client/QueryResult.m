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
        
        % Check if the result contains these series
        function present = contains(obj, varargin)
            check = @(x) ~isempty(obj.indexOf(x));
            present = arrayfun(check, varargin);
        end
        
        % Find series by name, matching tags
        function series = series(obj, name, varargin)
            idx = obj.indexOf(name);
            assert(~isempty(idx), ['series "' name '" is not present']);
            series = obj.Series(idx);
            if nargin > 2
                tags = struct(varargin{:});
                series = obj.filterByTags(series, tags);
            end
        end
    end
    
    methods(Access = private)
        % Find the position of a series
        function idx = indexOf(obj, name)
            match = strcmp(obj.names(), name);
            idx = find(match);
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
            if isfield(result, 'error')
                error('query:error', 'query error: %s', result.error);
            end
            assert(isfield(result, 'series'), 'the result contains no series');
            series = arrayfun(@(x) SeriesResult.from(x), result.series);
            obj = QueryResult(series);
        end
        
        % Filter series by matching tags
        function series = filterByTags(series, matchTags)
            keys = fieldnames(matchTags);
            selection = true(1, length(series));
            for i = 1:length(series)
                itemTags = series(i).tags();
                for j = 1:length(keys)
                    key = keys{j};
                    if ~isfield(itemTags, key) || ...
                            ~strcmp(matchTags.(key), itemTags.(key))
                        selection(i) = false;
                    end
                end
            end
            series = series(selection);
        end
    end
    
end
