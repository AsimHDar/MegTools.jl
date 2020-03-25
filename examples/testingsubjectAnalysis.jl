#' #Pipeline with single subject (all conditions)
using Plots
gr()
using Measures
using MegTools
test = load_cont_epochs("condEpoch.mat")

test_average = average_across_trials(test)

#' Getting the averages of all conditions
test_average_auditory,auditory_left,auditory_right = select_channels(
    test_average,
    paradigm="auditoryN1m",
)

avs = plot(layout=(4,1), size=(1000,1000))
for (cond,val) in test_average_auditory
    plot!(avs, test_average_auditory[cond], legend=false)
end

avs

#' Filtering and baseline correcting
filtered = highlow_butterworth_filter(test_average_auditory, 1000)
baseline_corrected = baseline_correction(filtered)

peaks = find_peaks(baseline_corrected, auditory_left, auditory_right)

#' Loading trigger values from labels
cond_trigger_vals = load_trigger_values("regsoi")

#' For this specific analysis I need the peaks from all averaged and preprocecced ERFS
soi, left_amps, right_amps = collect_peaks(peaks)

#' Plotting peaks that we got
scatter(soi,left_amps, label="Left peak amplitudes");
scatter!(soi,right_amps, label="Right peak amplitudes")
