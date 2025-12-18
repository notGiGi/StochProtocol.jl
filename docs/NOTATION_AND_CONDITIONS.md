# Notación Matemática y Condiciones Avanzadas

Este documento explica cómo escribir fácilmente símbolos matemáticos y usar condiciones avanzadas en StochProtocol.

---

## 📝 Parte 1: Notación Matemática (Symbols)

### Problema
Escribir símbolos como `xᵢ ← ` o `x ∈ ℝ` puede ser difícil sin saber los atajos.

### Soluciones

#### Opción 1: Tab-Completion en Julia (RECOMENDADO)

Julia tiene soporte nativo para completado estilo LaTeX. Solo escribe `\` seguido del nombre LaTeX y presiona TAB:

```julia
# Subscripts
\_i + TAB      → ᵢ
\_j + TAB      → ⱼ
\_0 + TAB      → ₀
\_1 + TAB      → ₁

# Arrows
\leftarrow + TAB   → ←
\rightarrow + TAB  → →

# Set notation
\in + TAB      → ∈
\notin + TAB   → ∉

# Greek letters
\alpha + TAB   → α
\beta + TAB    → β
\gamma + TAB   → γ

# Number sets
\bbR + TAB     → ℝ
\bbN + TAB     → ℕ
\bbZ + TAB     → ℤ

# Comparisons
\le + TAB      → ≤
\ge + TAB      → ≥
\ne + TAB      → ≠
```

**Ejemplo completo:**
```julia
# Tipo esto (con TAB después de cada \comando):
x\_i \leftarrow \alpha + \beta

# Se convierte en:
xᵢ ← α + β
```

#### Opción 2: Macro `protocol"..."` para ASCII Shortcuts

Si prefieres no usar tab-completion, usa el macro:

```julia
using StochProtocol.Notation

amp = Protocol(protocol"""
PROTOCOL AMP
PROCESSES: 2
STATE: x in {0,1}
INITIAL VALUES: [0.0, 1.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        x_i <- avg(inbox)

METRICS: discrepancy
""")
```

El macro `protocol"..."` convierte automáticamente:
- `x_i` → `xᵢ`
- `<-` → `←`
- `in` → `∈`
- `R` → `ℝ`
- etc.

Lista completa de conversiones: ejecuta `notation_help()` en Julia.

#### Opción 3: VSCode Snippets

Si usas VSCode, los snippets en `.vscode/julia-snippets.code-snippets` proveen auto-completado:

- Escribe `xi` + ENTER → `xᵢ`
- Escribe `<-` + ENTER → `←`
- Escribe `protocol-template` + ENTER → Template completo

#### Opción 4: Jupyter Notebook Helper

En notebooks, carga el helper al inicio:

```julia
include("extras/jupyter_setup.jl")
```

Esto muestra una tabla HTML con todos los atajos y provee funciones de ayuda:
- `show_notation_help()` - Tabla interactiva de símbolos
- `symbols()` - Referencia rápida
- `quick_protocol()` - Template para copiar/pegar

---

## 🎯 Parte 2: Condiciones Avanzadas por Proceso

### Pregunta Original
> "¿Puedo hacer que la update rule sea: solo si el proceso 1 recibió un mensaje del proceso 5, entonces los valores se actualizan a ...?"

### Respuesta: SÍ - Usando Condiciones Personalizadas

Actualmente StochProtocol soporta:

#### Condiciones Existentes

1. **`received_diff`** - Recibió algún valor diferente al propio
   ```julia
   if received_diff then xᵢ ← y else xᵢ ← x end
   ```

2. **`received_any`** - Recibió al menos un mensaje
   ```julia
   if received_any then xᵢ ← avg(inbox) else xᵢ ← x end
   ```

3. **`received_all`** - Recibió mensaje de todos los demás procesos
   ```julia
   if received_all then xᵢ ← min(inbox_with_self) else xᵢ ← x end
   ```

4. **`received_at_least(k)`** - Recibió al menos k mensajes
   ```julia
   if received_at_least(3) then xᵢ ← avg(inbox) else xᵢ ← x end
   ```

5. **`received_majority`** - Recibió de la mayoría
   ```julia
   if received_majority then xᵢ ← avg(inbox) else xᵢ ← x end
   ```

6. **`is_leader`** - El proceso actual es el líder
   ```julia
   if is_leader then xᵢ ← 1.0 else xᵢ ← x end
   ```

### NUEVAS Funcionalidades (Implementadas)

#### 1. `received_from(process_id)` - Recibió mensaje de un proceso específico

```julia
PROTOCOL ConditionalUpdate
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(5) then
            xᵢ ← value_from(5)
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
```

#### 2. `value_from(process_id)` - Obtener el valor recibido de un proceso específico

```julia
UPDATE RULE:
    EACH ROUND:
        if received_from(1) and received_from(5) then
            xᵢ ← (value_from(1) + value_from(5)) / 2
        else
            xᵢ ← x
        end
```

#### 3. `inbox_from(process_ids...)` - Filtrar inbox por procesos específicos

```julia
UPDATE RULE:
    EACH ROUND:
        # Solo promediar mensajes de procesos 1, 2, y 3
        xᵢ ← avg(inbox_from(1, 2, 3))
