#=
Run the sample protocols defined in `examples/protocols/*.protocol`.
Invoke with: `julia --project examples/run_examples.jl`
=#

using StochProtocol: run_protocol
using Printf

p_values = collect(0.0:0.1:1.0)
rounds = 1
repetitions = 1000
seed = 2024
consensus_eps = 1e-6  # Consensus threshold; change if stricter tolerance is desired.
# Example: run_protocol(...; consensus_eps=1e-4)

protocol_files = [
    "examples/protocols/amp.protocol",
    "examples/protocols/fv.protocol",
]

for file in protocol_files
    println("Running $(file)...")
    results = run_protocol(file; p_values=p_values, rounds=rounds, repetitions=repetitions, seed=seed, consensus_eps=consensus_eps)
    println("Consensus threshold eps = $(consensus_eps)")
    println("p\tmean_discrepancy\tconsensus_probability")
    for r in results
        @printf("%.2f\t%.4f\t%.3f\n", r.p, r.mean_discrepancy, r.consensus_probability)
    end
    println()
end
