module MergedArrays

using ConstructionBase

include("utils.jl")

export MergedArray, MergedVector, MergedMatrix
export MergedStrings
export Merged
export merged

struct MergedArray{N,S<:AbstractArray,R} <: AbstractArray{S,N}
    storage::S
    size::Dims{N}
    ranges::R
end

const MergedVector = MergedArray{1}
const MergedMatrix = MergedArray{2}

Base.size(ma::MergedArray) = ma.size

Base.getindex(ma::MergedArray, i::Integer) = collect(selectdim(ma.storage, ndims(ma.storage), ma.ranges[i]))
Base.getindex(ma::MergedArray, i::Integer...) = ma[LinearIndices(ma.size)[i...]]
Base.getindex(ma::MergedArray, I...) = [ma[i] for i in LinearIndices(ma)[I...]]


function MergedArray(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N
    lengths = Iterators.map(last ∘ size, arrays)
    cumlens = Iterators.accumulate(+, lengths, init=0)
    ranges = [i+1:j for (i,j) in zip(Iterators.flatten((0, cumlens)), cumlens)]
    storage = _cat(arrays; dims=N)
    return MergedArray(storage, size(arrays), ranges)
end

merged(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N = MergedArray(arrays)


struct MergedStrings{N,MA<:MergedArray{N}} <: AbstractArray{String,N}
    ma::MA
end

Base.size(ms::MergedStrings) = size(ms.ma)

Base.getindex(ms::MergedStrings, i::Integer...) = String(ms.ma[i...])
Base.getindex(ms::MergedStrings, I...) = [ms[i] for i in LinearIndices(ms)[I...]]

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

Base.getindex(m::Merged, i::Integer...) = m.constructor(map(v -> v[i...], m.storage)...)
Base.getindex(m::Merged, I...) = [m[i] for i in LinearIndices(m)[I...]]

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
