module Comparisons

using ..Explore: run_protocol
using ..Metrics: DEFAULT_CONSENSUS_EPS
using ..Explore.Errors: ExploreError, explore_try
using ..Explore.Views: ExploreRun

export compare, ComparisonResult

"""
Result of comparing two protocols across identical experimental parameters.
"""
struct ComparisonResult
    protocolA::String
    protocolB::String
    resultsA
    resultsB
    p_values::Vector{Float64}
    success::Bool
    details::String
end

# Lightweight condition IR for the comparison DSL.
struct ConditionSpec
    op::Symbol           # :gt or :lt
    threshold::Float64
    metric::Symbol       # :consensus or :discrepancy
    comparator::Symbol   # :gt, :lt, :ge, :le
end

"""
compare(protocolA::String, protocolB::String; p_values, rounds, repetitions, seed=123, consensus_eps=1e-6) do
    \"\"\"
    for p > 0.6:
        AMP.consensus > FV.consensus
    \"\"\"
end

Runs both protocols under identical parameters, then evaluates simple
comparative statements over subsets of p. Allowed statements:
    for p > c:
        AMP.consensus > FV.consensus
    for p < c:
        FV.discrepancy <= AMP.discrepancy

Metrics: `consensus` (uses consensus_probability mean) and `discrepancy`
(mean_discrepancy). Comparators: >, <, >=, <=. Aggregation is always the mean
over the selected p values. Returns a `ComparisonResult` with a success flag and
friendly details; raises an `ExploreError` on failure.
"""
function compare(protocolA, protocolB;
                 p_values=0:0.05:1,
                 rounds::Int=1,
                 repetitions::Int=2000,
                 seed::Int=123,
                 consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
                 debug::Bool=false,
                 block::Function)
    explore_try(; debug=debug) do
        base_ps = collect(Float64, p_values)
        resA = obtain_results(protocolA, base_ps, rounds, repetitions, seed, consensus_eps, debug)
        resB = obtain_results(protocolB, base_ps, rounds, repetitions, seed, consensus_eps, debug)
        ps = resA isa ExploreRun ? resA.p_values : base_ps
        if resA isa ExploreRun && resB isa ExploreRun && resA.p_values != resB.p_values
            throw(ExploreError("Comparison inputs have incompatible p grids."))
        end
        cond_text = block()
        conds = parse_conditions(cond_text)
        nameA = resA isa ExploreRun ? resA.name : string(protocolA)
        nameB = resB isa ExploreRun ? resB.name : string(protocolB)
        success, detail_msg = evaluate_conditions(nameA, nameB, resA, resB, ps, conds)
        success || throw(ExploreError(detail_msg))
        return ComparisonResult(nameA, nameB, resA, resB, ps, success, detail_msg)
    end
end

"""
Convenience overload so a `do` block can be passed positionally.
"""
function compare(protocolA, protocolB, f::Function;
                 p_values=0:0.05:1,
                 rounds::Int=1,
                 repetitions::Int=2000,
                 seed::Int=123,
                 consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
                 debug::Bool=false)
    return compare(protocolA, protocolB;
                   p_values=p_values,
                   rounds=rounds,
                   repetitions=repetitions,
                   seed=seed,
                   consensus_eps=consensus_eps,
                   debug=debug,
                   block=f)
end

# Allow `do`-block style where the block syntactically precedes the arguments.
function compare(f::Function, protocolA, protocolB;
                 p_values=0:0.05:1,
                 rounds::Int=1,
                 repetitions::Int=2000,
                 seed::Int=123,
                 consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
                 debug::Bool=false)
    return compare(protocolA, protocolB;
                   p_values=p_values,
                   rounds=rounds,
                   repetitions=repetitions,
                   seed=seed,
                   consensus_eps=consensus_eps,
                   debug=debug,
                   block=f)
end

function obtain_results(obj, ps, rounds, repetitions, seed, consensus_eps, debug)
    if obj isa ExploreRun
        return obj
    else
        return run_protocol(obj; p_values=ps, rounds=rounds, repetitions=repetitions, seed=seed, consensus_eps=consensus_eps, debug=debug)
    end
end

# -----------------------------------------------------------
# Parsing the tiny comparison DSL (string-based for simplicity).

