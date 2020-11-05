using Statistics



"""
    average_across_trials(all_epochs)

Returns the averaged signal across trials of a single condition (e.g. `Sub09["1"]` ).
"""
function average_across_trials(all_epochs)

    epoch_average = mean(all_epochs, dims=3)
    epoch_average = dropdims(epoch_average, dims=3)

    return epoch_average

end

"""
    average_across_trials(all_epochs::Dict)

Returns the averaged signal across trials of a subject (Dict with multiple conditions)).
"""
function average_across_trials(all_epochs::Dict)

    averages = Dict()
    for (condition, cond_data) in all_epochs
        averages[condition] = average_across_trials(cond_data)
    end

    return averages

end

"""
    select_channels(data; paradigm)

Select specific channels of interest to be processed for analysis. It selects
channel names based on the available paradigms and returns data from channels, as well as
the labels of the channels. The default paradigm is set to auditoryN1m. For manual selection
use the paradigm `select_channels` and input the channels as positional arguments as
arrays of strings.

Returns in the following format: `selected_data, left_hem_channels, right_hem_channels`
"""
function select_channels(data; paradigm::String="auditoryN1m", left_channels=[], right_channels=[])
# This paradigm selects channels based on the ones that appear most active during auditory
# stimuli of repeating nature
    if paradigm== "custom_channels"
        
        right_hem_ch = right_channels
        left_hem_ch  = left_channels

    elseif paradigm == "auditoryN1m"
        right_hem_ch = [
            "MEG1131",
            "MEG1341",
            "MEG1331",
            "MEG2611",
            "MEG2221",
            "MEG2411",
            "MEG2421",
            "MEG2641",
            "MEG2231",
            "MEG2441",
            "MEG2431",
            "MEG2321",
            "MEG2521",
        ]
        left_hem_ch  = [
            "MEG0241",
            "MEG0231",
            "MEG0441",
            "MEG1611",
            "MEG1621",
            "MEG1811",
            "MEG1521",
            "MEG1641",
            "MEG1631",
            "MEG1841",
            "MEG1941",
            "MEG1721",
            "MEG1911",
        ]

    else
        @error "Paradigm not found, add channels of interest as an array of symbols"
        return
    end

    right_hem_channels = Symbol.(right_hem_ch)
    left_hem_channels  = Symbol.(left_hem_ch)
    selected_data = data(channels= vcat(left_hem_channels, right_hem_channels))

    return selected_data, left_hem_channels, right_hem_channels

end

"""
    select_channels(data::Dict; paradigm)

Data contains all conditions and is a Dict (subject). Select specific channels of interest to be processed for analysis. It selects
channel names based on the available paradigms and returns data from channels, as well as
the labels of the channels. The default paradigm is set to auditoryN1m.

Returns in the following format: `selected_data, left_hem_channels, right_hem_channels`
"""
function select_channels(data::Dict; paradigm::String="auditoryN1m", left_channels=[], right_channels=[])

    select_ch = Dict()
    local left_hem_channels
    local right_hem_channels
    for (condition, cond_data) in data
        select_ch[condition], left_hem_channels, right_hem_channels = select_channels(
            cond_data,
            paradigm=paradigm,
            left_channels=left_channels,
            right_channels=right_channels,
        )
    end

    return select_ch, left_hem_channels, right_hem_channels
end

"""
    baseline_correction(data; baseline_range=(-200,0))

Baseline correct data (single subject—single channel or multiple channels) based on the 
specified range (default is -200 ≤ t ≤ 0)

Returns baseline corrected data (single channel or multiple channels) and if `output_baseline`
is set to `true` then it also returns the individual baseline
"""
function baseline_correction(data; baseline_range=(-200, 0), output_baseline=false)

    baseline_latency_range = t-> baseline_range[1] ≤ t ≤ baseline_range[2]
    individual_baseline = mean(data(time = baseline_latency_range), dims=1)
    baseline_corrected_data = data .- individual_baseline

    if output_baseline == true
        return baseline_corrected_data, individual_baseline
    else
        return baseline_corrected_data 
        
    end

end
"""
    baseline_correction(data::Dict; baseline_range=(-200,0))

Baseline correct data (single subject with one or more conditions) based on the input baseline 
values for each channel. This is usually an averaged computed baseline from many
conditions. For example, by using the `get_averaged_baseline` function

Returns baseline corrected data (single channel or multiple channels)
"""
function baseline_correction(data::Dict, multichannel_baseline)

    # Making a container for the baseline corrected data and then filling it up
    baseline_corrected_data = Dict()
    # This time we go through all the conditions
     for (condition, cond_data) in data
        baseline_corrected_data[condition] = (
            cond_data .-  
            multichannel_baseline(channels=cond_data.channels)
        )
        
        # Not sure why this line was entered
        #baseline_corrected_data[condition] = dropdims(baseline_corrected_data[condition],dims=3)
    end
    
    return baseline_corrected_data


