function [] = forEachPair(args, action)
if isscalar(args)
    pairs = args{1};
    assert(isstruct(pairs), ...
        'argument must be a struct or key and value pairs');
    keys = fieldnames(pairs);
    for i = 1:length(keys)
        key = keys{i};
        value = pairs.(key);
        action(key, value);
    end
else
    assert(iseven(length(args)), ...
        'key and value arguments must come in pairs');
    for i = 1:2:length(args)
        key = args{i};
        value = args{i + 1};
        action(key, value);
    end
end
end

function even = iseven(number)
even = ~logical(mod(number, 2));
end
