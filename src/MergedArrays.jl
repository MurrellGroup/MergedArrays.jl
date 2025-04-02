module MergedArrays

using ConstructionBase

include("utils.jl")

export MergedArray, MergedVector, MergedMatrix
export MergedStrings
export Merged
export merged

struct MergedArray{T,N,S<:AbstractArray,R} <: AbstractArray{T,N}
    storage::S
    size::Dims{N}
    ranges::R
end

const MergedVector = MergedArray{1}
const MergedMatrix = MergedArray{2}

MergedArray{T}(storage::S, size::Dims{N}, ranges::R) where {T,N,S<:AbstractArray,R} =
    MergedArray{T,N,S,R}(storage, size, ranges)

Base.convert(::Type{MergedArray{T}}, ma::MergedArray) where T =
    MergedArray{T}(ma.storage, ma.size, ma.ranges)

function MergedArray(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N
    lengths = Iterators.map(last ∘ size, arrays)
    cumlens = Iterators.accumulate(+, lengths, init=0)
    ranges = [i+1:j for (i,j) in zip(Iterators.flatten((0, cumlens)), cumlens)]
    storage = _cat(arrays; dims=N)
    ma = MergedArray{Any}(storage, size(arrays), ranges)
    T = typeof(first(ma))
    return convert(MergedArray{T}, ma)
end

Base.size(ma::MergedArray) = ma.size

function Base.view(ma::MergedArray{T}, I...) where T
    is = LinearIndices(ma)[I...]
    return MergedArray{T}(ma.storage, size(is), view(ma.ranges, is))
end

Base.getindex(ma::MergedArray, i::Integer) = collect(selectdim(ma.storage, ndims(ma.storage), ma.ranges[i]))
Base.getindex(ma::MergedArray, i::Integer...) = ma[LinearIndices(ma.size)[i...]]
Base.getindex(ma::MergedArray, I...) = [ma[i] for i in LinearIndices(ma)[I...]]

merged(arrays::AbstractArray{<:AbstractArray{<:Any,N}}) where N = MergedArray(arrays)

Base.getindex(ma::MergedArray{String}, i::Integer) = String(invoke(getindex, Tuple{MergedArray, Integer}, ma, i))

merged(strings::AbstractArray{<:AbstractString}) =
    convert(MergedArray{String}, MergedArray(codeunits.(strings)))


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
    !isconcretetype(T) && throw(ArgumentError("Cannot merge array of non-concrete type $T"))
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
