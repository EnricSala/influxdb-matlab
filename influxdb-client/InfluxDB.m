classdef InfluxDB < handle
    
    properties(Access = private)
        Url = ''
        User = ''
        Password = ''
        Database = ''
        ReadTimeout = 10
        WriteTimeout = 10
    end
    
    methods
        % Constructor
        function obj = InfluxDB(url, user, password, database)
            obj.Url = url;
            obj.User = user;
            obj.Password = password;
            obj.Database = database;
        end
        
        % Set the read timeout
        function obj = setReadTimeout(obj, timeout)
            obj.ReadTimeout = timeout;
        end
        
        % Set the write timeout
        function obj = setWriteTimeout(obj, timeout)
            obj.WriteTimeout = timeout;
        end
        
        % Check the status of the InfluxDB instance
        function [ok, millis] = ping(obj)
            try
                timer = tic;
                webread([obj.Url '/ping']);
                millis = toc(timer) * 1000;
                ok = true;
            catch
                millis = Inf;
                ok = false;
            end
        end
        
        % Show databases
        function databases = databases(obj)
            result = obj.runCommand('SHOW DATABASES');
            databases = result.series().field('name');
        end
        
        % Change the current database
        function obj = use(obj, database)
            obj.Database = database;
        end
        
        % Execute a query string
        function result = runQuery(obj, query, database, epoch)
            if nargin < 3 || isempty(database)
                database = obj.Database;
            end
            if nargin < 4 || isempty(epoch)
                epoch = 'ms';
            else
                TimeUtils.validateEpoch(epoch);
            end
            if iscell(query)
                query = strjoin(query, ';');
            end
            params = {['db=' database], ['epoch=' epoch], ['q=' query]};
            url = [obj.Url '/query?' strjoin(params, '&')];
            opts = weboptions('Timeout', obj.ReadTimeout, ...
                'Username', obj.User, 'Password', obj.Password);
            response = webread(url, opts);
            result = QueryResult.from(response, epoch);
        end
        
        % Obtain a query builder
        function builder = query(obj, varargin)
            if nargin > 2
                builder = QueryBuilder().series(varargin).influxdb(obj);
            elseif nargin > 1
                builder = QueryBuilder().series(varargin{1}).influxdb(obj);
            else
                builder = QueryBuilder().influxdb(obj);
            end
        end
        
        % Execute a write of a line protocol string
        function [] = runWrite(obj, lines, database, precision, retention, consistency)
            params = {};
            if nargin > 2 && ~isempty(database)
                params{end + 1} = ['db=' urlencode(database)];
            else
                params{end + 1} = ['db=' urlencode(obj.Database)];
            end
            if nargin > 3 && ~isempty(precision)
                TimeUtils.validatePrecision(precision);
                params{end + 1} = ['precision=' precision];
            end
            if nargin > 4  &&  ~isempty(retention)
                params{end + 1} = ['rp=' urlencode(retention)];
            end
            if nargin > 5  &&  ~isempty(consistency)
                assert(any(strcmp(consistency, {'any', 'one', 'quorum', 'all'})), ...
                    'consistency:unknown', '"%s" is not a valid consistency', consistency);
                params{end + 1} = ['consistency=' consistency];
            end
            url = [obj.Url '/write?' strjoin(params, '&')];
            opts = weboptions('Timeout', obj.WriteTimeout, ...
                'Username', obj.User, 'Password', obj.Password);
            webwrite(url, lines, opts);
        end
        
        % Obtain a write builder
        function builder = writer(obj)
            builder = WriteBuilder().influxdb(obj);
        end
        
        % Execute other queries or commands
        function result = runCommand(obj, command, varargin)
            idx = find(cellfun(@ischar, varargin), 1, 'first');
            database = iif(isempty(idx), '', varargin{idx});
            idx = find(cellfun(@islogical, varargin), 1, 'first');
            requiresPost = iif(isempty(idx), false, varargin{idx});
            if isempty(database)
                params = {'q', command};
            else
                params = {'db', database, 'q', command};
            end
            url = [obj.Url '/query'];
            opts = weboptions('Username', obj.User, 'Password', obj.Password);
            if requiresPost
                opts.Timeout = obj.WriteTimeout;
                response = webwrite(url, params{:}, opts);
            else
                opts.Timeout = obj.ReadTimeout;
                response = webread(url, params{:}, opts);
            end
            result = QueryResult.from(response);
        end
    end
    
end
