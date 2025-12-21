# Script to create a custom sysimage with StochProtocol precompiled
# This dramatically reduces load time in Google Colab and other environments

using PackageCompiler

# Create custom sysimage
create_sysimage(
    [:StochProtocol, :Plots, :PlutoUI];
    sysimage_path = "StochProtocol.so",
    precompile_execution_file = "precompile_workload.jl",
    cpu_target = "generic"  # Works on any machine
)

println("✅ Sysimage created: StochProtocol.so")
println("📦 Size: $(filesize("StochProtocol.so") / 1024 / 1024) MB")
println()
println("To use in Julia:")
println("  julia --sysimage StochProtocol.so")
println()
println("To use in Google Colab:")
println("  # Download sysimage first, then:")
println("  ENV[\"JULIA_SYSIMAGE\"] = \"StochProtocol.so\"")
