using Test
using StochProtocol
using StochProtocol.Explore.Run: run_protocol

@testset "Complex Nested Expressions" begin
    @testset "Parenthesized Arithmetic" begin
        proto = """
        PROTOCOL ParenthesizedArithmetic
        PROCESSES: 3
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [1.0, 5.0, 9.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← min(all) + max(all)

        METRICS:
            consensus
        """

        res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # min + max = 1 + 9 = 10.0 for all nodes
        @test res[1].consensus_probability ≈ 1.0
    end

    @testset "Nested Aggregations" begin
        proto = """
        PROTOCOL NestedAggregations
        PROCESSES: 4
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [2.0, 4.0, 6.0, 8.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← max(all) - min(all)

        METRICS:
            consensus
        """

        res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # max - min = 8 - 2 = 6 for all nodes
        @test res[1].consensus_probability ≈ 1.0
    end

    @testset "Complex Arithmetic Chain" begin
        proto = """
        PROTOCOL ComplexChain
        PROCESSES: 2
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [10.0, 20.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← x + 5 - 3

        METRICS:
            discrepancy
        """

        res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # Node 1: 10 + 5 - 3 = 12
        # Node 2: 20 + 5 - 3 = 22
        # Discrepancy = 22 - 12 = 10
        @test res[1].mean_discrepancy ≈ 10.0
    end

    @testset "Mixed Operations" begin
        proto = """
        PROTOCOL MixedOperations
        PROCESSES: 3
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [2.0, 4.0, 6.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← sum(all) / count(all)

        METRICS:
            consensus
        """

        res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # sum(all) / count(all) = (2+4+6) / 3 = 4.0
        @test res[1].consensus_probability ≈ 1.0
    end

    println("\n✓ All complex expression tests passed!")
end
