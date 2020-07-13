function load_trigger_values(experimental_paradigm::String)

    if experimental_paradigm == "regsoi"
        # Keys and time of soi (s)
        triggers = Dict(
        "1" => 1.0,
        "2" => 0.3,
        "3" => 0.4,
        "4" => 0.5,
        "5" => 0.6,
        "6" => 0.7,
        "7" => 0.8,
        "8" => 0.9,
        "9" => 1.1,
        "10" => 1.2,
        "11" => 1.3,
        "12" => 1.4,
        "13" => 1.5,
        "14" => 1.6,
        "15" => 1.7,
        "16" => 1.8,
        "17" => 1.9,
        "18" => 2.0,
        "19" => 1.001, # a second round of 1s to see an effect of fatigue
        "20" => "Noise",
    )

    elseif experimental_paradigm == "soistream"
        # Keys (in ms) and time of soi (s)
        triggers = Dict(
        "250" => 0.25,
        "500" => 0.5,
        "750" => 0.75,
        "1000" => 1.0,
        "1500" => 1.5,
        "2000" => 2.0,
        "3000" => 3.0,
        "4000" => 4.0,
        "5000" => 5.0,
        "7000" => 7.0,
    )



    else
    @error "Experimental paradigm not found, make yours and add it into src/triggerkeys.jl"
    end
    return triggers

end


a = [2,3,4,5]

function dojo()
    return a[2]=666
end