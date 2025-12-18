module Parser

using ..IR: ProtocolIR, IfReceivedDiffIR, SelfValue, MeetingPoint, ReceivedOtherValue, SimpleOpIR, UpdateIR, ExprIR, UpdatePhaseIR, InboxPredicateIR, ReceivedAny, ReceivedDiffIR, ReceivedAll, ReceivedAtLeast, ReceivedMajority, ConditionalIR, ConditionalElseIR, IsLeaderPredicate, AssignIR, VarIR, IndexedVarIR, LiteralIR, BinOpIR, AggregateIR, ComparisonIR, LogicalOpIR, DeliveryModelSpec, ReceivedFrom, ValueFrom, FilteredAggregateIR

# Parsing utilities for the paper-like DSL. The parser is a small, explicit
# state machine over the expected sections to keep error messages friendly.

const SUPPORTED_SIMPLE_OPS = [:average, :min, :max, :midpoint]
const SUPPORTED_METRICS = [:discrepancy, :consensus]

"""
Parse a `.protocol` file into a `ProtocolIR`. Errors are reported with line
numbers and clear expectations, without exposing Julia stack traces.
"""
function parse_protocol_file(path::String)::ProtocolIR
    lines = readlines(path)
    stripped = [(i, String(strip(l))) for (i, l) in enumerate(lines)]
    return parse_protocol_file_lines(stripped)
end

# -- helpers ---------------------------------------------------------------

function parse_state_var(line::AbstractString, line_no::Int)
    # Accept patterns like "x ∈ ℝ" or simply "x".
    parts = split(line)
    isempty(parts) && error("Error on line $line_no: expected a state variable declaration")
    var_raw = parts[1]
    base = replace(var_raw, "ᵢ" => "")  # drop subscript notation if present
    base == "" && error("Error on line $line_no: invalid state variable name")
    return Symbol(base)
end

function parse_initial(line::AbstractString, line_no::Int, state_var::Symbol)
    m = match(r"^(\S+)\s*=\s*(.+)$", line)
    m === nothing && error("Error in INITIAL (line $line_no): expected '<var> = <expression>'")
    lhs = m.captures[1]
    rhs = m.captures[2]
    lhs_var = Symbol(replace(lhs, "ᵢ" => ""))
    lhs_var == state_var || error("Error in INITIAL (line $line_no): only one state variable '$state_var' is allowed")
    expr = try
        Meta.parse("i -> ($(rhs))")
    catch
        error("Error in INITIAL (line $line_no): could not parse expression '$rhs'")
    end
    # Build a numeric initializer i -> value, using invokelatest to avoid world-age issues.
    fn = try
        eval(expr)
    catch
        error("Error in INITIAL (line $line_no): failed to build initializer from '$rhs'")
    end
    init_rule = function (i::Int)
        val = Base.invokelatest(fn, i)
        val isa Number || error("Error in INITIAL (line $line_no): initializer must be numeric")
        return Float64(val)
    end
    # Validate numeric output on a sample input.
    _ = try
        init_rule(1)
    catch
        error("Error in INITIAL (line $line_no): initializer must be a numeric expression in 'i'")
    end
    return init_rule
end

function parse_initial_values(line::AbstractString, line_no::Int, num_processes::Int)
    m = match(r"^\[(.*)\]\s*$", line)
    m === nothing && error("Error in INITIAL VALUES (line $line_no): expected a list like [v1, v2, ...]")
    body = m.captures[1]
    parts = split(body, ',')
    values = Float64[]
    for p in parts
        val_str = strip(p)
        isempty(val_str) && continue
        push!(values, parse(Float64, val_str))
    end
    length(values) == num_processes || error("Error in INITIAL VALUES (line $line_no): expected $num_processes values, found $(length(values))")
    return values
end

function parse_channel(line::AbstractString, line_no::Int)
    if occursin("guarantee", lowercase(line))
        m = match(r"^stochastic\s*with\s*guarantee\s*(.+)$"i, lowercase(line))
        m === nothing && error("Error in CHANNEL (line $line_no): expected 'stochastic with guarantee ...'")
        graw = strip(m.captures[1])
        if graw == "at_least(1)"
            return (:Bernoulli, :at_least_one)
        elseif graw == "majority"
            return (:Bernoulli, :majority)
        else
            error("Unknown channel guarantee on line $line_no")
        end
    else
        return (:Bernoulli, :none)
    end
end

function extract_rhs(line::AbstractString)
    m = match(r"←\s*(.+)$", line)
    m === nothing && (m = match(r"<-\s*(.+)$", line))
    return m === nothing ? strip(line) : strip(m.captures[1])
