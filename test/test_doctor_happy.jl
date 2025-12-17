using Test
using StochProtocol
using StochProtocol.Explore.Errors: ExploreError

const SIMPLE_PROTO = """
PROTOCOL Simple

PROCESSES: 2

STATE:
    x ∈ ℝ

INITIAL:
    xᵢ = i

CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← self

METRICS:
    discrepancy
    consensus
"""

@testset "run_protocol with text" begin
    res = run_protocol(SIMPLE_PROTO; p_values=0:0.5:1.0, rounds=1, repetitions=3, seed=1)
    @test length(res) == 3
end

@testset "compare with text" begin
    comp = compare(SIMPLE_PROTO, SIMPLE_PROTO; p_values=0:0.5:1.0, rounds=1, repetitions=3) do
        """
        for p > -1:
            AMP.consensus >= FV.consensus
        """
    end
    @test comp.success
end

@testset "study returns friendly output" begin
    sr = study(SIMPLE_PROTO, SIMPLE_PROTO; p_values=0:1, rounds=1, repetitions=2)
    shown = sprint(show, MIME("text/plain"), sr)
    @test !occursin("StudyResult(", shown)
end

@testset "ExploreError on invalid protocol" begin
    bad = """
    PROTOCOL Broken
    PROCESSES: 2
    STATE:
        x ∈ ℝ
    METRICS:
        discrepancy
    """
    @test_throws ExploreError run_protocol(bad; rounds=1, repetitions=1)
end
