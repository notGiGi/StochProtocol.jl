module Run

using ..Errors: ExploreError, explore_try
using ..Views: ExploreRun, summary, table
import ...DSL
using ...Metrics: DEFAULT_CONSENSUS_EPS

export run_protocol, run

"""
Explicit API to run a protocol specified by path or inline DSL text.
Accepts either an existing file, raw DSL text, a Protocol object, or an ExploreRun (returned as-is).
"""
function run_protocol(protocol;
                      p_values=0:0.05:1,
                      rounds::Int=1,
                      repetitions::Int=2000,
                      seed::Union{Int,Nothing}=nothing,
                      consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
                      debug::Bool=false,
                      trace::Bool=false,
                      trace_limit::Int=1)
    explore_try(; debug=debug) do
        # If it's already a path, read it; otherwise treat as inline text.
        # Also handle Protocol objects
        text = _load_protocol_text(String(protocol))
        # Parse to IR
        ir = _is_file_path(protocol) ? DSL.Parser.parse_protocol_file(protocol) : DSL.Parser.parse_protocol_text(text)
        # Lazy-load Experiments to avoid circularity.
        root = parentmodule(parentmodule(@__MODULE__))
        Experiments = getfield(root, :Experiments)
        MonteCarloSpec = getfield(Experiments, :MonteCarloSpec)
        run_many = getfield(Experiments, :run_many)
        # Sweep over p values.
        ps = collect(Float64, p_values)
        results = Any[]
        # Use random seed if not specified
        base_seed = seed === nothing ? rand(1:999999) : seed
        for (idx, p) in enumerate(ps)
            exp_spec = DSL.Compiler.compile(ir; p=p, rounds=rounds)
            mc = MonteCarloSpec(exp_spec, repetitions, base_seed + idx - 1)
            push!(results, run_many(mc; consensus_eps=consensus_eps, trace=trace, trace_limit=trace_limit))
        end
        return ExploreRun(ir.name, ir.num_processes, rounds, repetitions, ps, consensus_eps, results)
    end
end

# If a prior run is provided, return it directly (helps macro interoperability).
run_protocol(er::ExploreRun; kwargs...) = er

"""
Notebook-friendly entry point: run with notebook-friendly defaults and print
summary plus table automatically.
"""
function run(protocol_text::AbstractString;
             p_values=0:0.05:1,
             rounds::Int=1,
             repetitions::Int=2000,
             seed::Union{Int,Nothing}=nothing,
             consensus_eps::Float64=DEFAULT_CONSENSUS_EPS,
             debug::Bool=false,
             trace::Bool=false,
             trace_limit::Int=1,
             quiet::Bool=false)
    res = run_protocol(protocol_text; p_values=p_values, rounds=rounds, repetitions=repetitions, seed=seed, consensus_eps=consensus_eps, debug=debug, trace=trace, trace_limit=trace_limit)
    if !quiet
        println(summary(res))
        println()
        # Display a mini table
        tab = table(res)
        if tab isa AbstractVector
            for (i, row) in enumerate(tab[1:min(end, 6)])
                println("row $(i): ", row)
            end
        else
            show(tab[1:min(end, 6), :])
            println()
        end
    end
    return res
end

# Helpers ----------------------------------------------------------------

_is_file_path(s)::Bool = (s isa AbstractString) && ispath(String(s))
function _load_protocol_text(s)::String
    return _is_file_path(s) ? read(String(s), String) : String(s)
end

end
