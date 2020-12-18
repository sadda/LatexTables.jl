module LatexTables

using Parameters, Formatting

export Cell, setstyle!, Format, Style, Color, CellColor,
        apply, Table, Tabular, Cells, Rows, Cols, All, table_to_tex, make_tex_file

abstract type LatexStyle end
abstract type Indices end


mutable struct Cell{T}
    val::T
    style::Dict{Symbol, LatexStyle}

    Cell(val::T, style) where T = new{T}(val, convert(Dict{Symbol, LatexStyle}, style))
end

Cell(val) = Cell(val, Dict())
Cell(val::Real) = Cell(val, Dict(:format => Format("3f")))
Cell(val::String) = Cell(val, Dict(:format => Format('s')))


Base.show(io::IO, c::Cell) = show(io, c.val)


const CellMatrix = AbstractMatrix{<:Cell}
const CellArray = AbstractArray{<:Cell}


include("cellstyles.jl")
include("utilities.jl")


function create_table_top!(rows;
               position::String = "!ht",
               caption::String = "",
               label::String = "",
               centering::Bool = true,
               caption_position_top::Bool = true)

    push!(rows, string("\\begin{table}[", position,"] \n"))
    centering && push!(rows, "\\centering \n")
    (caption_position_top && !isempty(caption)) && push!(rows, string("\\caption{", caption, "} \n"))
    (caption_position_top && !isempty(label)) && push!(rows, string("\\label{", label, "} \n"))
end


function find_first_lrc(s::String)

    ii = findfirst.(['l', 'r', 'c'], s)
    minimum(ii[isa.(ii, Number)])
end


function create_table_mid!(rows, body_cells;
                           leading_col = [],
                           header = [],
                           alignment = [],
                           table_type = :booktabs)

    n_row, n_col = size(body_cells)

    if !isempty(leading_col)
        length(leading_col) != n_row && throw(ArgumentError("Wrong leading column size"))
        n_col_mod = n_col + 1
    else
        n_col_mod = n_col
    end

    if isempty(alignment)
        align = "l"^n_col_mod
    elseif length(alignment) == 1 && isempty(leading_col)
        align = alignment^n_col_mod
    elseif length(alignment) == 1 && !isempty(leading_col)
        align = "l" * alignment^(n_col_mod-1)
    elseif length(alignment) == n_col && !isempty(leading_col)
        ii    = find_first_lrc(alignment)
        align = alignment[1:ii-1] * "l" * alignment[ii:end]
    elseif length(alignment) == n_col_mod
        align = alignment
    else
        throw(ArgumentError("Wrong alignment size"))
    end

    if isempty(header)
        header_cells = header
    elseif isa(header, AbstractVector) && length(header) == n_col_mod
        header_cells = Cell.(reshape(string.(header), 1, :))
    elseif isa(header, AbstractVector) && length(header) == n_col && !isempty(leading_col)
        header_cells = Cell.(hcat("", reshape(string.(header), 1, :)))
    elseif isa(header, AbstractMatrix) && size(header,2) == n_col_mod
        header_cells = Cell.(string.(header))
    elseif isa(header, AbstractMatrix) && size(header,2) == n_col && !isempty(leading_col)
        header_cells = Cell.(hcat(repeat([""],size(header,1),1), string.(header)))
    else
        throw(ArgumentError("Wrong header size"))
    end

    if table_type == :booktabs
        push!(rows, string("\\begin{tabular}{@{} ", align...," @{}} \n"))
        push!(rows, "\\toprule \n")
        if !isempty(header_cells)
            push!(rows, apply(header_cells))
            table_type == :booktabs && push!(rows, "\\midrule \n")
        end
        for i in 1:n_row
            add_row = apply(body_cells[i,:])
            isempty(leading_col) ? push!(rows, add_row) : push!(rows, string(leading_col[i]) * " & " * add_row)
        end
        push!(rows, "\\bottomrule \n")
    elseif table_type == :tabular
        push!(rows, string("\\begin{tabular}{@{} ", align...," @{}} \n"))
        push!(rows, "\\hline \n")
        if !isempty(header_cells)
            push!(rows, apply(header_cells))
            table_type == :booktabs && push!(rows, "\\hline \n")
        end
        for i in 1:n_row
            add_row = apply(body_cells[i,:])
            isempty(leading_col) ? push!(rows, add_row) : push!(rows, string(leading_col[i]) * " & " * add_row)
        end
        push!(rows, "\\hline \n")
    else
        throw(ArgumentError("Wrong table type"))
    end
    push!(rows, "\\end{tabular} \n")
end


function create_table_bot!(rows;
                           caption::String = "",
                           label::String = "",
                           caption_position_top::Bool = false)

    (!caption_position_top && !isempty(caption)) && push!(rows, string("\\caption{", caption, "} \n"))
    (!caption_position_top && !isempty(label)) && push!(rows, string("\\label{", label, "} \n"))
    push!(rows, "\\end{table} \n")
end


