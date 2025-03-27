# b=1000 ~2x faster than b=2
function _cat(arrays::AbstractVector{<:AbstractArray}; dims, b=1000)
    n = length(arrays)
    n == 0 && throw(ArgumentError("No arrays provided"))
    n == 1 && return collect(first(arrays))

    current = collect(arrays)

    while length(current) > 1
        new = Vector{Any}(undef, ceil(Int, length(current) / b))
        j = 1
        for i in 1:b:length(current)
            group = current[i:min(i+b-1, length(current))]
            new[j] = (length(group) == 1) ? group[1] : cat(group...; dims=dims)
            j += 1
        end
        current = new
    end
    
    return only(current)
end
