using MergedArrays
using Test

@testset "MergedArrays.jl" begin

    @testset "structs" begin
        struct A
            a
            b
            c
        end

        Base.:(==)(a::A, b::A) = a.a == b.a && a.b == b.b && a.c == b.c

        arr = [A("ABC", [1,2,3], [0 0]), A("DEFG", [4,5,6,7], [1 1 1])]
        marr = merged(arr)
        @test marr isa Merged
        @test marr isa AbstractVector{A}
        @test marr[1] isa A
        @test all(marr .== arr)
    end

    @testset "NamedTuple" begin
        arr = [
            (a="ABC", b=[1,2,3], c=[0 0]),
            (a="DEFG", b=[4,5,6,7], c=[1 1 1])
        ]
        marr = merged(arr)
        @test marr isa Merged
        @test marr isa AbstractVector{eltype(arr)}
        @test marr[1] isa eltype(marr)
        @test all(marr .== arr)
    end

end