end

"""
    baseline_correction(data::Dict; baseline_range=(-200,0))

Data contains all conditions and is a Dict (subject). Baseline correct data (single channel or multiple channels) based on the specified range
(default is -200 ≤ t ≤ 0)

Returns baseline corrected data (single channel or multiple channels) of all conditions and
if `output_baseline` is set to `true` then it also returns the individual baselines
"""
function baseline_correction(data::Dict; baseline_range=(-200, 0), output_baseline=false)

    baseline_corrected_data = Dict()
    individual_baseline = Dict()


    if output_baseline == true
        for (condition, cond_data) in data
            baseline_corrected_data[condition], individual_baseline[condition] = baseline_correction(
                cond_data,
                baseline_range=baseline_range,
            )
        end

        return baseline_corrected_data, individual_baseline
    else
        for (condition, cond_data) in data
            baseline_corrected_data[condition] = baseline_correction(
                cond_data,
                baseline_range=baseline_range,
            )
        end

        return baseline_corrected_data 
    end

end

"""
    baseline_correction(data::Dict; baseline_range=(-200,0))

Baseline correction based on data from specified conditions.Data contains all conditions 
and is a Dict (subject). Baseline correct data (single channel or multiple channels) based 
on the specified range (default is -200 ≤ t ≤ 0)

Returns 
"""
function get_averaged_baseline(data::Dict, baseline_conditions; baseline_range=(-200, 0))
    
    ## Determine the baseline correction amount from the conditions stated
    # Determine total trials that we need to consider
    total_trials = sum([size(data[condition])[3] for condition in baseline_conditions])
    # Collect all the trials of the select sois and concatenate them
    all_trials = [data[cond] for cond in baseline_conditions]
    all_trials = reduce((a,b)->cat(a,b, dims=3), all_trials)

    # Determining the baseline value (of each channel) from all the trials
    baseline_latency_range = t-> baseline_range[1] ≤ t ≤ baseline_range[2]
    averaged_trials = mean(all_trials(time = baseline_latency_range), dims=3)
    baseline = mean(averaged_trials, dims=1)
    return baseline

end

"""

    collect_mean_amps(peaks::Dict, cond_trigger_vals=load_trigger_values("regsoi"))

Collects the mean amplitudes of the left and right ERF of all conditions present
in the subject (Dict) input. It also converts soi triggers to values of the sois; as assigned
by the `load_trigger_values(experimental_paradigm)` function. By default it loads the `regsoi`
trigger values.

Returns in the following format: `soi, left_mean_amps, right_mean_amps`
"""
function collect_mean_amps(peaks::Dict; cond_trigger_vals=load_trigger_values("regsoi"))
    soi, left_mean_amps, right_mean_amps = Float64[], Float64[], Float64[]
    for (condition,value) in peaks
        push!(soi, cond_trigger_vals[condition])
        push!(left_mean_amps, value["left_mean_amplitude"])
        push!(right_mean_amps, value["right_mean_amplitude"])

    end

    # Sorting the output so that a line can be made from the plots
    soi_idx = sortperm(soi)
    soi = soi[soi_idx]
    left_mean_amps  = left_mean_amps[soi_idx]
    right_mean_amps = right_mean_amps[soi_idx]

    return soi, left_mean_amps, right_mean_amps
end

"""

    find_mean_amplitude(data::Dict, left_hem_channels, right_hem_channels, mean_range=(50,150))

Data contains all conditions and is a Dict (subject). Finds the channels containing peak values (for left and right hemisphere data sets) in
(ideally averaged) data. Channels of interest are passed into left_hem_channels and right_hem_channels
as Symbols. The latency window for evaluating the peak values can be set with mean_range
(default is set to 50 ≤ t ≤150)

Returns the left and right peak erfs and their respective channel labels as a Dict
with the following entires: `["left_peak_erf"],["left_peak_value"], ["left_peak_latency"],  ["right_peak_erf"],
["right_peak_value"], ["left_channel_label"], ["right_peak_latency"], ["right_channel_label"] `

"""
function find_mean_amplitude(data::Dict, left_hem_channels, right_hem_channels; mean_range=(50,150))

    peaks = Dict()
    for (condition, cond_data) in data
        left_peak_erf, 
        left_mean_amplitude, 
        right_peak_erf, 
        right_mean_amplitude, 
        peak_channel_left, 
        peak_channel_right = find_mean_amplitude(
            cond_data,
            left_hem_channels,
            right_hem_channels,
            mean_range=mean_range,
        )
        peaks[condition] = Dict()
        peaks[condition]["left_peak_erf"]  = left_peak_erf
        peaks[condition]["left_mean_amplitude"]  = left_mean_amplitude
        peaks[condition]["right_peak_erf"] = right_peak_erf
        peaks[condition]["right_mean_amplitude"]  = right_mean_amplitude
        peaks[condition]["left_channel_label"]  = peak_channel_left
        peaks[condition]["right_channel_label"] = peak_channel_right
    end

    return peaks

