# StochProtocol.jl Documentation

This directory contains the documentation for StochProtocol.jl built with [Documenter.jl](https://juliadocs.github.io/Documenter.jl/).

## Building the Documentation Locally

1. **Install dependencies:**

```julia
using Pkg
Pkg.activate("docs")
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
```

2. **Build the docs:**

```julia
include("docs/make.jl")
```

3. **View the docs:**

Open `docs/build/index.html` in your browser.

## Documentation Structure

```
docs/
├── make.jl                 # Build configuration
├── Project.toml            # Doc dependencies
├── src/
│   ├── index.md           # Home page
│   ├── quickstart.md      # Quick start guide
│   ├── guides/            # In-depth guides
│   │   ├── dsl.md
│   │   ├── experiments.md
│   │   └── visualization.md
│   ├── examples/          # Example tutorials
│   │   ├── amp.md
│   │   ├── comparison.md
│   │   └── multirounds.md
│   └── api/               # API reference
│       ├── core.md
│       ├── dsl.md
│       └── visualization.md
└── build/                  # Generated site (gitignored)
```

## Live Preview

For live preview while editing:

```julia
using LiveServer
servedocs(doc_env=true)
```

Then visit http://localhost:8000 in your browser. Changes to `.md` files will auto-refresh.

## Deploying to GitHub Pages

1. **Set up GitHub Pages:**
   - Go to repository Settings → Pages
   - Set source to `gh-pages` branch

2. **Enable deployment in `make.jl`:**
   - Uncomment the `deploydocs()` section
   - Update the repo URL

3. **Deploy:**

```bash
julia --project=docs docs/make.jl
```

The docs will be built and pushed to the `gh-pages` branch automatically.

## Writing Documentation

### Adding a New Page

1. Create the `.md` file in `src/`
2. Add it to the `pages` list in `make.jl`
3. Rebuild with `include("docs/make.jl")`

### Code Examples

Use triple backticks with `julia` for syntax highlighting:

````markdown
```julia
using StochProtocol
AMP = Protocol("""...""")
```
````

### Docstrings

Document functions with docstrings in the source code:

```julia
"""
    myfunction(x, y)

Description of what it does.

# Arguments
- `x`: First argument
- `y`: Second argument

# Returns
- The result

# Examples
```jldoctest
julia> myfunction(1, 2)
3
```
"""
function myfunction(x, y)
    x + y
end
```

Then reference them in docs with:

````markdown
```@docs
myfunction
```
````

### Admonitions

Use special blocks for tips, warnings, etc.:

```markdown
!!! tip "Performance Tip"
    Use fewer repetitions while prototyping.

!!! warning "Memory Usage"
    Large parameter sweeps can use significant memory.

!!! note "Mathematical Note"
    The expected discrepancy E[D] = 1 - p for AMP.
```

## Style Guide

- Use clear, simple language
- Include runnable code examples
- Show both simple and advanced usage
- Link to related sections
- Keep pages focused (one topic per page)

## Questions?

See the [Documenter.jl documentation](https://juliadocs.github.io/Documenter.jl/stable/) for more details.
