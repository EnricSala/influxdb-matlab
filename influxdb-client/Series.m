classdef Series < handle
    
    properties
        Name, Tags, Fields, Time;
    end
    
    methods
        % Constructor
        function obj = Series(name)
            obj.Name = name;
            obj.Tags = {};
            obj.Fields = {};
            obj.Time = [];
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
                warning(['value of field ' key ' is empty']);
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
                warning('timezone not specified, assuming local');
                obj.Time = datetime(time, 'ConvertFrom', 'datenum', 'TimeZone', 'local');
            else
                error('unsupported time type');
            end
        end
        
        % Format to Line Protocol
        function lines = toLine(obj)
            time_length = length(obj.Time);
            fields_length = unique(cellfun(@(x) length(x.value), obj.Fields));
            assert(length(fields_length) == 1, ...
                'toLine:sizeMismatch', 'all fields must have the same length');
            assert(time_length == fields_length || time_length == 0, ...
                'toLine:sizeMismatch', 'time and fields must have the same length');
            builder = java.lang.StringBuilder();
            for i = 1:fields_length
                point = Point(obj.Name);
                for t = 1:length(obj.Tags)
                    tag = obj.Tags{t};
                    point.tag(tag.key, tag.value);
                end
                for f = 1:length(obj.Fields)
                    field = obj.Fields{f};
                    name = field.key;
                    value = field.value;
                    if isnumeric(value) || islogical(value)
                        point.field(name, value(i));
                    elseif iscell(value)
                        point.field(name, value{i});
                    else
                        error('unsupported value type');
                    end
                end
                if ~isempty(obj.Time)
                    point.time(obj.Time(i));
                end
                builder.append(point.toLine());
                builder.append(newline);
            end
            builder.deleteCharAt(int32(builder.length() - 1));
            lines = builder.toString().toCharArray()';
        end
    end
    
end