function table_to_tex(body::AbstractMatrix;
                      col_format = [],
                      row_format = [],
                      table_type = :booktabs,
                      leading_col = [],
                      header = [],
                      position = "!ht",
                      caption = "",
                      label = "",
                      centering = true,
                      alignment = "",
                      floating_table = true,
                      caption_position_top = true,
                      highlight_max_row = false,
                      highlight_min_row = false,
                      highlight_max_col = false,
                      highlight_min_col = false,
                      highlight_max_style = [CellColor(:green!50), Color(:blue), Style(:bold)],
                      highlight_min_style = Color(:orange),
                      other_rules = [],
                  )

    sum(highlight_max_col + highlight_max_row) > 1 && throw(ArgumentError("Both highlight_max_col and highlight_max_row are true"))
    sum(highlight_min_col + highlight_min_row) > 1 && throw(ArgumentError("Both highlight_min_col and highlight_min_row are true"))
    sum(!isempty(col_format) + !isempty(row_format)) > 1 && throw(ArgumentError("Too many formats specified"))

    rules = []

    n_row, n_col = size(body)

    add_rules_col_format!(rules, col_format, n_col)
    add_rules_row_format!(rules, row_format, n_row)

    highlight_max_col && add_rules_max_col!(rules, body, highlight_max_style)
    highlight_min_col && add_rules_min_col!(rules, body, highlight_min_style)
    highlight_max_row && add_rules_max_row!(rules, body, highlight_max_style)
    highlight_min_row && add_rules_min_row!(rules, body, highlight_min_style)

    [push!(rules, rule) for rule in other_rules]

    body_cells = Cell.(body)

    for (inds, style) in rules
        setstyle!(body_cells, inds, style...)
    end

    rows = String[]
    floating_table && create_table_top!(rows; position=position, caption=caption, label=label, centering=centering, caption_position_top=caption_position_top)
    create_table_mid!(rows, body_cells; leading_col=leading_col, header=header, alignment=alignment, table_type=table_type)
    floating_table && create_table_bot!(rows; caption=caption, label=label, caption_position_top=caption_position_top)

    return reduce(string, rows)
end


function add_rules_col_format!(rules, col_format, n_col)

    if !isempty(col_format)
        col_format = repeat_n(col_format, n_col)
        for i in 1:n_col
            if !isempty(col_format[i])
                push!(rules, Cols(i) => (Format(col_format[i]),))
            end
        end
    end
end


function add_rules_row_format!(rules, row_format, n_row)

    if !isempty(row_format)
        row_format = repeat_n(row_format, n_row)
        for i in 1:n_row
            if !isempty(row_format[i])
                push!(rules, Rows(i) => (Format(row_format[i]),))
            end
        end
    end
end


add_rules_max_col!(rules, body, highlight_style::AbstractVector) = add_rules_max_col!.([rules], [body], highlight_style)
add_rules_min_col!(rules, body, highlight_style::AbstractVector) = add_rules_min_col!.([rules], [body], highlight_style)
add_rules_max_row!(rules, body, highlight_style::AbstractVector) = add_rules_max_row!.([rules], [body], highlight_style)
add_rules_min_row!(rules, body, highlight_style::AbstractVector) = add_rules_min_row!.([rules], [body], highlight_style)
add_rules_max_col!(rules, body, highlight_style::LatexStyle) = add_rules_minmax_col!(rules, body, highlight_style, true)
add_rules_min_col!(rules, body, highlight_style::LatexStyle) = add_rules_minmax_col!(rules, body, highlight_style, false)
add_rules_max_row!(rules, body, highlight_style::LatexStyle) = add_rules_minmax_row!(rules, body, highlight_style, true)
add_rules_min_row!(rules, body, highlight_style::LatexStyle) = add_rules_minmax_row!(rules, body, highlight_style, false)


function add_rules_minmax_col!(rules, body, highlight_style::LatexStyle, find_max::Bool)

    for i in 1:size(body,2)
        i_red = findall(isa.(body[:,i], Number))
        if !isempty(i_red)
            x_ext = find_max ? maximum(body[i_red,i]) : minimum(body[i_red,i])
            i_ext = findall(body[i_red,i] .== x_ext)
            for j in 1:length(i_ext)
                push!(rules, Cells((i_red[i_ext[j]],i)) => (highlight_style,))
            end
        end
    end
end


function add_rules_minmax_row!(rules, body, highlight_style::LatexStyle, find_max::Bool)

    for i in 1:size(body,1)
        i_red = findall(isa.(body[i,:], Number))
        if !isempty(i_red)
            x_ext = find_max ? maximum(body[i,i_red]) : minimum(body[i,i_red])
            i_ext = findall(body[i,i_red] .== x_ext)
            for j in 1:length(i_ext)
                push!(rules, Cells((i,i_red[i_ext[j]])) => (highlight_style,))
            end
        end
    end
end


repeat_n(x::String, n) = repeat([x], n)
repeat_n(x::AbstractVector, n) = x


end
