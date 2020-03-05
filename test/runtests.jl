using MegTools
using Test


@testset "IO_Meg.jl" begin
    # Write your own tests here.
    test_data = joinpath(@__DIR__, "testData", "test_data.mat")
    a = load_cont_epochs(test_data)
    @test a isa Dict
    @test length(collect(keys(a))) == 4
    for condition in collect(keys(a))
        @test size(a[condition])==(1501, 319, 100)
    end
end
