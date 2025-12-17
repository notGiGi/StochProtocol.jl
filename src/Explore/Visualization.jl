module Visualization

using Plots
using PrettyTables

# Check if DataFrames is available
const _HAS_DATAFRAMES = try
    @eval using DataFrames
    true
catch
    false
end

export plot_discrepancy_vs_p, plot_consensus_vs_p, plot_comparison, results_table, results_comparison_table

"""
    plot_discrepancy_vs_p(results; title="Expected Discrepancy vs Probability")

Crea una gráfica hermosa de discrepancia esperada vs probabilidad de entrega.

# Argumentos
- `results`: Vector de resultados de run_protocol
- `title`: Título de la gráfica
- `save_path`: Opcional - path para guardar la imagen

# Retorna
- Un objeto Plot que se puede mostrar o guardar
"""
function plot_discrepancy_vs_p(results;
                               title="Expected Discrepancy vs Probability",
                               save_path=nothing,
                               xlabel="Delivery Probability (p)",
                               ylabel="Expected Discrepancy E[D]")

    # Extraer p values y discrepancies
    p_vals = [r.p for r in results]
    disc_vals = [r.mean_discrepancy for r in results]

    # Crear gráfica con estilo profesional
    plt = plot(p_vals, disc_vals,
               linewidth=3,
               marker=:circle,
               markersize=8,
               markerstrokewidth=2,
               markerstrokecolor=:white,
               color=:dodgerblue,
               label="E[D]",
               title=title,
               xlabel=xlabel,
               ylabel=ylabel,
               legend=:topright,
               grid=true,
               gridstyle=:dash,
               gridalpha=0.3,
               framestyle=:box,
               size=(800, 600),
               dpi=300,
               titlefontsize=16,
               guidefontsize=14,
               tickfontsize=12,
               legendfontsize=12,
               left_margin=5Plots.mm,
               bottom_margin=5Plots.mm)

    # Agregar línea de tendencia si hay suficientes puntos
    if length(p_vals) >= 3
        plot!(plt, p_vals, disc_vals,
              linestyle=:dash,
              linewidth=1.5,
              color=:gray,
              alpha=0.5,
              label="Trend")
    end

    # Guardar si se especifica path
    if save_path !== nothing
        savefig(plt, save_path)
        println("📊 Gráfica guardada en: $save_path")
    end

    return plt
end

"""
    plot_consensus_vs_p(results; title="Consensus Probability vs Delivery Probability")

Crea una gráfica de probabilidad de consenso vs probabilidad de entrega.
"""
function plot_consensus_vs_p(results;
                             title="Consensus Probability vs Delivery Probability",
                             save_path=nothing,
                             xlabel="Delivery Probability (p)",
                             ylabel="Consensus Probability P(consensus)")

    p_vals = [r.p for r in results]
    cons_vals = [r.consensus_probability for r in results]

    plt = plot(p_vals, cons_vals,
               linewidth=3,
               marker=:diamond,
               markersize=8,
               markerstrokewidth=2,
               markerstrokecolor=:white,
               color=:forestgreen,
               label="P(consensus)",
               title=title,
               xlabel=xlabel,
               ylabel=ylabel,
               legend=:bottomright,
               grid=true,
               gridstyle=:dash,
               gridalpha=0.3,
               framestyle=:box,
               size=(800, 600),
               dpi=300,
               titlefontsize=16,
               guidefontsize=14,
               tickfontsize=12,
               legendfontsize=12,
               left_margin=5Plots.mm,
               bottom_margin=5Plots.mm,
               ylims=(0, 1.05))

    # Agregar línea en y=1 para referencia
    hline!(plt, [1.0],
           linestyle=:dot,
           linewidth=2,
           color=:red,
           alpha=0.5,
           label="Perfect Consensus")

    if save_path !== nothing
        savefig(plt, save_path)
        println("📊 Gráfica guardada en: $save_path")
    end

    return plt
end

"""
    plot_comparison(results_dict; title="Protocol Comparison")

Compara múltiples protocolos en una sola gráfica.

# Argumentos
- `results_dict`: Dict{String, Vector{Result}} - nombre del protocolo => resultados
"""
function plot_comparison(results_dict;
                        title="Protocol Comparison: Expected Discrepancy",
                        save_path=nothing,
                        metric=:discrepancy)

    colors = [:dodgerblue, :forestgreen, :orangered, :purple, :gold, :crimson]
    markers = [:circle, :diamond, :square, :star5, :hexagon, :cross]

    plt = plot(title=title,
               xlabel="Delivery Probability (p)",
               ylabel=metric == :discrepancy ? "Expected Discrepancy E[D]" : "Consensus Probability",
               legend=:best,
               grid=true,
               gridstyle=:dash,
               gridalpha=0.3,
               framestyle=:box,
               size=(900, 600),
               dpi=300,
               titlefontsize=16,
               guidefontsize=14,
               tickfontsize=12,
               legendfontsize=11,
               left_margin=5Plots.mm,
               bottom_margin=5Plots.mm)

    idx = 1
    for (protocol_name, results) in results_dict
        p_vals = [r.p for r in results]
        vals = metric == :discrepancy ?
               [r.mean_discrepancy for r in results] :
               [r.consensus_probability for r in results]

        color = colors[mod1(idx, length(colors))]
        marker = markers[mod1(idx, length(markers))]

        plot!(plt, p_vals, vals,
              linewidth=2.5,
              marker=marker,
              markersize=7,
              markerstrokewidth=2,
              markerstrokecolor=:white,
              color=color,
              label=protocol_name)

        idx += 1
    end

    if save_path !== nothing
        savefig(plt, save_path)
        println("📊 Gráfica guardada en: $save_path")
    end

    return plt
