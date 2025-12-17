using Test
using StochProtocol
using StochProtocol.Explore.Run: run_protocol

@testset "AMP matches theory for E[D] = 1-p" begin
    proto = """
    PROTOCOL AMP_THEORY
    PROCESSES: 2
    STATE:
        x ∈ {0,1}

    INITIAL VALUES:
        [0, 1]

    PARAMETERS:
        y ∈ [0,1] = 0.0

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

    # Test p=0: E[D] = 1, P(consensus) = 0
    res_0 = run_protocol(proto; p_values=[0.0], rounds=1, repetitions=1000, seed=1)
    @test abs(res_0[1].mean_discrepancy - 1.0) < 0.02
    @test res_0[1].consensus_probability < 0.02

    # Test p=0.5: E[D] = 0.5, P(consensus) depends on y value
    # With y=0 and initial [0,1], consensus happens when message 0→1 arrives
    # So P(consensus) ≈ p = 0.5
    res_half = run_protocol(proto; p_values=[0.5], rounds=1, repetitions=2000, seed=1)
    @test abs(res_half[1].mean_discrepancy - 0.5) < 0.03
    @test abs(res_half[1].consensus_probability - 0.5) < 0.03

    # Test p=1.0: E[D] = 0, P(consensus) = 1.0
    res_1 = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1000, seed=1)
    @test res_1[1].mean_discrepancy < 0.01
    @test res_1[1].consensus_probability > 0.99

    println("\n✓ AMP theory validated:")
    println("  p=0.0: E[D]=$(round(res_0[1].mean_discrepancy, digits=3)), P(cons)=$(round(res_0[1].consensus_probability, digits=3))")
    println("  p=0.5: E[D]=$(round(res_half[1].mean_discrepancy, digits=3)), P(cons)=$(round(res_half[1].consensus_probability, digits=3))")
    println("  p=1.0: E[D]=$(round(res_1[1].mean_discrepancy, digits=3)), P(cons)=$(round(res_1[1].consensus_probability, digits=3))")
end