end

"""

    find_mean_amplitude(data, left_hem_channels, right_hem_channels, mean_range=(50,150))

Finds the channels containing peak values (for left and right hemisphere data sets) in
(ideally averaged) data. Channels of interest are passed into left_hem_channels and right_hem_channels
as Symbols. The latency window for evaluating the peak values can be set with mean_range
(default is set to 50 ≤ t ≤150)

Returns the left and right mean amplitudes, peak erfs and their respective channel labels  
in the following format: 
`left_peak_erf, left_peak_value, left_peak_latency, right_peak_erf, right_peak_value, 
    right_peak_latency, peak_channel_left, peak_channel_right`
"""
function find_mean_amplitude(data, left_hem_channels, right_hem_channels; mean_range=(50,150))
    # Making sure input dimentions are limited to 2 (channels and time)
    if ndims(data) > 2
        if size(data)[3] > 1
            @error "Dimentions more than 2, average this data first."
            return
        elseif ndims(data) > 3
            @error "Dimentions more than 3."
            return
        end
    end

    
    N1m_latency_range = t -> mean_range[1] ≤ t ≤ mean_range[2]
    # Left ERF
    # Find index of peak value
    left_channels = data(channels = left_hem_channels, time = N1m_latency_range)
    _,left_peak_idx = findmax(left_channels)
    # Determine channel name from index and use it to extract relevent channel data
    peak_channel_left= left_channels.channels[left_peak_idx[2]]
    left_peak_erf = data(channels = peak_channel_left)
    left_mean_amplitude = mean(data(channels = peak_channel_left, time=N1m_latency_range))

    # Right ERF
    right_channels = data(channels = right_hem_channels, time = N1m_latency_range)
    # Right side activity is negative, and so minimum is the "peak" value
    right_peak_value,right_peak_idx = findmin(right_channels)
    # Reversing polarity on right channel value
    peak_channel_right= right_channels.channels[right_peak_idx[2]]
    # Polarity is flipped to view in the positive of the y-axis
    right_peak_erf = -data(channels = peak_channel_right)
    right_mean_amplitude = -mean(data(channels = peak_channel_right, time=N1m_latency_range))
    

    return left_peak_erf, left_mean_amplitude, right_peak_erf, right_mean_amplitude, peak_channel_left, peak_channel_right

end

"""

    collect_peaks(peaks::Dict, cond_trigger_vals=load_trigger_values("regsoi"))

Collects the peaks (the maximum value and their latencies) of the left and right ERF of all conditions present
in the subject (Dict) input. It also converts soi triggers to values of the sois; as assigned
by the `load_trigger_values(experimental_paradigm)` function. By default it loads the `regsoi`
trigger values.

Returns in the following format: `soi, left_amps, left_lats, right_amps, right_lats`
"""
function collect_peaks(peaks::Dict; cond_trigger_vals=load_trigger_values("regsoi"))
    soi, left_amps, right_amps, left_lats, right_lats = 
        Float64[], Float64[], Float64[], Float64[], Float64[]
    for (condition,value) in peaks
        push!(soi, cond_trigger_vals[condition])
        push!(left_amps, value["left_peak_value"])
        push!(right_amps, value["right_peak_value"])
        push!(left_lats, value["left_peak_latency"])
        push!(right_lats, value["right_peak_latency"])

    end

    # Sorting the output so that a line can be made from the plots
    soi_idx = sortperm(soi)
    soi = soi[soi_idx]
    left_amps  = left_amps[soi_idx]
    right_amps = right_amps[soi_idx]
    left_lats  = left_lats[soi_idx]
    right_lats = right_lats[soi_idx]

    return soi, left_amps, left_lats, right_amps, right_lats
end

