function _cat(arrays::AbstractArray{<:AbstractArray{T,N}}; dims::Integer) where {T,N}
    isempty(arrays) && throw(ArgumentError("No arrays provided"))
    dims > N && throw(ArgumentError("dims > N is currently not supported"))

    first_arr = first(arrays)
    refsize = size(first_arr)
    total = 0

    for arr in arrays
        s = size(arr)
        total += s[dims]
        for i in 1:N
            i != dims && s[i] != refsize[i] && throw(DimensionMismatch("Inconsistent dimensions"))
        end
    end

    final_size = ntuple(i -> i == dims ? total : refsize[i], N)
    result = similar(first_arr, T, final_size)
    i = 0
    @inbounds for arr in arrays
        k = size(arr, dims)
        copyto!(selectdim(result, dims, i+1:i+k), arr)
        i += k
    end
    
    return result
end