"""
Jupyter Notebook Setup for StochProtocol

This file provides helpers for using mathematical notation in Jupyter notebooks.
Load it at the beginning of your notebook with:

```julia
include("path/to/jupyter_setup.jl")
```
"""

using StochProtocol

# Define a custom display for protocol strings with notation help
struct NotationHelper end

function Base.show(io::IO, ::MIME"text/html", ::NotationHelper)
    html = """
    <div style="background: #f0f9ff; border-left: 4px solid #0891b2; padding: 1rem; margin: 1rem 0; border-radius: 4px;">
        <h3 style="margin-top: 0; color: #0891b2;">✨ Mathematical Notation Shortcuts</h3>
        <p>Use these shortcuts when writing protocols:</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 0.5rem;">
            <thead>
                <tr style="background: #e0f2fe;">
                    <th style="padding: 0.5rem; text-align: left;">Type This</th>
                    <th style="padding: 0.5rem; text-align: left;">Get This</th>
                    <th style="padding: 0.5rem; text-align: left;">Example</th>
                </tr>
            </thead>
            <tbody>
                <tr><td style="padding: 0.5rem;"><code>\\xi + TAB</code></td><td style="padding: 0.5rem;">xᵢ</td><td style="padding: 0.5rem;"><code>xᵢ ← 0.5</code></td></tr>
                <tr style="background: #f0f9ff;"><td style="padding: 0.5rem;"><code>\\leftarrow + TAB</code></td><td style="padding: 0.5rem;">←</td><td style="padding: 0.5rem;"><code>xᵢ ← avg(inbox)</code></td></tr>
                <tr><td style="padding: 0.5rem;"><code>\\in + TAB</code></td><td style="padding: 0.5rem;">∈</td><td style="padding: 0.5rem;"><code>x ∈ ℝ</code></td></tr>
                <tr style="background: #f0f9ff;"><td style="padding: 0.5rem;"><code>\\bbR + TAB</code></td><td style="padding: 0.5rem;">ℝ</td><td style="padding: 0.5rem;"><code>x ∈ ℝ</code></td></tr>
                <tr><td style="padding: 0.5rem;"><code>\\alpha + TAB</code></td><td style="padding: 0.5rem;">α</td><td style="padding: 0.5rem;"><code>α = 0.5</code></td></tr>
                <tr style="background: #f0f9ff;"><td style="padding: 0.5rem;"><code>\\le + TAB</code></td><td style="padding: 0.5rem;">≤</td><td style="padding: 0.5rem;"><code>x ≤ 1</code></td></tr>
            </tbody>
        </table>
        <div style="margin-top: 1rem; padding: 0.75rem; background: white; border-radius: 4px;">
            <strong>💡 Pro Tip:</strong> Julia's REPL and Jupyter support LaTeX-style tab completion!
            <ul style="margin: 0.5rem 0;">
                <li>Type <code>\\</code> followed by LaTeX command name</li>
                <li>Press <code>TAB</code> to complete</li>
                <li>Example: <code>\\alpha</code> + TAB = α</li>
            </ul>
        </div>
        <div style="margin-top: 0.5rem;">
            <strong>Common Subscripts:</strong><br>
            <code>\\_i + TAB</code> → ᵢ,
            <code>\\_j + TAB</code> → ⱼ,
            <code>\\_0 + TAB</code> → ₀,
            <code>\\_1 + TAB</code> → ₁
        </div>
    </div>
    """
    print(io, html)
end

# Auto-display notation help
function show_notation_help()
    display("text/html", NotationHelper())
end

# Quick template function
"""
    quick_protocol()

Display a protocol template in the notebook.
"""
function quick_protocol()
    template = """
Protocol(\"\"\"
PROTOCOL MyProtocol
PROCESSES: 2
STATE: x ∈ ℝ
INITIAL VALUES: [0.0, 1.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS: discrepancy, consensus
\"\"\")
"""
    println("Copy and paste this template:")
    println("="^60)
    println(template)
    println("="^60)
end

# Common symbols as constants for easy copy-paste
const 𝕊 = Dict(
    :arrow => "←",
    :in => "∈",
    :real => "ℝ",
    :le => "≤",
    :ge => "≥",
    :ne => "≠",
    :alpha => "α",
    :beta => "β",
    :xi => "xᵢ",
    :xj => "xⱼ",
)

"""
    symbols()

Print a quick reference of common mathematical symbols.
"""
function symbols()
    println("Quick Symbol Reference:")
    println("="^40)
    for (name, symbol) in sort(collect(𝕊), by=x->x.first)
        println("  :$(rpad(string(name), 8))  →  $symbol")
    end
    println("="^40)
    println("Usage: 𝕊[:arrow] to get the symbol")
end

# Auto-run on include
println("📚 StochProtocol Jupyter Setup Loaded!")
println("Type `show_notation_help()` to see notation shortcuts")
println("Type `symbols()` for quick symbol reference")
println("Type `quick_protocol()` for a protocol template")
println()
