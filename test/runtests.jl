using MegTools
using Test

test_path = joinpath(@__DIR__, "testData", "test_data.mat")
test_data = load_cont_epochs(test_path)


@testset "IO_Meg.jl" begin
    # Write your own tests here.
    @test test_data isa Dict
    @test length(collect(keys(test_data))) == 4
    for condition in collect(keys(test_data))
        @test size(test_data[condition])==(1501, 319, 100)
    end
end

@testset "analysis_recipes.jl" begin
    # Testing single conditon, average_across_trials
    @test ndims(test_data["1"]) == 3
    averaged_trials = average_across_trials(test_data["1"])
    @test ndims(averaged_trials) == 2
    @test size(test_data["1"])[1:2] == size(averaged_trials)
    # Testing single condition, select_channels
    auditory_channels,left_labels,right_labels = select_channels(
        test_data["1"],
        paradigm="auditoryN1m",
    )
    @test size(auditory_channels)[2] ==  (length(left_labels) + length(right_labels))
    @test auditory_channels.channels == vcat(left_labels, right_labels)

end