function parse_conditions(text)::Vector{ConditionSpec}
    text === nothing && return ConditionSpec[]
    lines = split(String(text), '\n')
    conds = ConditionSpec[]
    current_op = nothing
    current_thresh = nothing
    i = 0
    while i < length(lines)
        i += 1
        line = strip(lines[i])
        isempty(line) && continue
        if startswith(line, "for ")
            m = match(r"^for\s+p\s*([<>])\s*([0-9eE\.\+\-]+)\s*:\s*$", line)
            m === nothing && error("Invalid condition header: '$line'. Expected 'for p > c:' or 'for p < c:'.")
            current_op = m.captures[1] == ">" ? :gt : :lt
            current_thresh = parse(Float64, m.captures[2])
            # Next non-empty line should carry metric comparison.
            while i < length(lines) && isempty(strip(lines[i+1]))
                i += 1
            end
            i < length(lines) || error("Expected a metric comparison after '$line'")
            metric_line = String(strip(lines[i+1]))
            i += 1
            push!(conds, parse_metric_comparison(metric_line, current_op, current_thresh))
        else
            error("Unexpected line in comparison block: '$line'. Use 'for p > c:' then a metric comparison.")
        end
    end
    return conds
end

function parse_metric_comparison(line::AbstractString, op::Symbol, thresh::Float64)
    m = match(r"^(AMP|FV)\.(consensus|discrepancy)\s*(>|<|>=|<=)\s*(AMP|FV)\.(consensus|discrepancy)\s*$", String(line))
    m === nothing && error("Invalid metric comparison: '$line'. Use AMP.consensus > FV.consensus, etc.")
    left_proto = String(m.captures[1])
    left_metric = Symbol(m.captures[2])
    comp_str = m.captures[3]
    right_proto = String(m.captures[4])
    right_metric = Symbol(m.captures[5])
    comparator = comp_str == ">" ? :gt : comp_str == "<" ? :lt : comp_str == ">=" ? :ge : :le
    left_metric == right_metric || error("Metric mismatch in '$line': both sides must use the same metric.")
    # Allow either order; evaluation always treats A=AMP, B=FV, so invert comparator when sides are swapped.
    if left_proto == "AMP" && right_proto == "FV"
        return ConditionSpec(op, thresh, left_metric, comparator)
    elseif left_proto == "FV" && right_proto == "AMP"
        inv = comparator == :gt ? :lt : comparator == :lt ? :gt : comparator == :ge ? :le : :ge
        return ConditionSpec(op, thresh, left_metric, inv)
    else
        error("Invalid protocol aliases in '$line'. Use AMP and FV.")
    end
end

# -----------------------------------------------------------
# Evaluation

function evaluate_conditions(protocolA, protocolB, resA, resB, ps::Vector{Float64}, conds::Vector{ConditionSpec})
    isempty(conds) && return true, "No conditions provided; nothing to compare."
    msgs = String[]
    for cond in conds
        mask = cond.op == :gt ? ps .> cond.threshold : ps .< cond.threshold
        any(mask) || return false, "No p values satisfy condition 'p $(cond.op == :gt ? ">" : "<") $(cond.threshold)'."
        valsA = metric_values(resA, cond.metric)[mask]
        valsB = metric_values(resB, cond.metric)[mask]
        meanA = sum(valsA) / length(valsA)
        meanB = sum(valsB) / length(valsB)
        ok = cond.comparator == :gt ? meanA > meanB :
             cond.comparator == :lt ? meanA < meanB :
             cond.comparator == :ge ? meanA >= meanB :
             meanA <= meanB
        ok || begin
            msg = [
                "❌ Comparison failed",
                "",
                "Condition: p $(cond.op == :gt ? ">" : "<") $(cond.threshold)",
                "Metric: $(cond.metric)",
                "AMP mean = $(meanA)",
                "FV  mean = $(meanB)",
                "Expected: AMP $(comp_symbol(cond.comparator)) FV"
            ]
            return false, join(msg, "\n")
        end
        push!(msgs, "✓ Comparison passed: AMP.$(cond.metric) $(comp_symbol(cond.comparator)) FV.$(cond.metric) for p $(cond.op == :gt ? ">" : "<") $(cond.threshold)")
    end
    return true, join(msgs, "\n")
end

function metric_values(results, metric::Symbol)
    vals = metric == :consensus ? [r.consensus_probability for r in results] :
           metric == :discrepancy ? [r.mean_discrepancy for r in results] :
           error("Unsupported metric $(metric)")
    return vals
end

comp_symbol(cmp::Symbol) = cmp == :gt ? ">" : cmp == :lt ? "<" : cmp == :ge ? ">=" : "<="

function Base.show(io::IO, ::MIME"text/plain", cr::ComparisonResult)
    status = cr.success ? "✓" : "✗"
    println(io, "$status Comparison of $(cr.protocolA) vs $(cr.protocolB)")
    println(io, cr.details)
end

end
