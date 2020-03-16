using Statistics



"""
    average_across_trials(all_epochs)

Returns the averaged signal across trials of a single condition (e.g. Sub09["1"]).
"""
function average_across_trials(all_epochs)

    epoch_average = mean(all_epochs, dims=3)
    epoch_average = dropdims(epoch_average, dims=3)

    return epoch_average

end

"""
    select_channels(data, paradigm)

Select specific channels of interest to be processed for analysis. It selects
channel names based on the available paradigms and returns data from channels, as well as
the labels of the channels. The default paradigm is set to auditoryN1m.

Returns in the following format: selected_data, left_hem_channels, right_hem_channels
"""
function select_channels(data; paradigm::String="auditoryN1m")
# This paradigm selects channels based on the ones that appear most active during auditory
# stimuli of repeating nature
    if paradigm == "auditoryN1m"
    # TODO: aesthetics: open form
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
    baseline_correction(data; baseline_range=(-200,0))

Baseline correct data (single channel or multiple channels) based on the specified range
(default is -200 < t < 0)

Returns baseline corrected data (single channel or multiple channels)
"""
function baseline_correction(data; baseline_range=(-200, 0))

    baseline_latency_range = t-> baseline_range[1] < t < baseline_range[2]
    baseline = mean(data(time = baseline_latency_range), dims=1)
    filt_baseline_corrected_data = data .- baseline

    return filt_baseline_corrected_data

end

"""

    find_peaks(data, left_hem_channels, right_hem_channels, peak_range=(50,150))

Finds the channels containing peak values (for left and right hemisphere data sets). Channels
of interest are passed into left_hem_channels and right_hem_channels as Symbols. The
latency window for evaluating the peak values can be set with peak_range (default is set
to 50 < t <150)

Returns the left and right peak erfs and their respective channel labels in the following
format: left_peak_erf right_peak_erf, peak_channel_left, peak_channel_right
"""
function find_peaks(data, left_hem_channels, right_hem_channels, peak_range=(50,150))

    N1m_latency_range = t -> peak_range[1] < t < peak_range[2]
    # Left ERF
    # Find index of peak value
    left_channels = data(channels = left_hem_channels, time = N1m_latency_range)
    _,left_peak = findmax(left_channels)
    # Determine channel name from index and use it to extract relevent channel data
    peak_channel_left= left_channels.channels[left_peak[2]]
    left_peak_erf = data(channels = peak_channel_left)

    # Right ERF
    right_channels = data(channels = right_hem_channels, time = N1m_latency_range)
    # Right side activity is negative, and so minimum is the "peak" value
    _,right_peak = findmin(right_channels)
    peak_channel_right= right_channels.channels[left_peak[2]]
    # Polarity is fliped to view in the positive of the y-axis
    right_peak_erf = -data(channels = peak_channel_right)

    return left_peak_erf, right_peak_erf, peak_channel_left, peak_channel_right

end
