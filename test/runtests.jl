using MergedArrays
using Test

@testset "MergedArrays.jl" begin

    @testset "structs" begin
        struct A
            a
            b
            c
            d
        end

        Base.:(==)(a::A, b::A) = a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d

        arr = [A("ABC", [1,2,3], [0 0], 1), A("DEFG", [4,5,6,7], [1 1 1], 2)]
        marr = merged(arr)
        @test marr isa Merged
        @test marr isa AbstractVector{A}
        @test marr[1] isa A
        @test marr.storage.a isa MergedArrays.MergedStrings
        @test marr.storage.b isa MergedArrays.MergedArray
        @test length(marr.storage.a) == 2
        @test length(marr) == length(arr)
        @test all(marr .== arr)

        @test merged(permutedims(arr))[1,1] == marr[1]
    end

    @testset "NamedTuple" begin
        arr = [
            (a="ABC", b=[1,2,3], c=[0 0], d=1),
            (a="DEFG", b=[4,5,6,7], c=[1 1 1], d=2)
        ]
        marr = merged(arr)
        @test marr isa Merged
        @test marr isa AbstractVector{eltype(arr)}
        @test marr[1] isa eltype(marr)
        @test marr.storage.a isa MergedArrays.MergedStrings
        @test marr.storage.b isa MergedArrays.MergedArray
        @test length(marr.storage.a) == 2
        @test length(marr) == length(arr)
        @test all(marr .== arr)
    end

end