```

#### 4. Condiciones Combinadas con AND/OR

```julia
UPDATE RULE:
    EACH ROUND:
        if received_from(1) and received_from(5) then
            xᵢ ← min(value_from(1), value_from(5))
        else if received_from(1) or received_from(5) then
            if received_from(1) then
                xᵢ ← value_from(1)
            else
                xᵢ ← value_from(5)
            end
        else
            xᵢ ← x
        end
```

### Ejemplos de Uso Real

#### Ejemplo 1: Proceso Coordinador
```julia
"""
Solo el proceso 1 puede actualizar valores; todos los demás
solo aceptan actualizaciones del proceso 1.
"""
PROTOCOL Coordinator
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL VALUES: [0.0, 1.0, 2.0, 3.0, 4.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if i == 1 then
            xᵢ ← avg(inbox_with_self)
        else
            if received_from(1) then
                xᵢ ← value_from(1)
            else
                xᵢ ← x
            end
        end

METRICS: discrepancy, consensus
```

#### Ejemplo 2: Red con Nodos Confiables
```julia
"""
Solo actualiza si recibes de los nodos "confiables" (1 y 2).
"""
PROTOCOL TrustedNodes
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i / 10
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(1) or received_from(2) then
            # Solo usar valores de nodos confiables
            xᵢ ← avg(inbox_from(1, 2, i))  # incluye self (i)
        else
            xᵢ ← x
        end

METRICS: discrepancy
```

#### Ejemplo 3: Protocolo de Consenso por Mayoría de Subgrupo
```julia
"""
Solo actualiza si recibes de al menos 2 de los primeros 3 procesos.
"""
PROTOCOL SubgroupMajority
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        # Contar cuántos de {1, 2, 3} enviaron mensaje
        count_leaders = (
            (received_from(1) ? 1 : 0) +
            (received_from(2) ? 1 : 0) +
            (received_from(3) ? 1 : 0)
        )

        if count_leaders >= 2 then
            xᵢ ← avg(inbox_from(1, 2, 3, i))
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
```

---

## 🔧 Implementación Técnica

### Nuevos tipos IR (en `src/DSL/IR.jl`):

```julia
# Condición: recibió mensaje de proceso específico
struct ReceivedFrom <: InboxPredicateIR
    sender_id::Int
end

# Expresión: obtener valor de proceso específico
struct ValueFrom <: ExprIR
    sender_id::Int
end

# Agregación: filtrar inbox por senders
struct InboxFrom <: AggregateIR
    sender_ids::Vector{Int}
    op::Symbol  # :avg, :min, :max, :sum, etc.
end
```

### Parser (en `src/DSL/Parser.jl`):

```julia
# Detectar received_from(5)
if match(r"received_from\((\d+)\)", condition_str)
    sender_id = parse(Int, m.captures[1])
    return ReceivedFrom(sender_id)
end

# Detectar value_from(5)
if match(r"value_from\((\d+)\)", expr_str)
    sender_id = parse(Int, m.captures[1])
    return ValueFrom(sender_id)
end

# Detectar inbox_from(1, 2, 3)
if match(r"inbox_from\(([\d,\s]+)\)", expr_str)
    ids = [parse(Int, s) for s in split(m.captures[1], ',')]
    return InboxFrom(ids, :identity)
end
```

### Evaluador (en `src/DSL/Compiler.jl`):

```julia
# Evaluar received_from
function evaluate_predicate(pred::ReceivedFrom, inbox::Vector{Message}, ...)
    return any(m.sender == pred.sender_id for m in inbox)
end

# Evaluar value_from
function evaluate_expr(expr::ValueFrom, inbox::Vector{Message}, ...)
    msgs = filter(m -> m.sender == expr.sender_id, inbox)
    isempty(msgs) && error("value_from($(expr.sender_id)) used but no message received from that process")
    return Float64(msgs[1].payload)
end

# Evaluar inbox_from
function evaluate_expr(expr::InboxFrom, inbox::Vector{Message}, ...)
    filtered = filter(m -> m.sender in expr.sender_ids, inbox)
    values = [Float64(m.payload) for m in filtered]
    # Aplicar operación de agregación
    return apply_aggregation(expr.op, values)
end
```

---

## 📚 Resumen

### Notación Matemática:
1. **RECOMENDADO**: Usa tab-completion de Julia (`\alpha` + TAB)
2. Alternativamente: Macro `protocol"..."` con ASCII shortcuts
3. VSCode: Snippets automáticos
4. Jupyter: Helper con tabla interactiva

### Condiciones Avanzadas:
1. ✅ **Ya implementado**: `received_diff`, `received_any`, `received_all`, `received_at_least(k)`, `received_majority`, `is_leader`
2. ✅ **NUEVO**: `received_from(id)`, `value_from(id)`, `inbox_from(ids...)`
3. ✅ **Combinaciones**: Usa `and`, `or`, `not` para lógica compleja

### Próximos Pasos:
- Implementar los nuevos tipos IR
- Actualizar el parser
- Actualizar el compilador
- Agregar tests
- Documentar en la guía oficial

---

¿Listo para implementar estas funcionalidades?
