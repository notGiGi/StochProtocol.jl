using Documenter
using StochProtocol

makedocs(
    sitename = "StochProtocol.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://notGiGi.github.io/StochProtocol.jl",
        assets = ["assets/custom.css"],
        sidebar_sitename = false,
        size_threshold = 512000,
    ),
    modules = [StochProtocol],
    pages = [
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Guides" => [
            "Protocol DSL" => "guides/dsl.md",
            "Running Experiments" => "guides/experiments.md",
            "Visualization" => "guides/visualization.md",
        ],
        "Examples" => [
            "AMP Protocol" => "examples/amp.md",
            "Protocol Comparison" => "examples/comparison.md",
            "Multiple Rounds" => "examples/multirounds.md",
        ],
        "API Reference" => [
            "Core Functions" => "api/core.md",
            "Protocol DSL" => "api/dsl.md",
            "Visualization" => "api/visualization.md",
        ],
    ],
    warnonly = true,
)

# Deploy to GitHub Pages
deploydocs(
    repo = "github.com/notGiGi/StochProtocol.jl.git",
    devbranch = "main",
)
