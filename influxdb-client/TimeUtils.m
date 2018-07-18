classdef TimeUtils
    
    properties(Constant, Access = private)
        DEFAULT_PRECISION = 'ms'
        DEFAULT_APPEND_PRECISION = false
        PRECISIONS = {'ns', 'u', 'ms', 's', 'm', 'h'}
        EPOCHS = {'ns', 'u', 'ms', 's', 'm', 'h'}
    end
    
    methods(Static)
        % Format a datetime as a string
        function str = formatDatetime(dtime, precision, appendPrecision)
            if nargin < 2, precision = TimeUtils.DEFAULT_PRECISION; end
            if nargin < 3, appendPrecision = TimeUtils.DEFAULT_APPEND_PRECISION; end
            scale = TimeUtils.scaleOfPrecision(precision);
            value = int64(scale * posixtime(dtime));
            if appendPrecision
                str = [num2str(value), precision];
            else
                str = num2str(value);
            end
        end
        
        % Format a datenum as a string
        function str = formatDatenum(dnum, precision, appendPrecision)
            if nargin < 2, precision = TimeUtils.DEFAULT_PRECISION; end
            if nargin < 3, appendPrecision = TimeUtils.DEFAULT_APPEND_PRECISION; end
            warning('datenums do not specify a timezone, assuming local');
            dtime = datetime(dnum, 'ConvertFrom', 'datenum', 'TimeZone', 'local');
            str = TimeUtils.formatDatetime(dtime, precision, appendPrecision);
        end
        
        % Convert a timestamp to a datetime
        function dtime = toDatetime(timestamp, precision)
            scale = TimeUtils.scaleOfPrecision(precision);
            dtime = datetime(timestamp / scale, ...
                'ConvertFrom', 'posixtime', 'TimeZone', 'local');
        end
        
        % Validate a precision
        function validatePrecision(precision)
            assert(any(strcmp(precision, TimeUtils.PRECISIONS)), ...
                'precision:unknown', '"%s" is not a valid precision', precision);
        end
        
        % Obtain the scale for a precision
        function scale = scaleOfPrecision(precision)
            switch precision
                case 'ns'
                    scale = 1000000000;
                case 'u'
                    scale = 1000000;
                case 'ms'
                    scale = 1000;
                case 's'
                    scale = 1;
                case 'm'
                    scale = 1 / 60;
                case 'h'
                    scale = 1 / 3600;
                otherwise
                    error('precision:unknown', ...
                        '"%s" is not a valid precision', precision);
            end
        end
        
        % Validate an epoch
        function validateEpoch(epoch)
            assert(any(strcmp(epoch, TimeUtils.EPOCHS)), ...
                'epoch:unknown', '"%s" is not a valid epoch', epoch);
        end
        
        % Obtain the scale for an epoch
        function scale = scaleOfEpoch(epoch)
            switch epoch
                case 'ns'
                    scale = 1000000000;
                case 'u'
                    scale = 1000000;
                case 'ms'
                    scale = 1000;
                case 's'
                    scale = 1;
                case 'm'
                    scale = 1 / 60;
                case 'h'
                    scale = 1 / 3600;
                otherwise
                    error('epoch:unknown', ...
                        '"%s" is not a valid epoch', epoch);
            end
        end
    end
    
end
