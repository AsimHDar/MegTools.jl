using Documenter, MegTools

makedocs(;
    modules=[MegTools],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/ElectronicTeaCup/MegTools.jl/blob/{commit}{path}#L{line}",
    sitename="MegTools.jl",
    authors="Asim H. Dar",
    assets=String[],
)

deploydocs(;
    repo="github.com/ElectronicTeaCup/MegTools.jl",
)