end

"""
    results_table(results; protocol_name="Protocol")

Crea una tabla hermosa y formateada de los resultados.
En Jupyter notebooks con DataFrames, muestra una tabla interactiva con colores.
"""
function results_table(results; protocol_name="Protocol")

    # Si tenemos DataFrames, crear DataFrame bonito para Jupyter
    if _HAS_DATAFRAMES
        df = DataFrames.DataFrame(
            p = [r.p for r in results],
            E_D = [round(r.mean_discrepancy, digits=6) for r in results],
            P_consensus = [round(r.consensus_probability, digits=4) for r in results],
            Trials = [r.repetitions for r in results]
        )

        println("\nResults: $protocol_name\n")

        return df  # Jupyter lo renderiza bonito automáticamente
    else
        # Fallback a PrettyTables si no hay DataFrames
        data = Matrix{Any}(undef, length(results), 4)
        for (i, r) in enumerate(results)
            data[i, 1] = r.p
            data[i, 2] = round(r.mean_discrepancy, digits=6)
            data[i, 3] = round(r.consensus_probability, digits=4)
            data[i, 4] = r.repetitions
        end

        headers = ["p", "E[D]", "P(consensus)", "Trials"]

        println("\n" * "━"^70)
        println("📊 RESULTS: $protocol_name")
        println("━"^70)

        pretty_table(data,
                     column_labels=headers,
                     alignment=[:center, :right, :right, :right])

        println("━"^70)
        println()

        return nothing
    end
end

"""
    results_comparison_table(results_dict)

Crea una tabla comparativa de múltiples protocolos.
En Jupyter con DataFrames, muestra una tabla interactiva y colorida.
"""
function results_comparison_table(results_dict)

    # Encontrar todos los valores de p únicos
    all_p_values = Set{Float64}()
    for results in values(results_dict)
        for r in results
            push!(all_p_values, r.p)
        end
    end
    p_values = sort(collect(all_p_values))

    protocols = collect(keys(results_dict))

    # Si tenemos DataFrames, crear DataFrame bonito
    if _HAS_DATAFRAMES
        # Crear un dict para construir el DataFrame
        df_data = Dict{Symbol, Vector{Any}}()
        df_data[:p] = p_values

        for protocol in protocols
            results = results_dict[protocol]
            ed_col = Symbol("$(protocol)_ED")
            pc_col = Symbol("$(protocol)_Pc")

            df_data[ed_col] = Vector{Any}(undef, length(p_values))
            df_data[pc_col] = Vector{Any}(undef, length(p_values))

            for (i, p) in enumerate(p_values)
                found = false
                for r in results
                    if r.p == p
                        df_data[ed_col][i] = round(r.mean_discrepancy, digits=6)
                        df_data[pc_col][i] = round(r.consensus_probability, digits=4)
                        found = true
                        break
                    end
                end
                if !found
                    df_data[ed_col][i] = missing
                    df_data[pc_col][i] = missing
                end
            end
        end

        df = DataFrames.DataFrame(df_data)

        println("\nProtocol Comparison\n")

        return df
    else
        # Fallback a PrettyTables
        n_protocols = length(protocols)
        data = Matrix{Any}(undef, length(p_values), 2 * n_protocols + 1)

        for (i, p) in enumerate(p_values)
            data[i, 1] = p

            for (j, protocol) in enumerate(protocols)
                results = results_dict[protocol]
                found = false
                for r in results
                    if r.p == p
                        data[i, 2j] = round(r.mean_discrepancy, digits=6)
                        data[i, 2j + 1] = round(r.consensus_probability, digits=4)
                        found = true
                        break
                    end
                end
                if !found
                    data[i, 2j] = "-"
                    data[i, 2j + 1] = "-"
                end
            end
        end

        headers = ["p"]
        for protocol in protocols
            push!(headers, "$protocol E[D]")
            push!(headers, "$protocol P(c)")
        end

        println("\n" * "━"^100)
        println("📊 PROTOCOL COMPARISON")
        println("━"^100)

        pretty_table(data,
                     column_labels=headers,
                     alignment=vcat([:center], repeat([:right], 2 * n_protocols)))

        println("━"^100)
        println()

        return nothing
    end
end

end # module