end

function parse_update(line::AbstractString, line_no::Int)::UpdateIR
    rhs = extract_rhs(line)
    lower = lowercase(rhs)
    if occursin("if_received_diff_then", lower)
        m = match(r"if_received_diff_then\s*\((.*)\)\s*$"i, rhs)
        m === nothing && error("Error in UPDATE RULE (line $line_no): expected IF_RECEIVED_DIFF_THEN(<then>, <else>)")
        args_str = m.captures[1]
        parts = split(args_str, ',')
        length(parts) == 2 || error("Error in UPDATE RULE (line $line_no): IF_RECEIVED_DIFF_THEN needs two arguments")
        then_expr = parse_expr(parts[1], line_no)
        else_expr = parse_expr(parts[2], line_no)
        return IfReceivedDiffIR(then_expr, else_expr)
    end
    # Handle explicit assignment lhs <- rhs
    if occursin("←", line) || occursin("<-", line)
        parts = split(line, ['←', '<', '-'])
        length(parts) < 2 && error("Error in UPDATE RULE (line $line_no): malformed assignment")
        lhs_token = strip(parts[1])
        rhs_token = extract_rhs(line)
        target = parse_indexed_lhs(lhs_token, line_no)
        expr = parse_expr(rhs_token, line_no)
        return AssignIR(target, expr)
    end
    # Direct assignment to an expression (e.g., y, self) when no lhs was parsed.
    try
        expr = parse_expr(rhs, line_no)
        return AssignIR(VarIR(:x), expr)
    catch
        # Fallback simple operator for backward compatibility (average/min/max/midpoint).
        op_match = match(r"([A-Za-z]+)\s*\(", rhs)
        op_match === nothing && error("Error in UPDATE RULE (line $line_no): unsupported rule syntax")
        op_str = lowercase(op_match.captures[1])
        op_sym = Symbol(op_str)
        op_sym in SUPPORTED_SIMPLE_OPS || error("Error in UPDATE RULE (line $line_no): operator '$op_str' is not supported.")
        return SimpleOpIR(op_sym)
    end
end

function parse_expr(text::AbstractString, line_no::Int)::ExprIR
    t = strip(text)
    t_lower = lowercase(t)

    # Try to parse as numeric literal first
    if occursin(r"^-?\d+\.?\d*$", t)
        return LiteralIR(parse(Float64, t))
    end

    # Binary operations: handle +, -, *, / with proper precedence
    # Check this BEFORE aggregations since aggregations might be part of a binary expr
    if occursin(r"[\+\-\*\/]", t)
        return parse_binary_expr(t, line_no)
    end

    # Aggregation functions: sum(...), avg(...), min(...), max(...), count(...)
    if occursin(r"^(sum|avg|min|max|count)\s*\(", t_lower)
        return parse_aggregate(t, line_no)
    end

    # value_from(process_id)
    if startswith(t_lower, "value_from")
        m = match(r"value_from\((\d+)\)", t_lower)
        m === nothing && error("Error in UPDATE RULE (line $line_no): value_from requires process ID (integer)")
        return ValueFrom(parse(Int, m.captures[1]))
    end

    # Parenthesized expressions
    if startswith(t, "(") && endswith(t, ")")
        return parse_expr(t[2:end-1], line_no)
    end

    # Simple expressions (existing)
    if t_lower == "xᵢ" || t_lower == "x" || t_lower == "self"
        return SelfValue()
    elseif t_lower == "x_i" || t_lower == "x[i]"
        return IndexedVarIR(:x, :self)
    elseif occursin("received_other", t_lower)
        m = match(r"received_other\(\s*x\s*\)", t_lower)
        m === nothing && error("Error in UPDATE RULE (line $line_no): expected received_other(x)")
        return ReceivedOtherValue()
    elseif occursin("received_diff", t_lower)
        m = match(r"received_diff\s*\(\s*(\w+)\s*\)", t_lower)
        return ReceivedDiffIR(m === nothing ? :x : Symbol(m.captures[1]))
    elseif occursin(r"^[a-zA-Z_][a-zA-Z0-9_]*$", t)
        # Valid identifier - treat as parameter/meeting point
        return MeetingPoint(Symbol(t))
    else
        error("Error in UPDATE RULE (line $line_no): expression '$text' is not supported")
    end
end

