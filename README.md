# MergedArrays

[![Build Status](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/MurrellGroup/MergedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/MurrellGroup/MergedArrays.jl)

MergedArray exports the `merged` function: taking an `AbstractArray` of some data structure, returning a `Merged <: AbstractArray` with a memory layout designed to minimize references, reducing strain on Julia's garbage collection system.

The `Merged` type merges the storage of fields with the following types:
- `AbstractArray`
- `AbstractString`

Other fields values are simply stored in `Array`s, akin to [https://github.com/JuliaArrays/StructArrays.jl](StructArrays.jl).

## Example

```julia
julia> struct Points{T}
           name::String
           vibe::Float32
           points::Matrix{T}
       end

julia> a = [Points("first", 1.0f0, [0; 1;; 1; 2;; 2; 3]), Points("last", 0.2f0, [3; 4;; 4; 5])]
2-element Vector{Points{Int64}}:
 Points{Int64}("first", 1.0f0, [0 1 2; 1 2 3])
 Points{Int64}("last", 0.2f0, [3 4; 4 5])

julia> m = merged(a)
2-element Merged{Points{Int64}, 1, @NamedTuple{name::MergedStrings{1, MergedArray{Vector{UInt8}, 1, Vector{UnitRange{Int64}}}}, vibe::Vector{Float32}, points::MergedArray{Matrix{Int64}, 1, Vector{UnitRange{Int64}}}}, UnionAll}:
 Points{Int64}("first", 1.0f0, [0 1 2; 1 2 3])
 Points{Int64}("last", 0.2f0, [3 4; 4 5])

julia> m[1]
Points{Int64}("first", 1.0f0, [0 1 2; 1 2 3])
```

> [!NOTE]
> `Merged` currently only tolerates axis differences in the last dimension, such that `allequal(points -> size(points)[1:end-1], p.points for p in a)` must hold true.

## Implementation details

```julia
julia> m.storage.name
2-element MergedStrings{1, MergedArray{Vector{UInt8}, 1, Vector{UnitRange{Int64}}}}:
 "first"
 "last"

julia> m.storage.name.ma.storage
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
2-element MergedArray{Matrix{Int64}, 1, Vector{UnitRange{Int64}}}:
 [0 1 2; 1 2 3]
 [3 4; 4 5]

julia> m.storage.points.storage
2×5 Matrix{Int64}:
 0  1  2  3  4
 1  2  3  4  5
```