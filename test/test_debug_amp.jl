using Test
using StochProtocol
using StochProtocol.Explore.Run: run_protocol

@testset "Debug AMP execution" begin
    proto = """
    PROTOCOL AMP_DEBUG
    PROCESSES: 2
    STATE:
        x ∈ {0,1}

    INITIAL VALUES:
        [0, 1]

    PARAMETERS:
        y ∈ [0,1] = 0.5

    CHANNEL:
        stochastic

    UPDATE RULE:
        if received_diff(x) then
            xᵢ ← y
        else
            xᵢ ← xᵢ
        end

    METRICS:
        discrepancy
        consensus
    """

    # Run with p=1 (deterministic delivery) and enable tracing
    res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1, seed=1, trace=true)

    println("\n=== AMP DEBUG RESULTS ===")
    println("p = 1.0")
    println("mean_discrepancy = $(res[1].mean_discrepancy)")
    println("consensus_probability = $(res[1].consensus_probability)")
    println("Expected: mean_discrepancy ≈ 0.0, consensus_probability ≈ 1.0")
    println("========================\n")
end
