# MergedArrays

[![Build Status](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/MurrellGroup/MergedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/MurrellGroup/MergedArrays.jl)

MergedArray exports the `merged` function: taking an `AbstractArray` of some structure, and makes a new array if it sees that the memory layout of the array and its elements can be improved in order to minimize references and reduce strain on the garbage collector.

The `merged` function takes an array of structures and merges the storage and references of nested fields:
- `AbstractArray` fields -> `MergedArrayOfArrays`
- `AbstractString` fields -> `MergedArrayOfStrings`
- other nested fields -> `Array`

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
