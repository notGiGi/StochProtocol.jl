# Simple script to build documentation locally
# Run with: julia docs/build_docs.jl

using Pkg

# Activate docs environment
Pkg.activate(@__DIR__)

# Add Documenter if not present
try
    using Documenter
catch
    Pkg.add("Documenter")
end

# Add main package from parent directory
Pkg.develop(PackageSpec(path=dirname(@__DIR__)))

# Build docs
include(joinpath(@__DIR__, "make.jl"))

println("\n✅ Documentation built successfully!")
println("Open docs/build/index.html in your browser to view.")
