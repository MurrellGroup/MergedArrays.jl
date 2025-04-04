module MergedArrays

import ArraysOfArrays
using ConstructionBase

export AbstractMergedArray, AbstractMergedVector, AbstractMergedMatrix
export MergedArray, MergedVector, MergedMatrix
export MergedArrayOfArrays, MergedVectorOfArrays, MergedMatrixOfArrays
export MergedArrayOfStrings, MergedVectorOfStrings, MergedMatrixOfStrings

# main API
export merged


abstract type AbstractMergedArray{T,N} <: AbstractArray{T,N} end

const AbstractMergedVector = AbstractMergedArray{<:Any,1}
const AbstractMergedMatrix = AbstractMergedArray{<:Any,2}

# only for pretty-printing
parent_type(@nospecialize array::AbstractMergedArray) = array._parent_type

function Base.showarg(io::IO, array::AbstractMergedArray, toplevel)
    print(io, "merged(::$(parent_type(array)))")
end


struct MergedArray{T,N,S<:NamedTuple,C,P} <: AbstractMergedArray{T,N}
    _eltype::Type{T}
    _storage::S
    _size::Dims{N}
    _constructor::C
    _parent_type::Type{P}
end

function MergedArray{T}(storage::S, size::Dims{N}, _parent_type::Type) where {T,N,S<:NamedTuple}
    return MergedArray(T, storage, size, constructorof(T), _parent_type)
end

const MergedVector = MergedArray{<:Any,1}
const MergedMatrix = MergedArray{<:Any,2}

Base.size(array::MergedArray) = array._size

Base.getindex(array::MergedArray, i::Integer...) = array._constructor(map(v -> v[i...], array._storage)...)
Base.getindex(array::MergedArray, I...) = [array[i] for i in LinearIndices(array)[I...]]

function Base.getproperty(array::MergedArray, prop::Symbol)
    if prop in fieldnames(MergedArray)
        return getfield(array, prop)
    else
        return getproperty(array._storage, prop)
    end
end


function MergedArray(xs::AbstractArray{T}) where T
    pairs = Pair{Symbol,Any}[]
    for name in fieldnames(T)
        push!(pairs, name => merged([getfield(x, name) for x in xs]))
    end
    storage = (; pairs...)
    newT = typeof(constructorof(T)(first.(last.(pairs))...))
    return MergedArray{newT}(storage, size(xs), typeof(xs))
end


# ArraysOfArrays.VectorOfArrays with arbitrary dimensions
# constrained in that it's not mutable/resizeable like ArraysOfArrays.VectorOfArrays
struct MergedArrayOfArrays{T,N,M,S<:ArraysOfArrays.VectorOfArrays{T,M},P} <: AbstractMergedArray{Array{T,M},N}
    storage::S
    size::Dims{N}
    _parent_type::Type{P}
end

const MergedVectorOfArrays = MergedArrayOfArrays{<:Any,1}
const MergedMatrixOfArrays = MergedArrayOfArrays{<:Any,2}

function MergedArrayOfArrays(arrays::AbstractArray{<:AbstractArray})
    return MergedArrayOfArrays(ArraysOfArrays.VectorOfArrays(vec(arrays)), size(arrays), typeof(arrays))
end

Base.size(array::MergedArrayOfArrays) = array.size

Base.getindex(array::MergedArrayOfArrays, i::Integer) = collect(array.storage[i])
Base.getindex(array::MergedArrayOfArrays, i::Integer...) = array[LinearIndices(array)[i...]]
Base.getindex(array::MergedArrayOfArrays, i::CartesianIndex) = array[LinearIndices(array)[i]]

function Base.getindex(array::MergedArrayOfArrays, I...)
    is = LinearIndices(array)[I...]
    return MergedArrayOfArrays(array.storage[vec(is)], size(is), array._parent_type)
end


struct MergedArrayOfStrings{N,A<:MergedArrayOfArrays{<:Any,N},P} <: AbstractMergedArray{String,N}
    array::A
    _parent_type::Type{P}
end

const MergedVectorOfStrings = MergedArrayOfStrings{1}
const MergedMatrixOfStrings = MergedArrayOfStrings{2}

function MergedArrayOfStrings(strings::AbstractArray{<:AbstractString})
    return MergedArrayOfStrings(MergedArrayOfArrays(codeunits.(strings)), typeof(strings))
end

Base.size(strings::MergedArrayOfStrings) = size(strings.array)

Base.getindex(strings::MergedArrayOfStrings, i::Integer...) = String(strings.array[i...])
Base.getindex(strings::MergedArrayOfStrings, i::CartesianIndex) = String(strings.array[i])
Base.getindex(strings::MergedArrayOfStrings, I...) = MergedArrayOfStrings(strings.array[I...], strings._parent_type)


"""
    merged(array::AbstractArray)

Change the memory layout of `array` and its elements to minimize
references and reduce strain on the garbage collector.
"""
function merged end

function merged(xs::AbstractArray{T}) where T
    isempty(xs) && return xs
    isbitstype(T) && return xs
    if !isconcretetype(T)
        narrowed_xs = identity.(xs) # Any[1, 2] -> Int[1, 2], Any[1, 1.0] -> Real[1, 1.0]
        narrowed_T = eltype(narrowed_xs)
        narrowed_T >: T || return merged(narrowed_xs)
        @warn "Failed to narrow element type to a concrete type."
        return narrowed_xs
    end
    return MergedArray(xs)
end

merged(arrays::AbstractArray{<:AbstractArray}) = MergedArrayOfArrays(arrays)
merged(strings::AbstractArray{<:AbstractString}) = MergedArrayOfStrings(strings)

end
