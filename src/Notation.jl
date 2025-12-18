"""
    Notation

Mathematical notation helpers for easy protocol writing.

Provides simple ASCII shortcuts that automatically convert to mathematical symbols.
"""
module Notation

export @protocol_str, notation_help

# Mapping of ASCII shortcuts to Unicode math symbols
const NOTATION_MAP = Dict{String, String}(
    # Subscripts
    "_i" => "ᵢ",
    "_j" => "ⱼ",
    "_k" => "ₖ",
    "_n" => "ₙ",
    "_0" => "₀",
    "_1" => "₁",
    "_2" => "₂",
    "_3" => "₃",
    "_4" => "₄",
    "_5" => "₅",

    # Greek letters
    "alpha" => "α",
    "beta" => "β",
    "gamma" => "γ",
    "delta" => "δ",
    "epsilon" => "ε",
    "lambda" => "λ",
    "mu" => "μ",
    "pi" => "π",
    "sigma" => "σ",
    "tau" => "τ",
    "phi" => "φ",

    # Operators
    "<-" => "←",
    "->" => "→",
    "<=" => "≤",
    ">=" => "≥",
    "!=" => "≠",

    # Set notation
    "in" => "∈",
    "notin" => "∉",
    "subset" => "⊆",
    "union" => "∪",
    "intersect" => "∩",
    "emptyset" => "∅",

    # Logic
    "forall" => "∀",
    "exists" => "∃",
    "and" => "∧",
    "or" => "∨",
    "not" => "¬",

    # Math symbols
    "R" => "ℝ",
    "N" => "ℕ",
    "Z" => "ℤ",
    "Q" => "ℚ",
    "infty" => "∞",
    "sum" => "∑",
    "prod" => "∏",
    "sqrt" => "√",

    # Common combinations
    "x_i" => "xᵢ",
    "x_j" => "xⱼ",
    "x_0" => "x₀",
    "x_1" => "x₁",
)

"""
    expand_notation(text::String) -> String

Expands ASCII shortcuts to Unicode mathematical symbols.

# Examples
```julia
expand_notation("x_i <- avg(inbox)")  # returns "xᵢ ← avg(inbox)"
expand_notation("x in R")             # returns "x ∈ ℝ"
expand_notation("alpha <= beta")      # returns "α ≤ β"
```
"""
function expand_notation(text::String)::String
    result = text

    # Sort by length (longest first) to avoid partial replacements
    sorted_keys = sort(collect(keys(NOTATION_MAP)), by=length, rev=true)

    for key in sorted_keys
        result = replace(result, key => NOTATION_MAP[key])
    end

    return result
end

"""
    @protocol_str(text)

String macro that automatically expands ASCII shortcuts to Unicode math symbols.

# Examples
```julia
protocol"x_i <- avg(inbox)"  # becomes "xᵢ ← avg(inbox)"
protocol"x in R"             # becomes "x ∈ ℝ"
```

Use this macro when writing protocols to avoid typing Unicode symbols directly:

```julia
using StochProtocol
using StochProtocol.Notation

amp = Protocol(protocol\"\"\"
PROTOCOL AMP
PROCESSES: 2
STATE: x in {0,1}
INITIAL VALUES: [0.0, 1.0]
PARAMETERS: y = 0.5
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then x_i <- y else x_i <- x end

METRICS: discrepancy, consensus
\"\"\")
```
"""
macro protocol_str(text)
    return expand_notation(text)
end

"""
    notation_help()

Print a helpful guide of all available notation shortcuts.
"""
function notation_help()
    println("━"^70)
    println("StochProtocol Notation Shortcuts")
    println("━"^70)

    categories = [
        ("Subscripts", filter(p -> startswith(p.first, "_"), NOTATION_MAP)),
        ("Operators", filter(p -> p.first in ["<-", "->", "<=", ">=", "!="], NOTATION_MAP)),
        ("Set Notation", filter(p -> p.first in ["in", "notin", "subset", "union", "intersect", "emptyset"], NOTATION_MAP)),
        ("Greek Letters", filter(p -> p.first in ["alpha", "beta", "gamma", "delta", "epsilon", "lambda", "mu", "pi", "sigma", "tau", "phi"], NOTATION_MAP)),
        ("Number Sets", filter(p -> p.first in ["R", "N", "Z", "Q"], NOTATION_MAP)),
        ("Common", filter(p -> startswith(p.first, "x_"), NOTATION_MAP)),
    ]

    for (category, items) in categories
        if !isempty(items)
            println("\n$category:")
            println("─"^70)
            for (ascii, unicode) in sort(collect(items), by=x->x.first)
                println("  $(rpad(ascii, 15)) →  $unicode")
            end
        end
    end

    println("\n" * "━"^70)
    println("Usage:")
    println("  1. Using the macro:    protocol\"x_i <- avg(inbox)\"")
    println("  2. Using the function: expand_notation(\"x_i <- avg(inbox)\")")
    println("━"^70)
end

end # module
