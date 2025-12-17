### A Pluto.jl notebook ###
# v0.19.x

using Markdown
using InteractiveUtils

# ╔═╡ 00000000-0000-0000-0000-000000000001
md"""
# StochProtocol Playground

Copia y pega protocolos (DSL tipo paper) y experimenta sin tocar archivos.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
begin
using StochProtocol
using PlutoUI
end

# ╔═╡ 00000000-0000-0000-0000-000000000003
md"""
### Protocol A (AMP por defecto)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000004
@bind protoA TextArea("""
PROTOCOL AMP

PROCESSES: 2

STATE:
    x ∈ ℝ

INITIAL VALUES:
    [0,1]

PARAMETERS:
    y ∈ [0,1] = 0.5

CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff(x) then
            xᵢ ← y
        end

METRICS:
    discrepancy
    consensus
"""; rows=16, columns=60)

# ╔═╡ 00000000-0000-0000-0000-000000000005
md"""
### Protocol B (FV por defecto)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000006
@bind protoB TextArea("""
PROTOCOL FV

PROCESSES: 2

STATE:
    x ∈ ℝ

INITIAL VALUES:
    [0,1]

CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff(x) then
            xᵢ ← received_other(x)
        end

METRICS:
    discrepancy
    consensus
"""; rows=16, columns=60)

# ╔═╡ 00000000-0000-0000-0000-000000000007
md"""
### Parámetros de simulación
"""

# ╔═╡ 00000000-0000-0000-0000-000000000008
@bind rounds Slider(1:10, default=1, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000009
@bind repetitions Slider(100:100:5000, default=2000, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000010
@bind p_step Slider(0.01:0.01:0.2, default=0.05, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000011
@bind consensus_eps Slider(1e-8:1e-7:1e-3, default=1e-6, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000012
p_values = collect(0:p_step:1)

# ╔═╡ 00000000-0000-0000-0000-000000000013
md"""
### Ejecutar estudio
"""

# ╔═╡ 00000000-0000-0000-0000-000000000014
study_result = study(protoA, protoB; p_values=p_values, rounds=rounds, repetitions=repetitions, consensus_eps=consensus_eps)

# ╔═╡ 00000000-0000-0000-0000-000000000015
md"""
### Resumen y tabla
"""

# ╔═╡ 00000000-0000-0000-0000-000000000016
study_result

# ╔═╡ 00000000-0000-0000-0000-000000000017
md"""
### Comparación declarativa (opcional)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000018
compare(protoA, protoB; p_values=p_values, rounds=rounds, repetitions=repetitions, consensus_eps=consensus_eps) do
    """
    for p > 0.6:
        AMP.consensus > FV.consensus
    """
end

# ╔═╡ 00000000-0000-0000-0000-000000000019
md"""
Este notebook evita archivos: puedes editar el texto de cada protocolo y ver los resultados al vuelo.
"""

