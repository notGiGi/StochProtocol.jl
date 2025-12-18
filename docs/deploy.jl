# Manual deployment script for documentation
# Run this to deploy docs to gh-pages branch

using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.instantiate()

# Set environment for deployment
ENV["GITHUB_REPOSITORY"] = "notGiGi/StochProtocol.jl"
ENV["GITHUB_EVENT_NAME"] = "push"
ENV["GITHUB_REF"] = "refs/heads/main"

# Build and deploy
include("make.jl")

println("\n✓ Documentation deployed to gh-pages branch!")
println("Visit: https://notgigi.github.io/StochProtocol.jl/")
