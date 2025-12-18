# Build documentation locally
using Pkg

# Activate docs environment
Pkg.activate(@__DIR__)

# Add local StochProtocol package
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))

# Install dependencies
Pkg.instantiate()

# Build docs
include("make.jl")

println("\n✓ Documentation built successfully!")
println("Open docs/build/index.html in your browser to view.")
