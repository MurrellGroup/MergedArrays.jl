# MergedArrays

[![Build Status](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/MurrellGroup/MergedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/MurrellGroup/MergedArrays.jl)

MergedArray exports the `merged` function: taking an `AbstractArray` of some data structure, returning a `Merged <: AbstractArray` with a memory layout designed to minimize references, reducing strain on Julia's garbage collection system.

The `merged` function takes an array of structures and merges the storage and references of nested fields:
- `AbstractArray` fields -> `MergedArrayOfArrays`
- `AbstractString` fields -> `MergedArrayOfStrings` (single reference)
- other nested fields -> `Array`

Other fields values are simply stored in `Array`s, akin to [https://github.com/JuliaArrays/StructArrays.jl](StructArrays.jl).

## Example

```julia
julia> struct Points{T}
           name::String
           vibe::Float32
           points::Matrix{T}
       end

julia> a = [Points("first", 1.0f0, [0; 1;; 2; 3;; 4; 5]), Points("last", 0.2f0, [6; 7;; 8; 9])]
2-element Vector{Points{Int64}}:
 Points{Int64}("first", 1.0f0, [0 2 4; 1 3 5])
 Points{Int64}("last", 0.2f0, [6 8; 7 9])

julia> m = merged(a)
2-element MergedVector{Points{Int64}, @NamedTuple{name::MergedVectorOfStrings{MergedVectorOfArrays{UInt8, 1, ArraysOfArrays.VectorOfVectors{UInt8, Vector{UInt8}, Vector{Int64}, Vector{Tuple{}}}}}, vibe::Vector{Float32}, points::MergedVectorOfArrays{Int64, 2, ArraysOfArrays.VectorOfArrays{Int64, 2, 1, Vector{Int64}, Vector{Int64}, Vector{Tuple{Int64}}}}}, UnionAll}:
 Points{Int64}("first", 1.0f0, [0 2 4; 1 3 5])
 Points{Int64}("last", 0.2f0, [6 8; 7 9])

julia> m[1]
Points{Int64}("first", 1.0f0, [0 2 4; 1 3 5])
```

## Implementation details

For the curious:

```julia
julia> m.storage.name
2-element MergedVectorOfStrings{MergedVectorOfArrays{UInt8, 1, ArraysOfArrays.VectorOfVectors{UInt8, Vector{UInt8}, Vector{Int64}, Vector{Tuple{}}}}}:
 "first"
 "last"

julia> m.storage.name.array.storage
2-element ArraysOfArrays.VectorOfVectors{UInt8, Vector{UInt8}, Vector{Int64}, Vector{Tuple{}}}:
 UInt8[0x66, 0x69, 0x72, 0x73, 0x74]
 UInt8[0x6c, 0x61, 0x73, 0x74]

julia> m.storage.name.array.storage.data
9-element Vector{UInt8}:
 0x66
 0x69
 0x72
 0x73
 0x74
 0x6c
 0x61
 0x73
 0x74

julia> m.storage.vibe
2-element Vector{Float32}:
 1.0
 0.2

julia> m.storage.points
2-element MergedVectorOfArrays{Int64, 2, ArraysOfArrays.VectorOfArrays{Int64, 2, 1, Vector{Int64}, Vector{Int64}, Vector{Tuple{Int64}}}}:
 [0 2 4; 1 3 5]
 [6 8; 7 9]

julia> m.storage.points.storage
2-element ArraysOfArrays.VectorOfArrays{Int64, 2, 1, Vector{Int64}, Vector{Int64}, Vector{Tuple{Int64}}}:
 [0 2 4; 1 3 5]
 [6 8; 7 9]

julia> m.storage.points.storage.data
10-element Vector{Int64}:
 0
 1
 2
 3
 4
 5
 6
 7
 8
 9
```
