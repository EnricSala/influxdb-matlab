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
            obj.Tags{end + 1} = struct('key', key, 'value', value);
        end
        
        % Add multiple tags at once
        function obj = tags(obj, varargin)
            forEachPair(varargin, @(k, v) obj.tag(k, v));
        end
        
        % Add a field value
        function obj = field(obj, key, value)
            if isempty(value)
                error('field:emptyValue', 'value of field "%s" is empty', key);
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
            elseif isfloat(time)
                obj.Time = datetime(time, 'ConvertFrom', 'datenum', 'TimeZone', 'local');
            else
                error('unsupported time type');
            end
        end
        
        % Format to Line Protocol
        function lines = toLine(obj, precision)
            time_length = length(obj.Time);
            field_lengths = unique(cellfun(@(x) length(x.value), obj.Fields));
            assert(~isempty(obj.Time), ...
                'toLine:emptyTime', 'the time vector cannot be empty');
            assert(~isempty(field_lengths), ...
                'toLine:emptyFields', 'must define at least one field');
            assert(length(field_lengths) == 1, ...
                'toLine:sizeMismatch', 'all fields must have the same length');
            assert(time_length == field_lengths || time_length == 0, ...
                'toLine:sizeMismatch', 'time and fields must have the same length');
            builder = java.lang.StringBuilder();
            for i = 1:field_lengths
                point = Point(obj.Name);
                for t = 1:length(obj.Tags)
                    tag = obj.Tags{t};
                    point.tag(tag.key, tag.value);
                end
                for f = 1:length(obj.Fields)
                    field = obj.Fields{f};
                    name = field.key;
                    value = field.value;
                    if iscell(value)
                        point.field(name, value{i});
                    else
                        point.field(name, value(i));
                    end
                end
                point.time(obj.Time(i));
                if nargin < 2
                    line = point.toLine();
                else
                    line = point.toLine(precision);
                end
                if ~isempty(line)
                    builder.append(line);
                    builder.append(newline);
                end
            end
            builder.deleteCharAt(int32(builder.length() - 1));
            lines = char(builder.toString());
        end
    end
    
end
