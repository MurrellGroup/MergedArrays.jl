module MergedArrays

using EllipsisNotation
using ConstructionBase

include("utils.jl")

export Merged, merged

struct MergedArray{T,A<:AbstractArray,R} <: AbstractVector{T}
    storage::A
    ranges::R
end

function MergedArray{T}(storage::A, ranges::R) where {T,A<:AbstractArray,R}
    first(axes(storage, ndims(storage))) == 1 || error("storage array must have 1-based indexing")
    return MergedArray{T,A,R}(storage, ranges)
end

Base.size(ja::MergedArray) = size(ja.ranges)

Base.getindex(ja::MergedArray, i::Integer) = ja.storage[.., ja.ranges[i]]
Base.getindex(ja::MergedArray{String}, i::Integer) = String(ja.storage[.., ja.ranges[i]])

function _merge_array(arrays::AbstractVector{<:AbstractArray{<:Any,N}}) where N
    lengths = Iterators.map(last ∘ size, arrays)
    cumlens = Iterators.accumulate(+, lengths, init=0)
    ranges = [i+1:j for (i,j) in zip(Iterators.flatten((0, cumlens)), cumlens)]
    storage = _cat(arrays; dims=N)
    return storage, ranges
end

function _merge(arrays::AbstractVector{A}) where A<:AbstractArray
    storage, ranges = _merge_array(arrays)
    return MergedArray{typeof(storage)}(storage, ranges)
end

function _merge(strings::AbstractVector{S}) where S<:AbstractString
    storage, ranges = _merge_array(collect.(codeunits.(strings)))
    return MergedArray{String}(storage, ranges)
end

_merge(xs::AbstractVector) = xs


struct Merged{T,S<:NamedTuple,C} <: AbstractVector{T}
    storage::S
    len::Int
    constructor::C
end

function Merged{T}(storage::S, len::Int) where {T,S<:NamedTuple}
    constructor = constructorof(T)
    return Merged{T,S,typeof(constructor)}(storage, len, constructor)
end

Base.size(m::Merged) = (m.len,)

Base.getindex(m::Merged, i::Integer) = m.constructor(map(v -> v[i], m.storage)...)

function merged(xs::AbstractVector{T}) where T
    pairs = []
    for name in fieldnames(T)
        push!(pairs, name => _merge([getfield(x, name) for x in xs]))
    end
    storage = (; pairs...)
    return Merged{T}(storage, length(xs))
end

end
