using Documenter
using StochProtocol

makedocs(
    sitename = "StochProtocol.jl",
    authors = "notGiGi",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://notGiGi.github.io/StochProtocol.jl",
        assets = ["assets/custom.css"],
        sidebar_sitename = false,
        size_threshold = 512000,
        collapselevel = 1,
        ansicolor = true,
    ),
    modules = [StochProtocol],
    pages = [
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Protocol DSL" => "guides/dsl.md",
            "Running Experiments" => "guides/experiments.md",
            "Delivery Models" => "guides/delivery_models.md",
            "Google Colab Setup" => "guides/colab_optimization.md",
        ],
        "Advanced Features" => [
            "Network Topologies" => "advanced/topologies.md",
            "Fault Models" => "advanced/faults.md",
            "Convergence Analysis" => "advanced/convergence.md",
            "Tracing & Debugging" => "advanced/tracing.md",
        ],
        "Examples" => [
            "Overview" => "examples/overview.md",
        ],
        "API Reference" => [
            "Core Functions" => "api/core.md",
        ],
    ],
    warnonly = true,
)

# Deploy to GitHub Pages
deploydocs(
    repo = "github.com/notGiGi/StochProtocol.jl.git",
    devbranch = "main",
)
