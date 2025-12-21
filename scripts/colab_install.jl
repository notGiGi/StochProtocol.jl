#!/usr/bin/env julia

"""
Ultra-fast installation script for Google Colab

Usage:
    julia colab_install.jl

This script:
1. Sets up optimized Julia environment
2. Installs only essential dependencies
3. Skips unnecessary precompilation
4. Uses binary packages when possible
"""

using Pkg

println("="^60)
println("StochProtocol.jl - Optimized Colab Installation")
println("="^60)
println()

# Step 1: Configure environment for speed
println("⚙️  Configuring environment...")
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"  # Skip auto precompile
ENV["JULIA_NUM_THREADS"] = "2"  # Use 2 threads in Colab

# Step 2: Activate temporary environment
println("📁 Creating temporary environment...")
Pkg.activate(temp=true)

# Step 3: Add only essential packages (no optional deps)
println("📦 Installing core packages...")
Pkg.add([
    PackageSpec(url="https://github.com/notGiGi/StochProtocol.jl"),
])

# Step 4: Add minimal plotting (GR backend is fastest)
println("📊 Installing plotting (GR backend)...")
Pkg.add("Plots")
ENV["GKSwstype"] = "100"  # Use GR for headless environment

# Step 5: Selective precompilation (only what we need)
println("🔨 Precompiling essentials...")
Pkg.precompile(["StochProtocol", "Plots"])

println()
println("="^60)
println("✅ Installation complete!")
println("="^60)
println()
println("Quick test:")
println("  using StochProtocol")
println("  protocol = Protocol(\\\"...\\\")")
println("  run_protocol(protocol; p_values=[0.7], rounds=10)")
println()
println("Total time: ~2-3 minutes")
println("="^60)
