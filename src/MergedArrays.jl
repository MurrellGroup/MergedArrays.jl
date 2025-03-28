module MergedArrays

using EllipsisNotation
using ConstructionBase

include("utils.jl")

export Merged, merged

struct MergedArray{S<:AbstractArray,N,R} <: AbstractArray{S,N}
    storage::S
    size::Dims{N}
    ranges::R
end

Base.size(ma::MergedArray) = ma.size

Base.getindex(ma::MergedArray, i::Integer) = ma.storage[.., ma.ranges[i]]

function Base.getindex(ma::MergedArray{<:Any,N}, i::Integer...) where N
    return ma[LinearIndices(ma.size)[i...]]
end

function MergedArray(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N
    lengths = Iterators.map(last ∘ size, arrays)
    cumlens = Iterators.accumulate(+, lengths, init=0)
    ranges = [i+1:j for (i,j) in zip(Iterators.flatten((0, cumlens)), cumlens)]
    storage = _cat(arrays; dims=N)
    return MergedArray(storage, size(arrays), ranges)
end

merged(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N = MergedArray(arrays)


struct MergedStrings{N,MA<:MergedArray{<:Any,N}} <: AbstractArray{String,N}
    ma::MA
end

Base.size(ms::MergedStrings) = size(ms.ma)

Base.getindex(ms::MergedStrings, i...) = String(ms.ma[i...])

merged(strings::AbstractArray{<:AbstractString}) = MergedStrings(MergedArray(codeunits.(strings)))


struct Merged{T,N,S<:NamedTuple,C} <: AbstractArray{T,N}
    storage::S
    size::Dims{N}
    constructor::C
end

function Merged{T}(storage::S, size::Dims{N}) where {T,N,S<:NamedTuple}
    constructor = constructorof(T)
    return Merged{T,N,S,typeof(constructor)}(storage, size, constructor)
end

Base.size(m::Merged) = m.size

Base.getindex(m::Merged, i...) = m.constructor(map(v -> v[i...], m.storage)...)

function merged(xs::AbstractArray{T}) where T
    isempty(xs) && throw(ArgumentError("Cannot merge empty vector"))
    isbitstype(T) && return xs
    pairs = []
    for name in fieldnames(T)
        push!(pairs, name => merged([getfield(x, name) for x in xs]))
    end
    storage = (; pairs...)
    constructor = constructorof(T)
    newT = typeof(constructor(first.(last.(pairs))...))
    return Merged{newT}(storage, size(xs))
end

end
