module Views

using ..Errors: ExploreError

export summary, table, as_dataframe, ExploreRun

# Optional DataFrames support.
const _HAS_DATAFRAMES = try
    @eval using DataFrames
    true
catch
    false
end

"""
Container for a protocol run with metadata plus underlying Monte Carlo results.
It behaves like a vector for backward compatibility.
"""
struct ExploreRun
    name::String
    num_processes::Int
    rounds::Int
    repetitions::Int
    p_values::Vector{Float64}
    consensus_eps::Float64
    results
end

Base.getindex(er::ExploreRun, i) = er.results[i]
Base.length(er::ExploreRun) = length(er.results)
Base.iterate(er::ExploreRun, state...) = iterate(er.results, state...)

"""
Return a short textual summary for a protocol run.
"""
function summary(er::ExploreRun)::String
    length(er) == 0 && return "No Monte Carlo results available for $(er.name)."
    ps = er.p_values
    vals = [r.consensus_probability for r in er]
    maxval = maximum(vals)
    # Pick the largest p achieving the max consensus.
    best_idx = findlast(==(maxval), vals)
    worst_idx = argmin([r.consensus_probability for r in er])
    lines = [
        "Protocol: $(er.name) | processes=$(er.num_processes) rounds=$(er.rounds) reps=$(er.repetitions) eps=$(er.consensus_eps)",
        "p span: $(minimum(ps))..$(maximum(ps)) step≈$(length(ps)>1 ? ps[2]-ps[1] : 0)",
        "Consensus peaks at p=$(ps[best_idx]): $(round(er[best_idx].consensus_probability, digits=3))",
        "Lowest consensus at p=$(ps[worst_idx]): $(round(er[worst_idx].consensus_probability, digits=3))",
        "Discrepancy min=$(round(minimum(r.mean_discrepancy for r in er), digits=3)) max=$(round(maximum(r.mean_discrepancy for r in er), digits=3))",
    ]
    return join(lines, "\n")
end

"""
Return a table-like structure for a protocol run. DataFrame if available,
otherwise a vector of NamedTuples.
"""
function table(er::ExploreRun)
    rows = [(; p=r.p, mean_discrepancy=r.mean_discrepancy, consensus_probability=r.consensus_probability) for r in er]
    if _HAS_DATAFRAMES
        return DataFrames.DataFrame(rows)
    else
        return rows
    end
end

"""
Return a DataFrame or throw if DataFrames is unavailable.
"""
function as_dataframe(er::ExploreRun)
    _HAS_DATAFRAMES || throw(ExploreError("DataFrames is not available in this environment."))
    return DataFrames.DataFrame(table(er))
end

function Base.show(io::IO, ::MIME"text/plain", er::ExploreRun)
    println(io, summary(er))
    println(io, "")
    println(io, "Use results_table(results) for formatted output or table(results) for raw data.")
end

end