# Parse aggregation functions like sum(inbox), avg(inbox), etc.
function parse_aggregate(text::AbstractString, line_no::Int)::ExprIR
    t_lower = lowercase(strip(text))

    # Check for filtered aggregation: op(inbox_from(1, 2, 3))
    m_filtered = match(r"^(sum|avg|min|max|count)\s*\(\s*inbox_from\s*\(([\d,\s]+)\)\s*\)$", t_lower)
    if m_filtered !== nothing
        op = Symbol(m_filtered.captures[1])
        ids_str = m_filtered.captures[2]
        sender_ids = [parse(Int, strip(s)) for s in split(ids_str, ',')]
        return FilteredAggregateIR(op, sender_ids, false)  # include_self = false
    end

    # Match pattern: function_name(source)
    m = match(r"^(sum|avg|min|max|count)\s*\(\s*(\w+)\s*\)$", t_lower)
    m === nothing && error("Error in UPDATE RULE (line $line_no): invalid aggregation syntax '$text'")

    op = Symbol(m.captures[1])
    source_str = m.captures[2]

    # Determine source
    source = if source_str == "inbox"
        :inbox
    elseif source_str == "all" || source_str == "values"
        :inbox_with_self
    else
        error("Error in UPDATE RULE (line $line_no): unknown aggregation source '$source_str'. Use 'inbox' or 'all'")
    end

    return AggregateIR(op, source)
end

# Parse binary arithmetic expressions with precedence
function parse_binary_expr(text::AbstractString, line_no::Int)::ExprIR
    t = strip(text)

    # Remove outer parentheses if they wrap the entire expression
    if startswith(t, "(") && endswith(t, ")")
        inner_len = ncodeunits(t)
        if inner_len > 2
            inner_start = nextind(t, 1)
            inner_end = prevind(t, inner_len+1)
            inner = t[inner_start:inner_end]
            # Check if the opening paren at position 1 matches the closing paren at the end
            # by verifying that removing them still gives a balanced expression
            depth = 0
            is_outer = true
            for c in inner
                if c == '('
                    depth += 1
                elseif c == ')'
                    depth -= 1
                end
                if depth < 0
                    is_outer = false
                    break
                end
            end
            # If depth is 0 and never went negative, the outer parens are redundant
            if is_outer && depth == 0
                return parse_expr(inner, line_no)
            end
        end
    end

    # Convert to vector of characters for safe indexing
    chars = collect(t)
    n = length(chars)

    # Find operators with lowest precedence (+ and -) first
    # We scan from right to left to get left-associativity
    depth = 0
    for i in n:-1:1
        c = chars[i]
        if c == ')'
            depth += 1
        elseif c == '('
            depth -= 1
        elseif depth == 0 && (c == '+' || c == '-')
            # Found operator at top level
            left_str = strip(join(chars[1:i-1]))
            right_str = strip(join(chars[i+1:end]))
            isempty(left_str) && error("Error in UPDATE RULE (line $line_no): missing left operand for '$c'")
            isempty(right_str) && error("Error in UPDATE RULE (line $line_no): missing right operand for '$c'")

            left = parse_expr(left_str, line_no)
            right = parse_expr(right_str, line_no)
            op = c == '+' ? :add : :sub
            return BinOpIR(op, left, right)
        end
    end

    # If no + or -, look for * and /
    depth = 0
    for i in n:-1:1
        c = chars[i]
        if c == ')'
            depth += 1
        elseif c == '('
            depth -= 1
        elseif depth == 0 && (c == '*' || c == '/')
            left_str = strip(join(chars[1:i-1]))
            right_str = strip(join(chars[i+1:end]))
            isempty(left_str) && error("Error in UPDATE RULE (line $line_no): missing left operand for '$c'")
            isempty(right_str) && error("Error in UPDATE RULE (line $line_no): missing right operand for '$c'")

            left = parse_expr(left_str, line_no)
            right = parse_expr(right_str, line_no)
            op = c == '*' ? :mul : :div
            return BinOpIR(op, left, right)
        end
    end

    # No operator found at top level - this might be a simple expression
    # Fallback to parsing non-arithmetic expressions
    # Check for aggregations, literals, identifiers, etc.
    t_lower = lowercase(t)

    # Numeric literal
    if occursin(r"^-?\d+\.?\d*$", t)
        return LiteralIR(parse(Float64, t))
    end

    # Aggregation function
    if occursin(r"^(sum|avg|min|max|count)\s*\(", t_lower)
        return parse_aggregate(t, line_no)
    end

    # Simple variable/parameter references
    if t_lower == "xᵢ" || t_lower == "x" || t_lower == "self"
        return SelfValue()
    elseif t_lower == "x_i" || t_lower == "x[i]"
        return IndexedVarIR(:x, :self)
    elseif occursin("received_other", t_lower)
        m = match(r"received_other\(\s*x\s*\)", t_lower)
        m === nothing && error("Error in UPDATE RULE (line $line_no): expected received_other(x)")
        return ReceivedOtherValue()
    elseif occursin("received_diff", t_lower)
        m = match(r"received_diff\s*\(\s*(\w+)\s*\)", t_lower)
        return ReceivedDiffIR(m === nothing ? :x : Symbol(m.captures[1]))
    elseif occursin(r"^[a-zA-Z_][a-zA-Z0-9_]*$", t)
        return MeetingPoint(Symbol(t))
    else
        error("Error in UPDATE RULE (line $line_no): could not parse expression '$text'")
    end
