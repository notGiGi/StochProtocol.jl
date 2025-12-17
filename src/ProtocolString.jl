module ProtocolString

export Protocol

"""
    Protocol(text::String)

Wrapper para strings de protocolos que se muestra bonito en notebooks.

# Ejemplo
```julia
AMP = Protocol(\"\"\"
PROTOCOL AMP
PROCESSES: 2
...
\"\"\")
```
"""
struct Protocol
    text::String
end

# Constructor conveniente desde string
Base.convert(::Type{Protocol}, s::AbstractString) = Protocol(String(s))

# Para usar en run_protocol
Base.String(p::Protocol) = p.text
Base.convert(::Type{String}, p::Protocol) = p.text

# Display bonito en notebooks y REPL
function Base.show(io::IO, ::MIME"text/plain", p::Protocol)
    lines = split(p.text, '\n')

    # Encontrar el nombre del protocolo
    protocol_name = "Protocol"
    for line in lines
        if startswith(strip(line), "PROTOCOL")
            parts = split(strip(line))
            if length(parts) >= 2
                protocol_name = parts[2]
                break
            end
        end
    end

    println(io, "╭─────────────────────────────────────────────────────────────╮")
    println(io, "│  Protocol: ", rpad(protocol_name, 48), "│")
    println(io, "╰─────────────────────────────────────────────────────────────╯")
    println(io)

    # Mostrar primeras líneas relevantes
    relevant_lines = []
    for line in lines
        stripped = strip(line)
        if !isempty(stripped)
            push!(relevant_lines, "  " * line)
            if length(relevant_lines) >= 8
                break
            end
        end
    end

    for line in relevant_lines
        println(io, line)
    end

    if length(lines) > 12
        println(io, "  ⋮")
    end

    println(io)
    println(io, "  ✓ Protocol loaded and ready to run")
end

# Display compacto
function Base.show(io::IO, p::Protocol)
    lines = split(p.text, '\n')
    protocol_name = "Protocol"
    for line in lines
        if startswith(strip(line), "PROTOCOL")
            parts = split(strip(line))
            if length(parts) >= 2
                protocol_name = parts[2]
                break
            end
        end
    end
    print(io, "Protocol(\"", protocol_name, "\")")
end

end
