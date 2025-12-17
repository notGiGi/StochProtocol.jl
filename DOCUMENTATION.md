# StochProtocol.jl Documentation

## 📚 What's Been Created

A complete documentation website similar to Flux.jl, including:

### Structure

```
docs/
├── build_docs.jl          # Simple build script
├── make.jl                # Documenter configuration
├── Project.toml           # Doc dependencies
├── README.md              # Developer guide
└── src/
    ├── index.md           # Home page (like Flux.jl)
    ├── quickstart.md      # 5-minute tutorial
    ├── getting_started.md # Detailed tutorial
    ├── guides/            # In-depth guides
    ├── examples/          # Example tutorials
    └── api/               # API reference
        └── core.md        # Core functions documented
```

## 🚀 Building the Documentation

### Option 1: Simple Build (Recommended)

```bash
julia docs/build_docs.jl
```

Then open `docs/build/index.html` in your browser.

### Option 2: Manual Build

```julia
using Pkg

# Activate docs environment
Pkg.activate("docs")

# Build
include("docs/make.jl")
```

### Option 3: Live Preview (Best for Development)

```julia
using Pkg
Pkg.add("LiveServer")

using LiveServer
servedocs(doc_env=true)
```

Visit http://localhost:8000 - changes auto-refresh!

## 📝 What Still Needs to Be Done

### Required Pages (TODO)

Create these files in `docs/src/`:

1. **`guides/dsl.md`** - Complete Protocol DSL reference
   - All syntax elements
   - PROCESSES, STATE, INITIAL VALUES
   - UPDATE RULE predicates
   - PARAMETERS
   - METRICS

2. **`guides/experiments.md`** - Running experiments
   - Parameter details
   - Monte Carlo configuration
   - Performance tips

3. **`guides/visualization.md`** - Plots and tables
   - `plot_discrepancy_vs_p`
   - `plot_consensus_vs_p`
   - `plot_comparison`
   - `results_table`
   - Customization options

4. **`examples/amp.md`** - Complete AMP tutorial
   - Theory
   - Implementation
   - Analysis
   - Results

5. **`examples/comparison.md`** - Comparing protocols
   - AMP vs FV
   - Side-by-side analysis

6. **`examples/multirounds.md`** - Multi-round analysis
   - Convergence
   - Round-by-round dynamics

7. **`api/dsl.md`** - DSL API reference
8. **`api/visualization.md`** - Visualization API

### Assets

Create `docs/src/assets/custom.css` for custom styling (optional).

## 🎨 Style Guide

The documentation follows Flux.jl's modern style:

- **Clean homepage** with 60-second example
- **"Why" section** highlighting benefits
- **Progressive disclosure** (quickstart → guides → API)
- **Runnable examples** everywhere
- **Admonitions** for tips/warnings
- **Cross-linking** between pages

### Writing Style

```markdown
# Title

Brief intro paragraph.

## Section

Clear explanations with code:

\`\`\`julia
# Runnable example
using StochProtocol
AMP = Protocol("""...""")
\`\`\`

!!! tip "Pro Tip"
    Use `Protocol()` for beautiful display!
```

## 🔗 Deploying to GitHub Pages

1. **Enable GitHub Pages:**
   - Settings → Pages → Source: `gh-pages` branch

2. **Update `docs/make.jl`:**
   ```julia
   # Uncomment and update:
   deploydocs(
       repo = "github.com/YOUR-USERNAME/StochProtocol.jl.git",
       devbranch = "main",
   )
   ```

3. **Push and deploy:**
   ```bash
   git add docs/
   git commit -m "Add documentation"
   git push

   # Build and deploy
   julia docs/build_docs.jl
   ```

Docs will appear at: `https://YOUR-USERNAME.github.io/StochProtocol.jl/`

## 📖 Documentation Features Implemented

### ✅ Complete

- [x] Homepage (index.md) - Flux-style landing page
- [x] Quick Start (quickstart.md) - 5-minute tutorial
- [x] Getting Started (getting_started.md) - Detailed intro
- [x] API Reference (api/core.md) - Core functions
- [x] Build scripts
- [x] Documentation structure
- [x] README for contributors

### ⏳ To Do

- [ ] Complete DSL guide
- [ ] Complete experiments guide
- [ ] Complete visualization guide
- [ ] Add all examples
- [ ] Add remaining API docs
- [ ] Custom CSS styling
- [ ] Add images/screenshots
- [ ] Set up GitHub Pages deployment

## 💡 Tips

### Adding Documentation for New Functions

1. **Add docstring in source code:**

```julia
"""
    my_function(x, y)

Does something useful.

# Arguments
- `x`: First parameter
- `y`: Second parameter

# Returns
- The result

# Examples
\`\`\`julia
result = my_function(1, 2)
\`\`\`
"""
function my_function(x, y)
    x + y
end
```

2. **Reference in docs:**

```markdown
## My Function

\`\`\`@docs
my_function
\`\`\`
```

### Using Admonitions

```markdown
!!! note "Mathematical Note"
    For AMP, E[D] = 1 - p

!!! tip "Performance"
    Use seed=42 for reproducibility

!!! warning "Memory"
    Large sweeps use memory

!!! danger "Breaking Change"
    API changed in v2.0
```

### Code Blocks

- Use `julia` for syntax highlighting
- Use `julia-repl` for REPL sessions
- Use `jldoctest` for testable examples

## 📚 Resources

- [Documenter.jl Manual](https://juliadocs.github.io/Documenter.jl/stable/)
- [Flux.jl Docs](https://fluxml.ai/Flux.jl/stable/) (style reference)
- [Example Julia Docs](https://docs.julialang.org/)

## 🎯 Next Steps

1. **Build locally** to verify it works
2. **Fill in TODO pages** (start with guides/dsl.md)
3. **Add examples** with real protocols
4. **Deploy to GitHub Pages**
5. **Share with users!**

---

**Questions?** Check `docs/README.md` or the Documenter.jl manual.
