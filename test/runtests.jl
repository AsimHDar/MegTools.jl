using MegTools
using Test


@testset "IO.jl" begin
    # Write your own tests here.
    a = load_cont_epochs("test/testData/test_data.mat")
    @test a isa Dict
    @test length(collect(keys(a))) == 4
    for condition in collect(keys(a))
        @test size(a[condition])==(1501, 319, 100)
    end
end
