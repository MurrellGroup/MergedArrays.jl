# MergedArrays

[![Build Status](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/MurrellGroup/MergedArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/MurrellGroup/MergedArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/MurrellGroup/MergedArrays.jl)

MergedArray exports the `merged` function: taking an `AbstractArray` of some structure, and makes a new array if it sees that the memory layout of the array and its elements can be improved in order to minimize references, which may improve performance of serialization operations or reduce strain on the garbage collector (especially full collections).

The `merged` function takes an array of structures and merges the storage and references of nested fields:
- `AbstractArray` fields -> `MergedArrayOfArrays`
- `AbstractString` fields -> `MergedArrayOfStrings`
- other nested fields -> `Array`

## Examples

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
2-element merged(::Vector{Points{Int64}}):
 Points{Int64}("first", 1.0f0, [0 2 4; 1 3 5])
 Points{Int64}("last", 0.2f0, [6 8; 7 9])

julia> m[1]
Points{Int64}("first", 1.0f0, [0 2 4; 1 3 5])

julia> m.name # special lazy nested field access
2-element merged(::Vector{String}):
 "first"
 "last"
```

> [!NOTE]
> Accessing elements of `AbstractMergedArray`s does *not* return views, i.e. new arrays get allocated. For lazy access of subarrays, it is best to use `view(array, I...)`.

## Motivation

The duration of "full" garbage collections can be significantly reduced by using `merged` arrays. For example:

```julia
julia> strings = ["" for i in 1:1_000_000_000]; # one billion references (strings)

julia> @time GC.gc()
  0.636332 seconds (100.00% gc time)

julia> @time GC.gc()
  0.498087 seconds (100.00% gc time)

julia> strings = merged(strings)
1000000000-element merged(::Vector{String}):
 ""
 ""
 # output truncated

julia> @time GC.gc() # original Vector gets collected
  0.240929 seconds (99.99% gc time)

julia> @time GC.gc()
  0.019803 seconds (99.86% gc time)

julia> strings = nothing

julia> @time GC.gc()
  0.101071 seconds (99.97% gc time)

julia> @time GC.gc()
  0.018891 seconds (99.83% gc time)
```
