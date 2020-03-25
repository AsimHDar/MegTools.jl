module MegTools

using AxisKeys
using LinearAlgebra
using MAT
using Measures
using NamedDims
using Statistics

# Paths are based on where this module is
# Once you're done with your script and feel you want to generalise it,
# then the functions are put here or 'include'-ed  here
# E.g. include("../scripts/ReadContEps.jl")

include("IO_Meg.jl")
export load_cont_epochs, load_BSepochs

include("analysis_recipes.jl")
export average_across_trials, select_channels, baseline_correction, find_peaks, collect_peaks


include("filters.jl")
export highlow_butterworth_filter

include("trigger_keys.jl")
export load_trigger_values



end
