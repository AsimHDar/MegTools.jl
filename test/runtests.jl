using MegTools
using AxisKeys
using Test


# BESA epoch data
test_path = joinpath(@__DIR__, "testData", "test_data.mat")
test_data = load_cont_epochs(test_path)

# BESA averaged data
BESA_av = joinpath(@__DIR__, "testData", "besa_av_singlecondition.mat")
BESA_av_data = load_besa_av(BESA_av)
# Brainstorm epoch data_path
BStest_path = joinpath(@__DIR__, "testData", "sub_001")
BStest_data = load_BSepochs(BStest_path)


@testset "IO_Meg.jl" begin
    # Testing BESA output
    @test test_data isa Dict
    @test length(collect(keys(test_data))) == 4
    for condition in collect(keys(test_data))
        @test size(test_data[condition])==(1501, 319, 100)  # Time, Channels, Trials
    end
    # Loading average
    @test BESA_av_data isa KeyedArray

    # Testing Brainstorm outputs
    @test BStest_data isa Dict
    @test length(collect(keys(BStest_data))) == 2 # There are only 2 conditions
    for condition in collect(keys(BStest_data))
        # In condition "7" one trial is rejected (005- as labelled in brainstormstudy.mat)
        @test size(BStest_data[condition])==(1501, 351, 2)  # Time, Channels, Trials
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
    # Selecting custom channels
    custom_channels, custom_left, custom_right = select_channels(
        test_data["1"],
        paradigm="custom_channels",
        left_channels=["MEG0241", "MEG0231"],
        right_channels="MEG2641"
    )
    @test length(custom_channels.channels) == 3
    @test length([custom_left;custom_right]) == 3
        # Selecting custom channels 
        custom_channels, custom_left, custom_right = select_channels(
            test_data["1"],
            paradigm="custom_channels",
            left_channels=["MEG0241", "MEG0231"],
            right_channels="MEG2641"
        )
        @test length(custom_channels.channels) == 3
        @test length([custom_left;custom_right]) == 3
    # Select from subject (Dict)
    auditory_channels,left_labels,right_labels = select_channels(
        test_data,
        paradigm="auditoryN1m",
    )
     # Select INCORRECT paradigm from subject (Dict)
    @test_throws MethodError auditory_channels,left_labels,right_labels = select_channels(
        test_data,
        paradigm="HamSandwich",
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
    # Getting the baseline value (using averaged data (all trials))
    baseline_corrected, indv_baseline = baseline_correction(averaged_trials, output_baseline = true)
    @test length(indv_baseline) == length(averaged_trials.channels)
    # Now checking a dict of subjects
    baseline_corrected, indv_baseline = baseline_correction(test_data, output_baseline = true)
    @test size(indv_baseline["1"]) == (1,319,100) # (time, channels, trials)
    # Determine if robust with different number of total trials
    not_filtered =  test_data["1"]
    baseline_corrected = baseline_correction(not_filtered)
    not_filtered_1 =  test_data["1"][:,:,1]
    baseline_corrected_1 = baseline_correction(not_filtered_1)
    @test baseline_corrected[:,:,1] == baseline_corrected_1
    # Testing with input baseline_condiitons (averaging approach as in Zacharias 2011)
    baseline_candidates= ["4","1"]
    averaged_baseline = get_averaged_baseline(test_data, baseline_candidates)
    @test size(averaged_baseline)[1] == 1
    @test size(averaged_baseline)[3] == 1 
    @test size(averaged_baseline)[2] == length(test_data["1"].channels)
    # Carrying out the baseline correction using the averaging method 
    # Checking that the baselines are different
    av_baseline_corrected = baseline_correction(test_data, averaged_baseline)
    per_erf_baseline = baseline_correction(test_data)
    @test av_baseline_corrected ≠ per_erf_baseline
    # However, they are should be the same shape
    @test length(av_baseline_corrected) == length(per_erf_baseline)
    @test size(av_baseline_corrected["1"]) == size(per_erf_baseline["1"])
    # Testing find find_peaks
    a,_,_,b,_,_,c,d = find_peaks(averaged_trials, left_labels, right_labels)
    @test ndims(a) == 1
    @test length(a) == length(averaged_trials[:,1])
    @test ndims(b) == 1
    @test length(b) == length(averaged_trials[:,1])
    # Testing custom channel with find peaks
    
    custom_channels2, custom_left2, custom_right2 = select_channels(
        averaged_trials,
        paradigm="custom_channels",
        left_channels=["MEG0241", ],
        right_channels=["MEG2641", ]
    )
    a,_,_,b,_,_,c,d = find_peaks(custom_channels2, custom_left2, custom_right2)
    @test ndims(a) == 1
    @test length(a) == length(averaged_trials[:,1])
    @test ndims(b) == 1
    @test length(b) == length(averaged_trials[:,1])
 # Testing with singular non-array input
    custom_channels3, custom_left3, custom_right3 = select_channels(
        averaged_trials,
        paradigm="custom_channels",
        left_channels="MEG0241",
        right_channels="MEG2641"
    )
    a,_,_,b,_,_,c,d = find_peaks(custom_channels3, custom_left3, custom_right3)
    @test ndims(a) == 1
    @test length(a) == length(averaged_trials[:,1])
    @test ndims(b) == 1
    @test length(b) == length(averaged_trials[:,1])

    # Testing find_peaks with incorrect dimentions
    @test_throws MethodError a,_,_,b,_,_,c,d = find_peaks(test_data, left_labels, right_labels)
    test_dict = Dict("fake_array"=>rand(10,10,1,10))
    @test_throws MethodError a,_,_,b,_,_,c,d = find_peaks(test_dict, left_labels, right_labels)
    # Testing mean amplitude of the m100 peaks
    _,l,_,r,_,_ = find_mean_amplitude(averaged_trials, left_labels, right_labels)
    @test length(l) == 1
    @test length(r) == 1
    #@test_throws MethodError find_mean_amplitude(test_data["1"], left_labels, right_labels)
    @test_logs (:error, "Dimentions more than 2, average this data first.")  find_mean_amplitude(test_data["1"], left_labels, right_labels)
    @test_throws MethodError find_mean_amplitude(test_dict, left_labels, right_labels)
    # Testing subject data will all conditions
    averaged_trials_all = average_across_trials(test_data)
    peak_means = find_mean_amplitude(averaged_trials_all, left_labels, right_labels)
    @test peak_means["1"]["left_mean_amplitude"] == l
    @test peak_means["1"]["right_mean_amplitude"] == r
    # Testing collection of mean amplitudes
    soi, left, right = collect_mean_amps(peak_means)
    @test length(soi) == length(left) == length(right)
    @test soi == sort(soi)
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
    filtered_nooffset = highlow_butterworth_filter(auditory_channels, 1000, offset=false)
    @test filtered ≠ auditory_channels
    @test filtered ≠ filtered_nooffset
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
    filtered_nooffset = highlow_butterworth_filter(auditory_channels, 1000, offset=false)
    for (cond, data) in filtered
        @test filtered_nooffset[cond]  ≠ filtered[cond] && size(filtered_nooffset[cond]) == size(filtered[cond])
        @test filtered_nooffset[cond].channels == vcat(left_labels, right_labels)
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
    triggers = load_trigger_values("soistream")
    @test triggers isa Dict
    @test length(triggers) == 10
end
