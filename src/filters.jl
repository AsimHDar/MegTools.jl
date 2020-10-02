using DSP

"""
    highlow_butterworth_filter(data,sampling_rate; low_pass=30, high_pass=1, bw_n_pole=5)

Applies a high and low-pass filter of butterworth design (n pole 5). For altering the
threshold values for filters, change add keyword arguments low_pass for low pass filter cut-off
(default=30) and high_pass for high-pass cut-off (default=1). To change the nth order
of the butterworth filter, use keyword bw_n_pole (default=5).

Returns filtered data
"""
function highlow_butterworth_filter(
    data, sampling_rate;
    low_pass=30,
    high_pass=1,
    bw_n_pole=5,
)

# Setting up low-pass filter properties
    low_threshold = low_pass
    responsetype_low = Lowpass(low_threshold, fs=sampling_rate)
    designmethod = Butterworth(bw_n_pole)
    # Applying filter
    low_pass_filter = digitalfilter(responsetype_low, designmethod)
    lowp_filtered_data = filtfilt(low_pass_filter, data)

    # Setup high-pass filter properties
    high_threshold = high_pass
    responsetype_high = Highpass(high_threshold, fs=sampling_rate)
    # Applying filter
    high_pass_filter = digitalfilter(responsetype_high, designmethod)
    filtered_data = filtfilt(high_pass_filter, lowp_filtered_data)

    # Resetting the offset
    filtered_data = filtered_data .+ mean(data, dims=1)
    @info "New filters are alive and hopefully well!"
    return filtered_data

end

"""
    highlow_butterworth_filter(data::Dict, sampling_rate; low_pass=30, high_pass=1, bw_n_pole=5)

Data contains all conditions and is a Dict (subject). Applies a high and low-pass filter of butterworth design (n pole 5). For altering the
threshold values for filters, change add keyword arguments low_pass for low pass filter cut-off
(default=30) and high_pass for high-pass cut-off (default=1). To change the nth order
of the butterworth filter, use keyword bw_n_pole (default=5).

Returns filtered data as a Dict
"""
function highlow_butterworth_filter(
    data::Dict, sampling_rate;
    low_pass=30,
    high_pass=1,
    bw_n_pole=5,
)

    filtered_data = Dict()
    for (condition, cond_data) in data
        filtered_data[condition] = highlow_butterworth_filter(
            cond_data,
            sampling_rate,
            low_pass=low_pass,
            high_pass=high_pass,
            bw_n_pole=bw_n_pole,
        )
    end

    return filtered_data

end
