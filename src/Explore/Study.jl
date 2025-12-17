module Study

using ..Run: run_protocol
using ..Views: table, summary
using ..Errors: explore_try, ExploreError
using ...Metrics: DEFAULT_CONSENSUS_EPS

export study, StudyResult

"""
Aggregate result of running and contrasting two protocols side by side.
"""
struct StudyResult
    resA
    resB
    comparison_summary::String
    tables::Dict{Symbol,Any}
end

"""
High-level helper for notebooks: run two protocols (path or text), return both
results and a short comparative summary.
"""
function study(protocolA::AbstractString, protocolB::AbstractString;
               p_values=0:0.05:1,
               rounds::Int=1,
               repetitions::Int=2000,
               seed::Int=123,
               consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
               debug::Bool=false)
    explore_try(; debug=debug) do
        resA = run_protocol(protocolA; p_values=p_values, rounds=rounds, repetitions=repetitions, seed=seed, consensus_eps=consensus_eps, debug=debug)
        resB = run_protocol(protocolB; p_values=p_values, rounds=rounds, repetitions=repetitions, seed=seed, consensus_eps=consensus_eps, debug=debug)
        comp_summary = build_comparison_summary(resA, resB)
        tbls = Dict(:A => table(resA), :B => table(resB), :combined => combined_table(resA, resB))
        return StudyResult(resA, resB, comp_summary, tbls)
    end
end

"""
Build a qualitative comparison between two runs.
"""
function build_comparison_summary(resA, resB)
    ps = resA.p_values
    diffs = [resA[i].consensus_probability - resB[i].consensus_probability for i in 1:length(resA)]
    high_mask = ps .> 0.5
    low_mask = ps .< 0.5
    msgs = String[]
    if any(high_mask)
        mean_high = sum(diffs[high_mask]) / sum(high_mask)
        push!(msgs, mean_high > 0 ? "For p > 0.5, protocol A has higher consensus on average." :
                          mean_high < 0 ? "For p > 0.5, protocol B has higher consensus on average." :
                          "For p > 0.5, no clear dominance.")
    end
    if any(low_mask)
        mean_low = sum(diffs[low_mask]) / sum(low_mask)
        push!(msgs, mean_low > 0 ? "For p < 0.5, protocol A has higher consensus on average." :
                         mean_low < 0 ? "For p < 0.5, protocol B has higher consensus on average." :
                         "For p < 0.5, no clear dominance.")
    end
    isempty(msgs) && push!(msgs, "No clear dominance under current settings.")
    return join(msgs, " ")
end

"""
Merge both runs into a simple table for display.
"""
function combined_table(resA, resB)
    rows = NamedTuple[]
    for i in 1:length(resA)
        push!(rows, (
            p = resA.p_values[i],
            consensus_A = resA[i].consensus_probability,
            consensus_B = resB[i].consensus_probability,
            discrepancy_A = resA[i].mean_discrepancy,
            discrepancy_B = resB[i].mean_discrepancy,
        ))
    end
    return rows
end

function Base.show(io::IO, ::MIME"text/plain", sr::StudyResult)
    println(io, "Study summary")
    println(io, "--------------")
    println(io, summary(sr.resA))
    println(io)
    println(io, summary(sr.resB))
    println(io, "\nComparison:")
    println(io, sr.comparison_summary)
    combined = sr.tables[:combined]
    println(io, "\nMini table (first 6 rows):")
    for (i, row) in enumerate(combined[1:min(6, length(combined))])
        println(io, row)
    end
end

end
