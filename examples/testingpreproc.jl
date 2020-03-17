#' # Simple pipeline

#' Loading a single conditon from subject where epoch data was extracted via BESA®. In This
#' example we use some more plausible data than the test data

using Plots
gr()
using Measures
using MegTools
test = load_cont_epochs("condEpoch.mat")


#' The data from condition "2" (defined in BESA®) is averaged across all the trials
test_average = average_across_trials(test["2"])

#' We select data that we're interested in: in this case the pre-defined auditoryN1m channels
#' and take a look at the averaged waveforms from the selected channels.
test_average_auditory,auditory_left,auditory_right = select_channels(
    test_average,
    paradigm="auditoryN1m",
)

plot(test_average_auditory, legend=false, size=(1000,500))

#' Applying filters to smoothen out the waveform
filtered = highlow_butterworth_filter(test_average_auditory, 1000)
plot(test["2"].time, filtered(channels=:MEG1621), label="Filtered", size=(1000,500), linewidth=3, color=:royalblue);
plot!(test["2"].time, test_average_auditory(channels=:MEG1621), label="Raw", color=:lightblue)


#' Follow up with baseline correction of the data
baseline_corrected = baseline_correction(filtered)
plot(test["2"].time, filtered(channels=:MEG1621), label="Only Filtered", size=(1000,500), linewidth=3, color=:royalblue);
plot!(test["2"].time, baseline_corrected(channels=:MEG1621), label="Baseline Corrected", size=(1000,500), linewidth=3, color=:crimson)

#' And finally finding peaks in both left and right sets of channels
a,b,c,d = find_peaks(baseline_corrected, auditory_left, auditory_right)

# Takinga look at all the channels with marked peak values
channel_plots = plot(layout=(9,3), size = (1000,3000), margin=5mm, legend=false, ticks=[])
for channel = 1:26
    plot!(channel_plots, test_average_auditory[:,channel], color=:lightblue, subplot=channel, label = "Raw Signal")
    plot!(channel_plots, filtered[:,channel], subplot=channel, width=2, color=:royalblue,label = "filtered Signal")
    plot!(channel_plots, baseline_corrected[:,channel], subplot=channel, color=:crimson, width=2, label="Baseline corrected")
    if test_average_auditory.channels[channel] == c
        plot!(reverse(findmax(baseline_corrected[:,channel])), seriestype=:scatter, subplot=channel, color=:green, label="Peak left hem", markersize=8)
    elseif test_average_auditory.channels[channel] == d
        plot!(reverse(findmin(baseline_corrected[:,channel])), seriestype=:scatter, subplot=channel, color=:red, label="Peak right hem", markersize=8)
    end

end


channel_plots
