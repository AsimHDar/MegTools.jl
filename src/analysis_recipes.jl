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
