using MergedArrays
using Test

struct A
    a
    b
    c
    d
end

@testset "MergedArrays.jl" begin

    @testset "structs" begin

        Base.:(==)(a::A, b::A) = a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d

        arr = [A("ABC", [1,2,3], [0 0], 1), A("DEFG", [4,5,6,7], [1 1 1], 2)]
        marr = merged(arr)
        @test marr isa MergedArrays.MergedArray
        @test marr isa AbstractVector{A}
        @test marr[1] isa A
        @test marr[:] isa Vector{A}
        @test marr[:,:] isa Matrix{A}
        @test marr.a isa MergedArrays.MergedArrayOfStrings
        @test marr.b isa MergedArrays.MergedArrayOfArrays
        @test length(marr.a) == 2
        @test length(marr) == length(arr)
        @test all(marr .== arr)

        @test merged(permutedims(arr))[1,1] == marr[1]

        io = IOBuffer()
        Base.showarg(io, marr, true)
        @test String(take!(io)) == "merged(::Vector{A})"

        @test marr.a[1] isa String
        @test marr.a[:] isa Vector{String}
        @test marr.a[:,:] isa Matrix{String}

        @test marr.b[1] isa Vector{Int}
        @test marr.b[:] isa Vector{Vector{Int}}
        @test marr.b[:,:] isa Matrix{Vector{Int}}
    end

    @testset "NamedTuple" begin
        arr = [
            (a="ABC", b=[1,2,3], c=[0 0], d=1),
            (a="DEFG", b=[4,5,6,7], c=[1 1 1], d=2)
        ]
        marr = merged(arr)
        @test marr isa MergedArrays.MergedArray
        @test marr[1] isa eltype(marr)
        @test marr.a isa MergedArrays.MergedArrayOfStrings
        @test marr.b isa MergedArrays.MergedArrayOfArrays
        @test length(marr.a) == 2
        @test length(marr) == length(arr)
        @test all(marr .== arr)
    end

    @test_logs (:warn, "Failed to narrow element type to a concrete type.") merged(Any[1, 1.0]) isa Vector{Real}

end