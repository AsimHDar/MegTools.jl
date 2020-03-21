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
    # Subject (Dict) test
    subject_av = average_across_trials(test_data)
    @test  subject_av isa Dict
    @test ndims(subject_av["1"]) == 2
    @test size(test_data["1"])[1:2] == size(subject_av["1"])

    # Testing single condition, select_channels
    auditory_channels,left_labels,right_labels = select_channels(
        test_data["1"],
        paradigm="auditoryN1m",
    )
    @test size(auditory_channels)[2] ==  (length(left_labels) + length(right_labels))
    @test auditory_channels.channels == vcat(left_labels, right_labels)
    # Select from subject (Dict)
    auditory_channels,left_labels,right_labels = select_channels(
        test_data,
        paradigm="auditoryN1m",
    )
    @test size(auditory_channels["1"])[2] ==  (length(left_labels) + length(right_labels))
    @test auditory_channels["1"].channels == vcat(left_labels, right_labels)
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
    # Single subject (Dict)
    baseline_corrected = baseline_correction(test_data)
    @test test_data["1"] ≠ baseline_corrected["1"]
    @test sum(baseline_corrected["1"]) < sum(test_data["1"])
    # Determine if robust with different number of total trials
    not_filtered =  test_data["1"]
    baseline_corrected = baseline_correction(not_filtered)
    not_filtered_1 =  test_data["1"][:,:,1]
    baseline_corrected_1 = baseline_correction(not_filtered_1)
    @test baseline_corrected[:,:,1] == baseline_corrected_1
    # Testing find find_peaks
    a,_,b,_,c,d = find_peaks(averaged_trials, left_labels, right_labels)
    @test ndims(a) == 1
    @test length(a) == length(averaged_trials[:,1])
    @test ndims(b) == 1
    @test length(b) == length(averaged_trials[:,1])
    # Single subject (Dict)
    subpeaks = find_peaks(subject_av, left_labels, right_labels)
    @test ndims(subpeaks["1"]["left_peak_erf"]) == 1
    @test length(subpeaks["1"]["left_peak_erf"]) == length(subject_av["1"][:,1])
    @test ndims(subpeaks["1"]["right_peak_erf"]) == 1
    @test length(subpeaks["1"]["right_peak_erf"]) == length(subject_av["1"][:,1])
    sois, left, right = collect_peaks(subpeaks)
    @test length(sois) ==  length(left) ==  length(right)
    @test typeof(sois[1]) == Float64



    # Testing will all averaged_trials
    #=TODO? a,b,c,d = find_peaks(
        highlow_butterworth_filter(test_data["1"], 1000),
        left_labels,
        right_labels
    )
    =#

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
    # Subject (Dict)
    subject_av = average_across_trials(test_data)
    auditory_channels,left_labels,right_labels = select_channels(
        subject_av,
        paradigm="auditoryN1m",
    )
    filtered = highlow_butterworth_filter(auditory_channels, 1000)
    for (cond, data) in filtered
        @test filtered[cond]  ≠ auditory_channels[cond] && size(filtered[cond]) == size(auditory_channels[cond])
        @test filtered[cond].channels == vcat(left_labels, right_labels)
    end

end


@testset "trigger_keys.jl" begin
    triggers = load_trigger_values("regsoi")
    @test triggers isa Dict
    @test length(triggers) == 20
    try
        load_trigger_values("MyUnknownProject")
    catch
        @test 1==1 #statating that an error is occuring
    end
end
