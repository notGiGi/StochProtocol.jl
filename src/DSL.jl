module DSL

# DSL entrypoint for the paper-style protocol language. The language is a
# compact mathematical DSL (not Julia) intended to mirror paper-style protocol
# definitions. Implementation is split into IR, parser, and compiler.

include("DSL/IR.jl")
include("DSL/Parser.jl")
include("DSL/Compiler.jl")
using .IR
using .Parser
using .Compiler

# Legacy placeholder macro remains but intentionally does nothing yet.
export @protocol

macro protocol(args...)
    :(nothing)
end

end
