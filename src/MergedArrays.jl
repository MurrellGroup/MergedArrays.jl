module MergedArrays

import ArraysOfArrays
using ConstructionBase

export AbstractMergedArray,  AbstractMergedVector,  AbstractMergedMatrix
export MergedArray,          MergedVector,          MergedMatrix
export MergedArrayOfArrays,  MergedVectorOfArrays,  MergedMatrixOfArrays
export MergedArrayOfStrings, MergedVectorOfStrings, MergedMatrixOfStrings

# main API
export merged


abstract type AbstractMergedArray{T,N} <: AbstractArray{T,N} end

const AbstractMergedVector = AbstractMergedArray{<:Any,1}
const AbstractMergedMatrix = AbstractMergedArray{<:Any,2}

# pretty-printing
parent_type(@nospecialize array::AbstractMergedArray) = array._parent_type
Base.showarg(io::IO, array::AbstractMergedArray, _) = print(io, "merged(::$(parent_type(array)))")

Base.getindex(array::AbstractMergedArray, i::Integer...) = array[LinearIndices(array)[i...]]
Base.getindex(array::AbstractMergedArray, i::CartesianIndex) = array[LinearIndices(array)[i]]
Base.getindex(array::AbstractMergedArray, I...) = [array[i] for i in LinearIndices(array)[I...]]


struct MergedArray{T,N,S<:NamedTuple,C,P} <: AbstractMergedArray{T,N}
    _eltype::Type{T}
    _size::Dims{N}
    _storage::S
    _constructor::C
    _parent_type::Type{P}
end

Base.size(array::MergedArray) = array._size
Base.getindex(array::MergedArray, i::Integer) = array._constructor(map(v -> v[i], array._storage)...)

Base.getproperty(array::MergedArray, prop::Symbol) = prop in fieldnames(MergedArray) ?
    getfield(array, prop) : getproperty(getfield(array, :_storage), prop)

function MergedArray(xs::AbstractArray{T}) where T
    pairs = Pair{Symbol,Any}[]
    for name in fieldnames(T)
        push!(pairs, name => merged([getfield(x, name) for x in xs]))
    end
    storage = (; pairs...)
    constructor = constructorof(T)
    x = constructor(first.(last.(pairs))...)
    return MergedArray(typeof(x), size(xs), storage, constructor, typeof(xs))
end


# essentially ArraysOfArrays.VectorOfArrays with arbitrary dimensions
struct MergedArrayOfArrays{T,N,M,S<:ArraysOfArrays.VectorOfArrays{T,M},P} <: AbstractMergedArray{Array{T,M},N}
    storage::S
    size::Dims{N}
    _parent_type::Type{P}
end

Base.size(array::MergedArrayOfArrays) = array.size
Base.getindex(array::MergedArrayOfArrays, i::Integer) = collect(array.storage[i])

function MergedArrayOfArrays(arrays::AbstractArray{<:AbstractArray})
    return MergedArrayOfArrays(ArraysOfArrays.VectorOfArrays(vec(arrays)), size(arrays), typeof(arrays))
end


struct MergedArrayOfStrings{N,A<:MergedArrayOfArrays{<:Any,N},P} <: AbstractMergedArray{String,N}
    array::A
    _parent_type::Type{P}
end

Base.size(strings::MergedArrayOfStrings) = size(strings.array)
Base.getindex(strings::MergedArrayOfStrings, i::Integer) = String(strings.array[i])

function MergedArrayOfStrings(strings::AbstractArray{<:AbstractString})
    return MergedArrayOfStrings(MergedArrayOfArrays(codeunits.(strings)), typeof(strings))
end


const MergedVector = MergedArray{<:Any,1}
const MergedMatrix = MergedArray{<:Any,2}

const MergedVectorOfArrays = MergedArrayOfArrays{<:Any,1}
const MergedMatrixOfArrays = MergedArrayOfArrays{<:Any,2}

const MergedVectorOfStrings = MergedArrayOfStrings{1}
const MergedMatrixOfStrings = MergedArrayOfStrings{2}


"""
    merged(array::AbstractArray)

Change the memory layout of `array` and its elements to minimize
references and reduce strain on the garbage collector.
"""
function merged end

# Any[1, 2] -> Int[1, 2]
# Any[1, 2.0] -> Real[1, 2.0]
# Vector{Any}[[1], Any[2]] -> Vector{Int}[[1], [2]]
nested_narrow(x) = identity(x)
nested_narrow(array::AbstractArray) = nested_narrow.(array)

function merged(xs::AbstractArray{T}) where T
    isempty(xs) && return xs
    isbitstype(T) && return xs
    if !isconcretetype(T)
        narrowed_xs = nested_narrow(xs)
        narrowed_T = eltype(narrowed_xs)
        narrowed_T >: T || return merged(narrowed_xs)
        @warn "Failed to narrow element type to a concrete type."
        return narrowed_xs
    end
    return MergedArray(xs)
end

merged(arrays::AbstractArray{<:AbstractArray{T}}) where T = MergedArrayOfArrays(arrays)
merged(arrays::AbstractArray{<:AbstractArray}) = MergedArrayOfArrays(nested_narrow(arrays))

merged(strings::AbstractArray{<:AbstractString}) = MergedArrayOfStrings(strings)

end
