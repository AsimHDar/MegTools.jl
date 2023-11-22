using Documenter, MegTools

makedocs(
    modules=[MegTools],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "DocStrings" => "functions.md",
        "Simple Pipeline" => "pipelines/testingpreproc.md",
    ],
    sitename="MegTools.jl",
    authors="Asim H. Dar",
)

deploydocs(
    repo="github.com/AsimHDar/MegTools.jl.git",
    target="build",
    push_preview=true,
    versions = nothing,
    devbranch = "main"
)

    
