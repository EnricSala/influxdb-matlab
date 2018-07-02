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
            url = [obj.Url '/query'];
            opts = weboptions('Timeout', obj.ReadTimeout, ...
                'Username', obj.User, 'Password', obj.Password);
            response = webread(url, 'q', 'SHOW DATABASES', opts);
            databases = [response.results.series.values{:}];
        end
        
        % Change the current database
        function obj = use(obj, database)
            obj.Database = database;
        end
        
        % Execute a query string
        function result = runQuery(obj, query)
            url = [obj.Url '/query'];
            opts = weboptions('Timeout', obj.ReadTimeout, ...
                'Username', obj.User, 'Password', obj.Password);
            response = webread(url, 'db', obj.Database, 'epoch', 'ms', 'q', query, opts);
            result = QueryResult.from(response);
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
                assert(any(strcmp(precision, {'ns', 'u', 'ms', 's', 'm', 'h'})), ...
                    'precision:unknown', '"%s" is not a valid precision', precision);
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
    end
    
end