end

# Helper to check if parentheses are balanced
function is_balanced_parens(text::AbstractString)::Bool
    depth = 0
    for c in text
        if c == '('
            depth += 1
        elseif c == ')'
            depth -= 1
            depth < 0 && return false
        end
    end
    return depth == 0
end

function parse_indexed_lhs(token::AbstractString, line_no::Int)
    tok = strip(String(token))
    if endswith(tok, "ᵢ")
        base = replace(tok, "ᵢ" => "")
        return IndexedVarIR(Symbol(base), :self)
    elseif occursin(r"_i$", tok)
        base = replace(tok, r"_i$" => "")
        return IndexedVarIR(Symbol(base), :self)
    elseif occursin(r"\[i\]$", tok)
        base = replace(tok, r"\[i\]$" => "")
        return IndexedVarIR(Symbol(base), :self)
    else
        return VarIR(Symbol(tok))
    end
end

function parse_parameter!(params::Dict{Symbol,Any}, line::AbstractString, line_no::Int)
    # Accept either the detailed form "param ∈ [min,max] = value" or the simpler "param = value".
    # Match: param_name ∈ [min,max] = value
    m = match(r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*∈?\s*\[[^\]]+\]\s*=\s*([0-9eE\.\+\-]+)\s*$", line)
    if m === nothing
        # Match: param_name = value
        m = match(r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([0-9eE\.\+\-]+)\s*$", line)
        m === nothing && error("Error in PARAMETERS (line $line_no): expected 'param ∈ [min,max] = <float>' or 'param = <float>'")
    end
    param_name = Symbol(m.captures[1])
    val = parse(Float64, m.captures[2])
    params[param_name] = val
end

function parse_metric(line::AbstractString, line_no::Int)
    sym = Symbol(lowercase(strip(line)))
    sym in SUPPORTED_METRICS || begin
        supported = join(string.(SUPPORTED_METRICS), ", ")
        error("Error in METRICS (line $line_no): metric '$sym' is not supported. Supported metrics: $supported.")
    end
    return sym
end

"""
Parse a MODEL declaration line.
Examples:
  - "standard"
  - "guaranteed k=3 scope=per_round"
  - "broadcast probability=per_source"
  - "process 2: broadcast"
"""
function parse_model(line::AbstractString, line_no::Int, num_processes::Int)::DeliveryModelSpec
    # Check for process-specific model: "process <id>: <model>"
    process_match = match(r"^process\s+(\d+):\s*(.+)$"i, line)
    if process_match !== nothing
        process_id = parse(Int, process_match.captures[1])
        if process_id < 1 || process_id > num_processes
            error("Error in MODEL (line $line_no): process ID $process_id out of range (1..$num_processes)")
        end
        model_str = strip(process_match.captures[2])
        return parse_model_spec(model_str, line_no, process_id)
    else
        # Global model
        return parse_model_spec(line, line_no, nothing)
    end
end

function parse_model_spec(model_str::AbstractString, line_no::Int, process_id::Union{Nothing,Int})
    model_str = strip(model_str)
    model_lower = lowercase(model_str)

    # Standard model
    if model_lower == "standard"
        return DeliveryModelSpec(:standard, Dict{Symbol,Any}(), process_id)
    end

    # Guaranteed model: "guaranteed k=3 scope=per_round"
    if startswith(model_lower, "guaranteed")
        params = Dict{Symbol,Any}()
        # Extract k parameter
        k_match = match(r"k\s*=\s*(\d+)", model_str)
        if k_match === nothing
            error("Error in MODEL (line $line_no): guaranteed model requires k=<number>")
        end
        params[:min_messages] = parse(Int, k_match.captures[1])

        # Extract scope parameter (optional, defaults to per_round)
        scope_match = match(r"scope\s*=\s*(\w+)", model_str)
        if scope_match !== nothing
            scope_str = lowercase(scope_match.captures[1])
            if scope_str == "per_round"
                params[:scope] = :per_round
            elseif scope_str == "total"
                params[:scope] = :total
            else
                error("Error in MODEL (line $line_no): scope must be 'per_round' or 'total', got '$scope_str'")
            end
        else
            params[:scope] = :per_round  # Default
        end

        return DeliveryModelSpec(:guaranteed, params, process_id)
    end

    # Broadcast model: "broadcast probability=per_source"
    if startswith(model_lower, "broadcast")
        params = Dict{Symbol,Any}()
        # Extract probability parameter (optional, defaults to per_source)
        prob_match = match(r"probability\s*=\s*(\w+)", model_str)
        if prob_match !== nothing
            prob_str = lowercase(prob_match.captures[1])
            if prob_str == "per_source"
                params[:probability] = :per_source
            elseif prob_str == "uniform"
                params[:probability] = :uniform
            else
                error("Error in MODEL (line $line_no): probability must be 'per_source' or 'uniform', got '$prob_str'")
            end
        else
            params[:probability] = :per_source  # Default
        end

        return DeliveryModelSpec(:broadcast, params, process_id)
    end

    error("Error in MODEL (line $line_no): unknown model type '$model_str'. Supported: standard, guaranteed, broadcast")
end

"""
Parse a protocol provided directly as text (e.g., in a notebook).
"""
function parse_protocol_text(text::String)::ProtocolIR
    # Be tolerant to leading BOM/blank lines when pasted from notebooks.
    cleaned = replace(text, r"^\ufeff" => "")
    cleaned = replace(cleaned, r"^\s*\n+" => "")
    lines = split(cleaned, '\n')
    stripped = [(i, String(strip(l))) for (i, l) in enumerate(lines)]
    return parse_protocol_file_lines(stripped)
end

"""
Core parsing given pre-stripped lines.
"""
function parse_protocol_file_lines(stripped)
    # Reuse existing logic by faking a temporary file read
    # (all functions downstream operate on `stripped`).
    # We place the main body in a let to avoid code duplication.
    return let
        idx = 1
        # The body of parse_protocol_file but using local `stripped`
        # (copied and slightly adapted).
        # PROTOCOL <name>
        function next_nonempty(start)
            n = length(stripped)
            i = start
            while i <= n && isempty(stripped[i][2])
                i += 1
            end
            return i
        end
        idx = next_nonempty(idx)
        idx > length(stripped) && error("Missing PROTOCOL declaration")
        line_no, line = stripped[idx]
        m = match(r"^PROTOCOL\s+(\S+)\s*$"i, line)
        m === nothing && error("Error on line $line_no: expected 'PROTOCOL <Name>'")
        protocol_name = String(m.captures[1])
        idx += 1

        # PROCESSES (or backward-compatible NODES)
        idx = next_nonempty(idx)
        idx > length(stripped) && error("Missing PROCESSES section")
        line_no, line = stripped[idx]
        m = match(r"^(PROCESSES|NODES):\s*(\d+)\s*$"i, line)
        m === nothing && error("Error on line $line_no: expected 'PROCESSES: <integer>'")
        num_processes = parse(Int, m.captures[2])
        idx += 1

        # STATE:
        idx = next_nonempty(idx)
        idx > length(stripped) && error("Missing STATE section")
        line_no, line = stripped[idx]
        startswith(line, "STATE") || error("Error on line $line_no: expected 'STATE:'")
        idx += 1
        idx = next_nonempty(idx)
        idx > length(stripped) && error("STATE section must declare a variable")
        state_line_no, state_line = stripped[idx]
        state_var = parse_state_var(state_line, state_line_no)
        idx += 1

        # PARAMETERS and INITIAL VALUES (order-tolerant)
        params = Dict{Symbol,Any}()
        init_values = nothing
        init_rule = nothing

        # Try to parse PARAMETERS and INITIAL VALUES in any order
        idx = next_nonempty(idx)
        for _ in 1:3  # Allow up to 3 sections (PARAMETERS, INITIAL VALUES, INITIAL)
            idx > length(stripped) && break
            current_line = stripped[idx][2]

            if startswith(current_line, "PARAMETERS")
                idx += 1
                idx = next_nonempty(idx)
                while idx <= length(stripped)
                    lno, l = stripped[idx]
                    isempty(l) && (idx += 1; continue)
                    occursin(":", l) && break
                    parse_parameter!(params, l, lno)
                    idx += 1
                end
                idx = next_nonempty(idx)
            elseif startswith(current_line, "INITIAL VALUES")  # Check this BEFORE "INITIAL"
                idx += 1
                idx = next_nonempty(idx)
                idx > length(stripped) && error("INITIAL VALUES section must include a list like [v1, v2, ...]")
                vals_line_no, vals_line = stripped[idx]
                init_values = parse_initial_values(vals_line, vals_line_no, num_processes)
                idx += 1
                idx = next_nonempty(idx)
            elseif startswith(current_line, "INITIAL") && !startswith(current_line, "INITIAL VALUES")
                idx += 1
                idx = next_nonempty(idx)
                idx > length(stripped) && error("INITIAL section must define an expression")
                init_line_no, init_line = stripped[idx]
                init_rule = parse_initial(init_line, init_line_no, state_var)
                idx += 1
                idx = next_nonempty(idx)
            else
                # Not a parameter or initial section, move on
                break
            end
        end

        # Validate that we have at least one initialization method
        if init_values === nothing && init_rule === nothing
            error("Missing INITIAL section; provide either INITIAL or INITIAL VALUES")
        end

        # CHANNEL and ROLES (order-tolerant: CHANNEL may appear before or after ROLES).
        leader_id = nothing
        idx = next_nonempty(idx)
        # If CHANNEL comes first
        if idx <= length(stripped) && startswith(stripped[idx][2], "CHANNEL")
            idx += 1
            idx = next_nonempty(idx)
            idx > length(stripped) && error("CHANNEL section must define a channel")
            channel_line_no, channel_line = stripped[idx]
            channel_type, channel_guarantee = parse_channel(channel_line, channel_line_no)
            channel_type == :Bernoulli || error("Only stochastic (Bernoulli) channel is supported in v1")
            if channel_guarantee == :majority && num_processes < 2
                error("Guarantee majority invalid for N < 2")
            end
            params[:channel_guarantee] = channel_guarantee
            idx += 1
            idx = next_nonempty(idx)
            if idx <= length(stripped) && startswith(stripped[idx][2], "ROLES")
                idx += 1
                idx = next_nonempty(idx)
                idx > length(stripped) && error("ROLES section must define a leader")
                leader_line_no, leader_line = stripped[idx]
                leader_id = parse_leader(leader_line, leader_line_no, num_processes)
                idx += 1
            end
        # Else if ROLES comes first, parse it then expect CHANNEL
        elseif idx <= length(stripped) && startswith(stripped[idx][2], "ROLES")
            idx += 1
            idx = next_nonempty(idx)
            idx > length(stripped) && error("ROLES section must define a leader")
            leader_line_no, leader_line = stripped[idx]
            leader_id = parse_leader(leader_line, leader_line_no, num_processes)
            idx += 1

            idx = next_nonempty(idx)
            idx > length(stripped) && error("Missing CHANNEL section")
            line_no, line = stripped[idx]
            startswith(line, "CHANNEL") || error("Error on line $line_no: expected 'CHANNEL:'")
            idx += 1
            idx = next_nonempty(idx)
            idx > length(stripped) && error("CHANNEL section must define a channel")
            channel_line_no, channel_line = stripped[idx]
            channel_type, channel_guarantee = parse_channel(channel_line, channel_line_no)
            channel_type == :Bernoulli || error("Only stochastic (Bernoulli) channel is supported in v1")
            if channel_guarantee == :majority && num_processes < 2
                error("Guarantee majority invalid for N < 2")
            end
            params[:channel_guarantee] = channel_guarantee
            idx += 1
        else
            # Default fallback: assume stochastic channel with no guarantee if the
            # CHANNEL block is omitted entirely.
            params[:channel_guarantee] = :none
            idx = next_nonempty(idx)
        end

        # MODEL (optional: communication delivery models)
        delivery_models = DeliveryModelSpec[]
        if idx <= length(stripped) && startswith(stripped[idx][2], "MODEL")
            idx += 1
            idx = next_nonempty(idx)
            while idx <= length(stripped)
                lno, l = stripped[idx]
                isempty(l) && (idx += 1; continue)
                # Stop if we hit a new section
                if occursin(":", l) && (startswith(l, "UPDATE") || startswith(l, "METRICS"))
                    break
                end
                push!(delivery_models, parse_model(l, lno, num_processes))
                idx += 1
            end
            idx = next_nonempty(idx)
        end

        # If no models specified, default to standard model globally
        if isempty(delivery_models)
            push!(delivery_models, DeliveryModelSpec(:standard, Dict{Symbol,Any}(), nothing))
        end

        # UPDATE RULE (optional: if absent, default to no-op phases).
        idx = next_nonempty(idx)
        phases = UpdatePhaseIR[]
        if idx <= length(stripped) && startswith(stripped[idx][2], "UPDATE RULE")
            idx += 1
            phases, idx = parse_phases(stripped, idx, num_processes)
        end

        # METRICS: optional; default to discrepancy/consensus if omitted.
        idx = next_nonempty(idx)
        metrics = Symbol[]
        if idx <= length(stripped) && startswith(stripped[idx][2], "METRICS")
            idx += 1
            while idx <= length(stripped)
                lno, l = stripped[idx]
                if isempty(l)
                    idx += 1
                    continue
                end
                if occursin(":", l)
                    break
                end
                push!(metrics, parse_metric(l, lno))
                idx += 1
            end
            isempty(metrics) && error("METRICS section must list at least one metric")
        else
            # Default metrics when block is missing.
            metrics = [:discrepancy, :consensus]
        end
        init_rule_final = init_rule === nothing ? i::Int -> error("No init_rule defined") : init_rule

        return ProtocolIR(protocol_name, num_processes, init_rule_final, init_values, phases, metrics, merge(params, Dict(:leader_id => leader_id)), delivery_models)
    end
end

function parse_phases(stripped, idx::Int, num_processes::Int)
    phases = UpdatePhaseIR[]
    seen_end = false
    n = length(stripped)
    while idx <= n
        line_no, line = stripped[idx]
        isempty(line) && (idx += 1; continue)
        startswith(line, "METRICS") && break
        if startswith(line, "EACH ROUND")
            recursive = occursin("RECURSIVE", line)
            idx += 1
            idx > n && error("EACH ROUND must include a rule on the next line")
            rule, idx = parse_phase_body(stripped, idx)
            push!(phases, UpdatePhaseIR(:each_round, recursive, rule, nothing))
        elseif startswith(line, "END")
            recursive = occursin("RECURSIVE", line)
            seen_end && error("Error on line $line_no: END phase already defined; only one END phase is allowed")
            idx += 1
            idx > n && error("END must include a rule on the next line")
            rule, idx = parse_phase_body(stripped, idx)
            push!(phases, UpdatePhaseIR(:end, recursive, rule, nothing))
            seen_end = true
        elseif startswith(line, "FIRST ROUND")
            idx += 1
            rule, idx = parse_phase_body(stripped, idx)
            push!(phases, UpdatePhaseIR(:first_round, false, rule, nothing))
        elseif startswith(line, "AFTER")
            m = match(r"AFTER\s+(\d+)\s+ROUNDS", line)
            m === nothing && error("Invalid temporal condition on line $line_no")
            t = parse(Int, m.captures[1])
            idx += 1
            rule, idx = parse_phase_body(stripped, idx)
            push!(phases, UpdatePhaseIR(:after_rounds, false, rule, t))
        elseif startswith(line, "UNTIL")
            occursin("consensus", lowercase(line)) || error("UNTIL only supports consensus in v1")
            idx += 1
            rule, idx = parse_phase_body(stripped, idx)
            push!(phases, UpdatePhaseIR(:until, false, rule, :consensus))
        else
            # Backward compatibility: a single rule without phase defaults to EACH ROUND.
            if startswith(lowercase(line), "if ")
                rule, idx = parse_phase_body(stripped, idx)
                push!(phases, UpdatePhaseIR(:each_round, false, rule, nothing))
            else
                rule = parse_update(line, line_no)
                push!(phases, UpdatePhaseIR(:each_round, false, rule, nothing))
                idx += 1
            end
            break
        end
    end
    return phases, idx
end

function parse_phase_body(stripped, idx::Int)
    n = length(stripped)
    idx > n && error("Phase body missing")
    line_no, line = stripped[idx]
    ln = strip(line)
    if startswith(lowercase(ln), "if ")
        pred = parse_predicate(ln, line_no)
        idx += 1
        idx > n && error("Conditional requires a rule after line $line_no")
        rule_line_no, rule_line = stripped[idx]
        rule = parse_update(rule_line, rule_line_no)
        idx += 1
        # Optional else branch
        else_rule = AssignIR(VarIR(:x), SelfValue())
        if idx <= n && lowercase(strip(stripped[idx][2])) == "else"
            idx += 1
            idx > n && error("Else branch requires a rule after line $(line_no)")
            else_line_no, else_line = stripped[idx]
            else_rule = parse_update(else_line, else_line_no)
            idx += 1
        end
        # Optional end
        if idx <= n && lowercase(strip(stripped[idx][2])) == "end"
            idx += 1
        end
        return ConditionalElseIR(pred, rule, else_rule), idx
    else
        rule = parse_update(line, line_no)
        idx += 1
        return rule, idx
    end
end

function parse_predicate(line::AbstractString, line_no::Int)::InboxPredicateIR
    l = lowercase(strip(line))
    m = match(r"if\s+(.*)\s+then", l)
    m === nothing && error("Invalid inbox predicate on line $line_no")
    body = strip(m.captures[1])

    # Parse the body as a predicate expression
    return parse_predicate_expr(body, line_no)
end

function parse_predicate_expr(text::AbstractString, line_no::Int)::InboxPredicateIR
    t = strip(text)

    # Handle NOT operator (highest precedence)
    if startswith(t, "not ")
        # Use nextind for safe Unicode indexing
        inner_start = nextind(t, 4)  # After "not "
        inner = strip(t[inner_start:end])
        return LogicalOpIR(:not, [parse_predicate_expr(inner, line_no)])
    end

    # Convert to character array for safe indexing
    chars = collect(t)
    n = length(chars)

    # Handle OR operator (lowest precedence) - scan for " or " outside parentheses
    depth = 0
    for i in 1:n-3
        c = chars[i]
        if c == '('
            depth += 1
        elseif c == ')'
            depth -= 1
        elseif depth == 0 && i+3 <= n && join(chars[i:i+3]) == " or "
            left = parse_predicate_expr(join(chars[1:i-1]), line_no)
            right = parse_predicate_expr(join(chars[i+4:end]), line_no)
            return LogicalOpIR(:or, [left, right])
        end
    end

    # Handle AND operator (medium precedence) - scan for " and " outside parentheses
    depth = 0
    for i in 1:n-4
        c = chars[i]
        if c == '('
            depth += 1
        elseif c == ')'
            depth -= 1
        elseif depth == 0 && i+4 <= n && join(chars[i:i+4]) == " and "
            left = parse_predicate_expr(join(chars[1:i-1]), line_no)
            right = parse_predicate_expr(join(chars[i+5:end]), line_no)
            return LogicalOpIR(:and, [left, right])
        end
    end

    # Handle comparison operators
    comp_ops = [
        (">=", :gte),
        ("<=", :lte),
        ("!=", :neq),
        ("==", :eq),
        (">", :gt),
        ("<", :lt)
    ]

    for (op_str, op_sym) in comp_ops
        op_len = length(op_str)
        depth = 0
        for i in 1:n-op_len+1
            c = chars[i]
            if c == '('
                depth += 1
            elseif c == ')'
                depth -= 1
            elseif depth == 0 && i+op_len-1 <= n && join(chars[i:i+op_len-1]) == op_str
                left_expr = parse_expr(join(chars[1:i-1]), line_no)
                right_expr = parse_expr(join(chars[i+op_len:end]), line_no)
                return ComparisonIR(op_sym, left_expr, right_expr)
            end
        end
    end

    # Handle existing simple predicates
    if t == "received_any(x)" || t == "received_any"
        return ReceivedAny()
    elseif t == "received_diff(x)" || t == "received_diff"
        return ReceivedDiffIR(:x)
    elseif t == "received_all(x)" || t == "received_all"
        return ReceivedAll()
    elseif startswith(t, "received_at_least")
        m2 = match(r"received_at_least\((\d+)", t)
        m2 === nothing && error("received_at_least requires integer literal on line $line_no")
        return ReceivedAtLeast(parse(Int, m2.captures[1]))
    elseif t == "received_majority(x)" || t == "received_majority"
        return ReceivedMajority()
    elseif t == "self is leader"
        return IsLeaderPredicate()
    elseif startswith(t, "received_from")
        m2 = match(r"received_from\((\d+)\)", t)
        m2 === nothing && error("received_from requires process ID (integer) on line $line_no")
        return ReceivedFrom(parse(Int, m2.captures[1]))
    else
        error("Invalid inbox predicate '$t' on line $line_no")
    end
end

function parse_leader(line::AbstractString, line_no::Int, num_processes::Int)
    m = match(r"leader\s*=\s*(\d+)", lowercase(line))
    m === nothing && error("Error in ROLES (line $line_no): expected 'leader = <int>'")
    lid = parse(Int, m.captures[1])
    (1 <= lid <= num_processes) || error("Error in ROLES (line $line_no): leader must be between 1 and $num_processes")
    return lid
end

end
