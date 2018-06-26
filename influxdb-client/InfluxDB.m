classdef InfluxDB < handle
    
    properties(Access = private)
        Host, User, Password, Database;
    end
    
    methods
        % Constructor
        function obj = InfluxDB(host, user, password, database)
            obj.Host = host;
            obj.User = user;
            obj.Password = password;
            obj.Database = database;
        end
        
        % Test the connection with a ping
        function [ok, millis] = ping(obj)
            timer = tic;
            url = [obj.Host '/ping'];
            [~, status] = urlread(url);
            millis = toc(timer) * 1000;
            ok = logical(status);
        end
        
        % Show databases
        function databases = databases(obj)
            url = [obj.Host '/query'];
            opts = weboptions('Username', obj.User, 'Password', obj.Password);
            response = webread(url, 'q', 'SHOW DATABASES', opts);
            databases = [response.results.series.values{:}];
        end
        
        % Change the current database
        function obj = use(obj, database)
            obj.Database = database;
        end
        
        % Execute a query string
        function result = runQuery(obj, query)
            url = [obj.Host '/query'];
            opts = weboptions('Username', obj.User, 'Password', obj.Password);
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
        function [] = runWrite(obj, lines)
            url = [obj.Host '/write?db=' obj.Database '&precision=ms'];
            opts = weboptions('Username', obj.User, 'Password', obj.Password);
            webwrite(url, lines, opts);
        end
        
        % Obtain a write builder
        function builder = writer(obj)
            builder = WriteBuilder().influxdb(obj);
        end
    end
    
end
