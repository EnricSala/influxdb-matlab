function [] = forEachPair(args, action)
if length(args) == 1
    pairs = args{1};
else
    aux = cellfun(@nest, args, 'UniformOutput', false);
    pairs = struct(aux{:});
end
keys = fieldnames(pairs);
for i = 1:length(keys)
    key = keys{i};
    value = pairs.(key);
    action(key, value);
end
end

function y = nest(x)
if iscell(x)
    y = {x};
else
    y = x;
end
end
