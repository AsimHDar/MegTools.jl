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
    # Same with averaged trial, which is of a single condition
    auditory_channels,left_labels,right_labels = select_channels(
        averaged_trials,
        paradigm="auditoryN1m",
    )
    @test size(auditory_channels)[2] ==  (length(left_labels) + length(right_labels))
    @test auditory_channels.channels == vcat(left_labels, right_labels)
    # Testing baseline_correction
    filtered = highlow_butterworth_filter(auditory_channels, 1000)
    baseline_corrected = baseline_correction(filtered)
    @test filtered ≠ baseline_corrected
    @test sum(baseline_corrected) < sum(filtered)
    # Determine if robust with different number of total trials
    not_filtered =  test_data["1"]
    baseline_corrected = baseline_correction(not_filtered)
    not_filtered_1 =  test_data["1"][:,:,1]
    baseline_corrected_1 = baseline_correction(not_filtered_1)
    @test baseline_corrected[:,:,1] == baseline_corrected_1
    # Testing find find_peaks
    a,b,c,d = find_peaks(averaged_trials, left_labels, right_labels)
    @test ndims(a) == 1
    @test length(a) == length(averaged_trials[:,1])
    @test ndims(b) == 1
    @test length(b) == length(averaged_trials[:,1])
    # Testing will all averaged_trials
    a,b,c,d = find_peaks(
        highlow_butterworth_filter(test_data["1"], 1000),
        left_labels,
        right_labels
    )
    

end

@testset "filters.jl" begin
    # Testing single condition, highlow_butterworth_filter
    averaged_trials = average_across_trials(test_data["1"])
    auditory_channels,left_labels,right_labels = select_channels(
        averaged_trials,
        paradigm="auditoryN1m",
    )
    filtered = highlow_butterworth_filter(auditory_channels, 1000)
    @test filtered ≠ auditory_channels
    @test size(filtered) == size(auditory_channels)
    @test filtered.channels == vcat(left_labels, right_labels)

end
