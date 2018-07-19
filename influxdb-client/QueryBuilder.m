classdef QueryBuilder < handle
    
    properties(Access = private)
        InfluxDB = []
        Database = []
        Epoch = []
        Series = {}
        Fields = {'*'}
        Tags = {}
        Before = []
        After = []
        Where = []
        GroupByTimeInterval = ''
        GroupByTimeFill = ''
        GroupByTags = {}
        Limit = []
    end
    
    methods
        % Constructor
        function obj = QueryBuilder(varargin)
            if nargin > 1
                obj.series(varargin);
            elseif nargin > 0
                obj.series(varargin{1});
            end
        end
        
        % Set the client instance used for execution
        function obj = influxdb(obj, influxdb)
            obj.InfluxDB = influxdb;
        end
        
        % Configure the database
        function obj = database(obj, database)
            obj.Database = database;
        end
        
        % Configure the epoch
        function obj = epoch(obj, epoch)
            obj.Epoch = epoch;
        end
        
        % Configure which series to query
        function obj = series(obj, varargin)
            if nargin > 2
                series = varargin;
            elseif nargin > 1
                series = varargin{1};
                series = iif(iscell(series), series, {series});
            else
                error('series:empty', 'must specify at least 1 serie');
            end
            obj.Series = series;
        end
        
        % Configure which fields to query
        function obj = fields(obj, varargin)
            if nargin > 2
                fields = varargin;
            elseif nargin > 1
                fields = varargin{1};
                fields = iif(iscell(fields), fields, {fields});
            else
                fields = {'*'};
            end
            obj.Fields = fields;
        end
        
        % Add tag equals clause
        function obj = tag(obj, key, values)
            fmt = @(x) ['"' key '"=''' x ''''];
            if iscell(values)
                terms = cellfun(fmt, values, 'UniformOutput', false);
                clause = ['(' strjoin(terms, ' OR ') ')'];
            else
                clause = fmt(values);
            end
            obj.Tags{end + 1} = clause;
        end
        
        % Add multiple tags equals
        function obj = tags(obj, varargin)
            forEachPair(varargin, @(k, v) obj.tag(k, v));
        end
        
        % Add tag-like clause
        function obj = tagLike(obj, key, values)
            fmt = @(x) ['"' key '"=~/' x '/'];
            if iscell(values)
                terms = cellfun(fmt, values, 'UniformOutput', false);
                clause = ['(' strjoin(terms, ' OR ') ')'];
            else
                clause = fmt(values);
            end
            obj.Tags{end + 1} = clause;
        end
        
        % Add multiple tags-like
        function obj = tagsLike(obj, varargin)
            forEachPair(varargin, @(k, v) obj.tagLike(k, v));
        end
        
        % Configure the where clause
        function obj = where(obj, where)
            obj.Where = where;
        end
        
        % Specify before time constraint
        function obj = before(obj, before, precision)
            if nargin < 3 || isempty(precision)
                precision = 'ms';
            end
            if isempty(before)
                obj.Before = [];
            elseif ischar(before)
                obj.Before = ['time < ''' before ''''];
            elseif isdatetime(before)
                str = TimeUtils.formatDatetime(before, precision, true);
                obj.Before = ['time < ' str];
            else
                error('unsupported time type');
            end
        end
        
        % Specify before or equals time constraint
        function obj = beforeEquals(obj, before, precision)
            if nargin < 3 || isempty(precision)
                precision = 'ms';
            end
            if isempty(before)
                obj.Before = [];
            elseif ischar(before)
                obj.Before = ['time <= ''' before ''''];
            elseif isdatetime(before)
                str = TimeUtils.formatDatetime(before, precision, true);
                obj.Before = ['time <= ' str];
            else
                error('unsupported time type');
            end
        end
        
        % Specify after time constraint
        function obj = after(obj, after, precision)
            if nargin < 3 || isempty(precision)
                precision = 'ms';
            end
            if isempty(after)
                obj.After = [];
            elseif ischar(after)
                obj.After = ['time > ''' after ''''];
            elseif isdatetime(after)
                str = TimeUtils.formatDatetime(after, precision, true);
                obj.After = ['time > ' str];
            else
                error('unsupported time type');
            end
        end
        
        % Specify after time constraint
        function obj = afterEquals(obj, after, precision)
            if nargin < 3 || isempty(precision)
                precision = 'ms';
            end
            if isempty(after)
                obj.After = [];
            elseif ischar(after)
                obj.After = ['time >= ''' after ''''];
            elseif isdatetime(after)
                str = TimeUtils.formatDatetime(after, precision, true);
                obj.After = ['time >= ' str];
            else
                error('unsupported time type');
            end
        end
        
        % Configure a group by time clause
        function obj = groupByTime(obj, time, fill)
            if nargin > 1 && ~isempty(time)
                obj.GroupByTimeInterval = ['time(' time ')'];
                if nargin > 2 && ~isempty(fill)
                    obj.GroupByTimeFill = ['fill(' fill ')'];
                else
                    obj.GroupByTimeFill = '';
                end
            else
                obj.GroupByTimeInterval = '';
                obj.GroupByTimeFill = '';
            end
        end
        
        % Configure a group by tags clause
        function obj = groupByTags(obj, varargin)
            if nargin > 1
                tags = varargin;
                for i = 1:length(tags)
                    tag = tags{i};
                    if ~strcmp(tag, '*')
                        tags{i} = ['"' tag '"'];
                    end
                    obj.GroupByTags = tags;
                end
            else
                obj.GroupByTags = {'*'};
            end
        end
        
        % Configure the maximum number of points to return
        function obj = limit(obj, limit)
            obj.Limit = limit;
        end
        
        % Build the query string
        function query = build(obj)
            query = obj.buildBaseQuery();
            query = obj.appendWhereTo(query);
            query = obj.appendGroupByTo(query);
            query = obj.appendLimitTo(query);
        end
        
        % Execute the query and unpack the response
        function [result, query] = execute(obj)
            assert(~isempty(obj.InfluxDB), 'execute:clientNotSet', ...
                'the influxdb client is not set for this builder');
            query = obj.build();
            result = obj.InfluxDB.runQuery(query, obj.Database, obj.Epoch);
        end
    end
    
    methods(Access = private)
        % Build base query
        function query = buildBaseQuery(obj)
            assert(~isempty(obj.Series), 'build:emptySeries', 'series not defined');
            series = strjoin(obj.Series, ',');
            fields = strjoin(obj.Fields, ',');
            query = ['SELECT ' fields ' FROM ' series];
        end
        
        % Append limit
        function query = appendLimitTo(obj, query)
            if ~isempty(obj.Limit) && obj.Limit > 0
                query = [query ' LIMIT ' num2str(int32(obj.Limit))];
            end
        end
        
        % Append where clause
        function query = appendWhereTo(obj, query)
            clauses = [obj.Tags, {obj.Before, obj.After, obj.Where}];
            ispresent = ~cellfun(@isempty, clauses);
            condition = strjoin(clauses(ispresent), ' AND ');
            if ~isempty(condition)
                query = [query ' WHERE ' condition];
            end
        end
        
        % Append group by clause
        function query = appendGroupByTo(obj, query)
            interval = obj.GroupByTimeInterval;
            tags = obj.GroupByTags;
            if ~isempty(interval) || ~isempty(tags)
                groupby = strjoin([interval, tags], ',');
                fill = obj.GroupByTimeFill;
                if ~isempty(interval) && ~isempty(fill)
                    query = [query ' GROUP BY ' groupby ' ' fill];
                else
                    query = [query ' GROUP BY ' groupby];
                end
            end
        end
    end
    
end
