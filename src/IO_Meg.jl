using AxisKeys
using LinearAlgebra
using MAT
using NamedDims
using Plots
using Statistics

"""
    load_cont_epochs(file_name)

Produces a dictionary of arrays (using AxisRange and NamedDims), based on the different
conditions classified from the input .mat file. The input .mat file is produced from the
BESA®-MATLAB® interface when the "Epochs around triggers" option is selected.

Each array has the following format: [time(ms), channels, trials]

"""
function load_cont_epochs(file_name)
## Loading the data of all epochs
cont_epochs = matread(file_name)
cont_epochs = cont_epochs["besa_channels"]
all_epochs  = cont_epochs["data"]["amplitudes"]

## Making sure all epochs are the same length
one_latency = cont_epochs["data"]["latencies"][1]
all_latencies = dropdims(cont_epochs["data"]["latencies"],dims=1)
test_all = map(x -> x==one_latency, all_latencies)
if false ∈ test_all
throw("Input Error: all epochs are not of the same size")
return
end


## Extracting all the conditons via their trigger codes

# Proallocating total number of conditions
stacked_conditions = Array{String,1}(undef, length(all_epochs))

# Going through all epochs to determine the type of event at t=0

for epoch = 1:length(all_epochs)
    # determine index at t=0 in each event
    epoch_latencies  = cont_epochs["data"]["event"][epoch]["latency"]

    if length(epoch_latencies) > 1
        t_zero   = findfirst(isequal(0),epoch_latencies[:])
    else
        t_zero   = findfirst(isequal(0),epoch_latencies)
    end

    # Get the condition label/trigger at t=0
    stacked_conditions[epoch]=string(cont_epochs["data"]["event"][epoch]["label"][t_zero][1])
end

# Getting all the different conditions and their counts so they can be nested (under a subject)
# by name. The count is so that we can preallocate the number of trials
unique_conditions = unique(stacked_conditions)
unique_counts = Dict([(condition,count(x->x==condition, stacked_conditions))
for condition in unique_conditions])

# Determine size of a specific epoch
epoch_dims = size(cont_epochs["data"]["amplitudes"][1])

# Making a dictionary to contain all epochs in each condition
# Preallocating based on known details
# DOC: epoch size of all conditions has to be the same
stacked_epochs = Dict()
for (condition,unique_count) in unique_counts
    stacked_epochs[condition] = Array{Float64,3}(undef,epoch_dims[1],epoch_dims[2],unique_count )
end
for condition in unique_conditions


    for epoch = 1:length(unique_counts[condition])
        # Placing the epoch data based on the condition
        condition_index = condition.==stacked_conditions
        relevant_epochs = all_epochs[condition_index]
        for trial = 1:length(relevant_epochs)
            stacked_epochs[condition][:,:,trial] = relevant_epochs[trial]
        end
        # Adding named dimentions. Getting the timing from from the first epoch, i.e
        # assuming that all epoch sizes are the same
         stacked_epochs[condition] = wrapdims(
            stacked_epochs[condition],
            time = dropdims(cont_epochs["data"]["latencies"][1],dims=1),
            channels = dropdims(Symbol.(cont_epochs["channellabels"]),dims=1),
            trials = 1:(size(stacked_epochs["1"],3)),
            )


    end
end

return stacked_epochs

end