"""

    find_peaks(data::Dict, left_hem_channels, right_hem_channels, peak_range=(50,150))

Data contains all conditions and is a Dict (subject). Finds the channels containing peak values (for left and right hemisphere data sets) in
(ideally averaged) data. Channels of interest are passed into left_hem_channels and right_hem_channels
as Symbols. The latency window for evaluating the peak values can be set with peak_range
(default is set to 50 ≤ t ≤150)

Returns the left and right peak erfs and their respective channel labels as a Dict
with the following entires: `["left_peak_erf"],["left_peak_value"], ["left_peak_latency"],  ["right_peak_erf"],
["right_peak_value"], ["left_channel_label"], ["right_peak_latency"], ["right_channel_label"] `

"""
function find_peaks(data::Dict, left_hem_channels, right_hem_channels; peak_range=(50,150))

    peaks = Dict()
    for (condition, cond_data) in data
        left_peak_erf,
        left_peak_value,
        left_peak_latency,
        right_peak_erf,
        right_peak_value,
        right_peak_latency,
        peak_channel_left,
        peak_channel_right = find_peaks(
            cond_data,
            left_hem_channels,
            right_hem_channels,
            peak_range,
        )
        peaks[condition] = Dict()
        peaks[condition]["left_peak_erf"]  = left_peak_erf
        peaks[condition]["left_peak_value"]  = left_peak_value
        peaks[condition]["left_peak_latency"]  = left_peak_latency
        peaks[condition]["right_peak_erf"] = right_peak_erf
        peaks[condition]["right_peak_value"]  = right_peak_value
        peaks[condition]["right_peak_latency"]  = right_peak_latency
        peaks[condition]["left_channel_label"]  = peak_channel_left
        peaks[condition]["right_channel_label"] = peak_channel_right
        @info " For soi $condition left channel is $peak_channel_left and right is $peak_channel_right"
    end

    return peaks

end

"""

    find_peaks(data, left_hem_channels, right_hem_channels, peak_range=(50,150))

Finds the channels containing peak values (for left and right hemisphere data sets) in
(ideally averaged) data. Channels of interest are passed into left_hem_channels and right_hem_channels
as Symbols. The latency window for evaluating the peak values can be set with peak_range
(default is set to 50 ≤ t ≤150)

Returns the left and right peak erfs and their respective channel labels in the following
format: `left_peak_erf, left_peak_value, left_peak_latency, right_peak_erf, right_peak_value, 
            right_peak_latency, peak_channel_left, peak_channel_right`
"""
function find_peaks(data, left_hem_channels, right_hem_channels, peak_range=(50,150))
    # Making sure input dimentions are limited to 2 (channels and time)
    if ndims(data) > 2
        # checking if there are multiple trials in the input data
        if size(data)[3] > 1
            @error "Multiple trials found, average this data first."
            return
        elseif ndims(data) > 3
            @error "Dimentions more than 3. Unsure of the input data format"
            return
        end
    end


    N1m_latency_range = t -> peak_range[1] ≤ t ≤ peak_range[2]
    # Left ERF
    # Find index of peak value
    left_channels = data(channels = left_hem_channels, time = N1m_latency_range)
    left_peak_value,left_peak_idx = findmax(left_channels)
    # Determine channel name from index and use it to extract relevent channel data
    # The three states below are based on the input of the channel names if they
    # are 1. Array of channels, 2. A symbol 3. An array with a single Symbol
    
    if left_hem_channels isa Array && length(left_hem_channels) > 1
        peak_channel_left= left_channels.channels[left_peak_idx[2]]
        left_peak_erf = data(channels = peak_channel_left)
        left_peak_latency = left_channels.time[left_peak_idx[1]]
    elseif left_hem_channels isa Symbol
        peak_channel_left = left_hem_channels
        left_peak_erf =  data(channels = left_hem_channels)
        left_peak_latency = left_channels.time[left_peak_idx]
    elseif left_hem_channels isa Array
        peak_channel_left = left_hem_channels[1]
        left_peak_erf =  data(channels = left_hem_channels)
        left_peak_latency = left_channels.time[left_peak_idx]
    end
    
    # Right ERF
    right_channels = data(channels = right_hem_channels, time = N1m_latency_range)
    # Right side activity is negative, and so minimum is the "peak" value
    right_peak_value,right_peak_idx = findmin(right_channels)
    # Reversing polarity on right channel value
    right_peak_value = abs(right_peak_value)
    
    if right_hem_channels isa Array && length(right_hem_channels) > 1
        peak_channel_right= right_channels.channels[right_peak_idx[2]]
        # Polarity is flipped to view in the positive of the y-axis
        right_peak_erf = -data(channels = peak_channel_right)
        right_peak_latency = right_channels.time[right_peak_idx[1]]
    elseif right_hem_channels isa Symbol
        peak_channel_right= right_hem_channels
        # Polarity is flipped to view in the positive of the y-axis
        right_peak_erf = -data(channels = right_hem_channels)
        right_peak_latency = right_channels.time[right_peak_idx]
    elseif right_hem_channels isa Array
        peak_channel_right= right_hem_channels[1]
        # Polarity is flipped to view in the positive of the y-axis
        right_peak_erf = -data(channels = right_hem_channels)
        right_peak_latency = right_channels.time[right_peak_idx]
    end
    
    return left_peak_erf, left_peak_value, left_peak_latency, right_peak_erf, right_peak_value, right_peak_latency, peak_channel_left, peak_channel_right

end

