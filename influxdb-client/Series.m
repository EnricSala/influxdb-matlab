classdef Series < handle
    
    properties(Access = private)
        Name = []
        Tags = {}
        Fields = {}
        Time = []
    end
    
    methods
        % Constructor
        function obj = Series(name)
            obj.Name = name;
        end
        
        % Add a tag
        function obj = tag(obj, key, value)
            if isnumeric(value) || islogical(value)
                obj.Tags{end + 1} = [Series.safeKey(key) '=' value];
            elseif ischar(value)
                obj.Tags{end + 1} = [Series.safeKey(key) '=' Series.safeKey(value)];
            else
                error('unsupported tag type');
            end
        end
        
        % Add multiple tags at once
        function obj = tags(obj, varargin)
            forEachPair(varargin, @(k, v) obj.tag(k, v));
        end
        
        % Add a field value
        function obj = field(obj, key, value)
            if ischar(value)
                field = struct('key', key, 'value', {{value}});
                obj.Fields{end + 1} = field;
            elseif isempty(value)
                % ignore field with empty value
            elseif isnumeric(value) || islogical(value)
                field = struct('key', key, 'value', value);
                obj.Fields{end + 1} = field;
            elseif iscell(value)
                field = struct('key', key, 'value', {value});
                obj.Fields{end + 1} = field;
            else
                error('unsupported value type');
            end
        end
        
        % Add multiple fields at once
        function obj = fields(obj, varargin)
            forEachPair(varargin, @(k, v) obj.field(k, v));
        end
        
        % Set the time
        function obj = time(obj, time)
            if isdatetime(time)
                obj.Time = time;
            else
                error('unsupported time type');
            end
        end
        
        % Import data from other structures
        function obj = import(obj, data)
            if istimetable(data) || istable(data)
                insert = @(x) obj.field(x, data.(x));
                cellfun(insert, data.Properties.VariableNames);
                if istimetable(data)
                    obj.time(data.Properties.RowTimes);
                end
            else
                error('unsupported import data type');
            end
        end
        
        % Format to Line Protocol
        function lines = toLine(obj, precision)
            time_length = length(obj.Time);
            field_lengths = unique(cellfun(@(x) length(x.value), obj.Fields));
            
            % Check if the series name is valid
            assert(~isempty(obj.Name), ...
                'toLine:emptyName', 'series name cannot be empty');
            
            % Return empty if there are no fields
            if isempty(field_lengths)
                lines = '';
                return;
            end
            
            % Make sure the dimensions match
            assert(length(field_lengths) == 1, ...
                'toLine:sizeMismatch', 'all fields must have the same length');
            assert(time_length == field_lengths || time_length == 0, ...
                'toLine:sizeMismatch', 'time and fields must have the same length');
            assert(~isempty(obj.Time) || field_lengths == 1, ...
                'toLine:emptyTime', 'the time vector cannot be empty');
            
            % Obtain the time precision scale
            if time_length > 0
                if nargin < 2, precision = 'ms'; end
                scale = TimeUtils.scaleOfPrecision(precision);
                timestamp = int64(scale * posixtime(obj.Time));
            end
            
            % Create a line for each sample
            measurement = Series.safeMeasurement(obj.Name);
            prefix = [strjoin([{measurement}, obj.Tags], ',') ' '];
            
            builder = '';
            for i = 1:field_lengths
                values = '';
                for f = 1:length(obj.Fields)
                    field = obj.Fields{f};
                    name = Series.safeKey(field.key);
                    value = field.value;
                    if iscell(value)
                        str = obj.fieldFmt(name, value{i});
                    else
                        str = obj.fieldFmt(name, value(i));
                    end
                    if ~isempty(str)
                        values = [values, str, ','];
                    end
                end
                if ~isempty(values)
                    values = values(1:end-1);
                    if time_length > 0
                        time = sprintf(' %i', timestamp(i));
                        builder = [builder, prefix, values, time, newline];
                    else
                        builder = [builder, prefix, values, newline];
                    end
                end
            end
            lines = iif(isempty(builder), '', builder(1:end-1));
        end
    end
    
    methods(Static, Access = private)
        % Format a field
        function str = fieldFmt(key, value)
            if isfloat(value)
                if ~isempty(value) && isfinite(value)
                    str = sprintf('%s=%.8g', key, value);
                else
                    str = '';
                end
            elseif isinteger(value)
                str = sprintf('%s=%ii', key, value);
            elseif ischar(value)
                str = [key '="' Series.safeValue(value) '"'];
            elseif islogical(value)
                str = [key '=' iif(value, 'true', 'false')];
            else
                error('unsupported value type');
            end
        end
        
        % The following functions escape special characters according to:
        % https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_reference/#special-characters
        function safe = safeValue(value)
            safe = regexprep(value, '["\\]', '\\$0');
        end
        
        function safe = safeKey(key)
            safe = regexprep(key, '[,= ]', '\\$0');
        end
        
        function safe = safeMeasurement(name)
            safe = regexprep(name, '[, ]', '\\$0');
        end
    end
    
end
