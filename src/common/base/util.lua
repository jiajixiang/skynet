
local util = {}

function table.find(tbl,func)
    local isfunc = type(func) == "function"
    for k,v in pairs(tbl) do
        if isfunc then
            if func(k,v) then
                return k,v
            end
        else
            if func == v then
                return k,v
            end
        end
    end
end

function table.dump(t,depth,name)
    if type(t) ~= "table" then
        return tostring(t)
    end
    depth = depth or 0
    local max_depth = 5
    name = name or ""
    local cache = { [t] = "."}
    local function _dump(t,depth,name)
        local temp = {}
        local bracket_space = string.rep(" ",depth * 2)
        local space = string.rep(" ",(depth + 1) * 2)
        table.insert(temp,"{")
        if depth < max_depth then
            for k,v in pairs(t) do
                local key = tostring(k)
                if type(k) == "number" then
                    key = "[" .. key .. "]"
                end
                local value
                if cache[v] then
                    value = cache[v]
                elseif type(v) == "table" then
                    local new_key = name .. "." .. key
                    cache[v] = new_key
                    value = _dump(v,depth+1,new_key)
                else
                    if type(v) == "string" then
                        v = "\"" .. string.gsub(v,"\"","\\\"") .. "\""
                    end
                    value = tostring(v)
                end
                table.insert(temp,space .. key .. " = " .. value)
            end
        else
            table.insert(temp,space .. "...")
        end
        table.insert(temp,bracket_space .. "}")
        return table.concat(temp,"\n")
    end
    return _dump(t,depth,name)
end

function table.ksort(dict,join_str,exclude_keys,exclude_values)
    join_str = join_str or "&"
    exclude_keys = exclude_keys or {}
    exclude_values = exclude_values or {[""]=true}
    local list = {}
    for k,v in pairs(dict) do
        if (not exclude_keys or not exclude_keys[k]) and
            (not exclude_values or not exclude_values[v]) then
            table.insert(list,{k,v})
        end
    end
    table.sort(list,function (lhs,rhs)
        return lhs[1] < rhs[1]
    end)
    local list2 = {}
    for i,item in ipairs(list) do
        table.insert(list2,string.format("%s=%s",item[1],item[2]))
    end
    return table.concat(list2,join_str)
end


local function get_type_first_print( t )
    local str = type(t)
    return string.upper(string.sub(str, 1, 1))..":"
end

function util.dump_table(t, prefix, indent_input, print)
    local indent = indent_input
    if indent_input == nil then
        indent = 1
    end

    if print == nil then
        print = _G["print"]
    end

    local p = nil

    local formatting = string.rep("    ", indent)
    if prefix ~= nil then
        formatting = prefix .. formatting
    end

    if t == nil then
        print(formatting.." nil")
        return
    end

    if type(t) ~= "table" then
        print(formatting..get_type_first_print(t)..tostring(t))
        return
    end

    local output_count = 0
    for k,v in pairs(t) do
        local str_k = get_type_first_print(k)
        if type(v) == "table" then

            print(formatting..str_k..k.." -> ")

            util.dump_table(v, prefix, indent + 1,print)
        else
            print(formatting..str_k..k.." -> ".. get_type_first_print(v)..tostring(v))
        end
        output_count = output_count + 1
    end

    if output_count == 0 then
        print(formatting.." {}")
    end
end

return util
