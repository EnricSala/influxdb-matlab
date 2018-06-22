classdef QueryBuilder < handle
    
    properties(Access = private)
        Influx, Series, Fields, Tags, Before, After, Where, Limit;
    end
    
    methods
        % Constructor
        function obj = QueryBuilder(influx, series)
            obj.Influx = influx;
            obj.series(series);
            obj.fields('*');
            obj.Tags = {};
            obj.Before = [];
            obj.After = [];
            obj.Where = [];
            obj.Limit = [];
        end
        
        % Configure which series to query
        function obj = series(obj, series)
            assert(~isempty(series), 'must specify at least 1 serie');
            obj.Series = iif(iscell(series), series, { series });
        end
        
        % Configure returned fields
        function obj = fields(obj, fields)
            assert(~isempty(fields), 'must specify at least 1 field');
            obj.Fields = iif(iscell(fields), fields, { fields });
        end
        
        % Add tag conditions
        function obj = tagged(obj, key, values)
            fmt = @(x) ['"' key '"=''' x ''''];
            if iscell(values)
                terms = cellfun(fmt, values, 'UniformOutput', false);
                clause = ['(' strjoin(terms, ' OR ') ')'];
            else
                clause = fmt(values);
            end
            obj.Tags{end + 1} = clause;
        end
        
        % Configure where clause
        function obj = where(obj, where)
            obj.Where = where;
        end
        
        % Specify before time constraint
        function obj = before(obj, before)
            if isempty(before)
                obj.Before = [];
            elseif ischar(before)
                obj.Before = ['time < ''' before ''''];
            elseif isdatetime(before)
                obj.Before = ['time < ' obj.formatDatetime(before) 'ms'];
            elseif isfloat(before)
                obj.Before = ['time < ' obj.formatDatenum(before) 'ms'];
            else
                error('unsupported before type');
            end
        end
        
        % Specify before or equals time constraint
        function obj = beforeEquals(obj, before)
            if isempty(before)
                obj.Before = [];
            elseif ischar(before)
                obj.Before = ['time <= ''' before ''''];
            elseif isdatetime(before)
                obj.Before = ['time <= ' obj.formatDatetime(before) 'ms'];
            elseif isfloat(before)
                obj.Before = ['time <= ' obj.formatDatenum(before) 'ms'];
            else
                error('unsupported before type');
            end
        end
        
        % Specify after time constraint
        function obj = after(obj, after)
            if isempty(after)
                obj.After = [];
            elseif ischar(after)
                obj.After = ['time > ''' after ''''];
            elseif isdatetime(after)
                obj.After = ['time > ' obj.formatDatetime(after) 'ms'];
            elseif isfloat(after)
                obj.After = ['time > ' obj.formatDatenum(after) 'ms'];
            else
                error('unsupported before type');
            end
        end
        
        % Specify after time constraint
        function obj = afterEquals(obj, after)
            if isempty(after)
                obj.After = [];
            elseif ischar(after)
                obj.After = ['time >= ''' after ''''];
            elseif isdatetime(after)
                obj.After = ['time >= ' obj.formatDatetime(after) 'ms'];
            elseif isfloat(after)
                obj.After = ['time >= ' obj.formatDatenum(after) 'ms'];
            else
                error('unsupported before type');
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
            query = obj.appendLimitTo(query);
        end
        
        % Execute the query and unpack the response
        function [result, query] = execute(obj)
            query = obj.build();
            result = obj.Influx.rawQuery(query);
        end
    end
    
    methods(Access = private)
        % Build base query
        function query = buildBaseQuery(obj)
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
            clauses = [obj.Tags, {obj.Where, obj.Before, obj.After}];
            ispresent = cellfun(@(x) ~isempty(x), clauses);
            condition = strjoin(clauses(ispresent), ' AND ');
            if ~isempty(condition)
                query = [query ' WHERE ' condition];
            end
        end
    end
    
    methods(Static, Access = private)
        % Convert datetime to string
        function str = formatDatetime(dtime)
            str = num2str(int64(1000 * posixtime(dtime)));
        end
        
        % Convert datenum to string
        function str = formatDatenum(dnum)
            warning('timezone not specified, assuming local');
            dtime = datetime(dnum, 'ConvertFrom', 'datenum', 'TimeZone', 'local');
            str = QueryBuilder.formatDatetime(dtime);
        end
    end
    
end
