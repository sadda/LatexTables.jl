module LatexTables

using Parameters, Formatting

export Cell, setstyle!, Color, Size, Format, Prefix, Suffix,
        apply, Table, Tabular, Cells, Rows, Cols, All, table_to_tex


abstract type LatexStyle end
abstract type Indices end


@with_kw_noshow mutable struct Cell{T}
    val::T
    style::Dict{Symbol, LatexStyle} = Dict{Symbol, LatexStyle}()
end


function Cell(val::Real)
    c = Cell(; val = val)
    setstyle!(c, Format("3f"))
    return c
end


function Cell(val::String)
    c = Cell(; val = val)
    setstyle!(c, Format('s'))
    return c
end


function Base.show(io::IO, c::Cell)
    col = get(c.style, :color, Color(:default))
    fmt = get(c.style, :format, Format())
    printstyled(io, format(c.val; fmt.val...); color = col.val)
end


const CellMatrix = AbstractMatrix{<:Cell}
const CellArray = AbstractArray{<:Cell}


include("cellstyles.jl")
include("indices.jl")


function create_table_top!(rows;
               position::String = "!ht",
               caption::String = "",
               label::String = "",
               centering::Bool = true,
               caption_top::Bool = true)

    push!(rows, string("\\begin{table}[", position,"] \n"))
    centering && push!(rows, "\\centering \n")
    (caption_top && !isempty(caption)) && push!(rows, string("\\caption{", caption, "} \n"))
    (caption_top && !isempty(label)) && push!(rows, string("\\label{", label, "} \n"))
end


function create_table_mid!(rows, body_cells;
                           header=[],
                           alignment=[])

    n_row, n_col = size(body_cells)

    if isempty(header)
        header_cells = header
    elseif isa(header, AbstractVector) && length(header) == n_col
        header_cells = Cell.(reshape(header, 1, :))
    elseif isa(header, AbstractMatrix) && size(header,2) == n_row
        header_cells = Cell.(header)
    else
        throw(ArgumentError("wrong header"))
    end

    if isempty(alignment)
        align = fill("l", n_col)
    elseif isa(header, AbstractVector) && length(alignment) == n_col
        align = alignment
    else
        throw(ArgumentError("wrong alignment"))
    end

    push!(rows, string("\\begin{tabular}[@{} ", align...," @{}] \n"))
    push!(rows, "\\toprule \n")
    if !isempty(header_cells)
        push!(rows, apply(header_cells))
        push!(rows, "\\midrule \n")
    end
    push!(rows, apply(body_cells))
    push!(rows, "\\bottomrule \n")
    push!(rows, "\\end{tabular} \n")
end


function create_table_bot!(rows;
                           caption::String = "",
                           label::String = "",
                           caption_top::Bool = false)

    (!caption_top && !isempty(caption)) && push!(rows, string("\\caption{", caption, "} \n"))
    (!caption_top && !isempty(label)) && push!(rows, string("\\label{", label, "} \n"))
    push!(rows, "\\end{table} \n")
end


# TODO leading_col
# TODO table_type
# TODO check header, alignment
# TODO add cell color, bold, italic
function table_to_tex(body::AbstractMatrix;
                      col_format = [],
                      row_format = [],
                      max_row = false,
                      min_row = false,
                      max_col = false,
                      min_col = false,
                      table_type = :booktabs,
                      leading_col = [],
                      header = [],
                      caption_top = true
                      position = "!ht",
                      caption = "",
                      label = "",
                      centering = true,
                      alignment = "",
                      whole_table = true,
                      max_highlight_style = Color(:green)
                      min_highlight_style = Color(:blue)
                  )

    sum(max_col + max_row) > 1 && throw(ArgumentError("Both max_col and max_row are true"))
    sum(min_col + min_row) > 1 && throw(ArgumentError("Both min_col and min_row are true"))
    sum(!isempty(col_format) + !isempty(row_format)) > 1 && throw(ArgumentError("Too many formats specified"))

    rules = []

    n_row, n_col = size(body)

    add_rules_col_format!(rules, col_format, n_col)
    add_rules_row_format!(rules, row_format, n_row)

    max_col && add_rules_max_col!(rules, body, max_highlight_style)
    min_col && add_rules_min_col!(rules, body, min_highlight_style)
    max_row && add_rules_max_row!(rules, body, max_highlight_style)
    min_row && add_rules_min_row!(rules, body, min_highlight_style)

    body_cells = Cell.(body)

    for (inds, style) in rules
        setstyle!(body_cells, inds, style...)
    end

    rows = String[]
    whole_table && create_table_top!(rows; position=position, caption=caption, label=label, centering=centering, caption_top=caption_top)
    create_table_mid!(rows, body_cells)
    whole_table && create_table_bot!(rows; caption=caption, label=label, caption_top=caption_top)

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


function add_rules_max_col!(rules, body, highlight_style)

    for i in 1:size(body,2)
        x_ext = maximum(body[:,i])
        i_ext = findall(body[:,i] .== x_ext)
        for j in 1:length(i_ext)
            push!(rules, Cells((i_ext[j],i)) => (highlight_style,))
        end
    end
end


function add_rules_min_col!(rules, body, highlight_style)

    for i in 1:size(body,2)
        x_ext = minimum(body[:,i])
        i_ext = findall(body[:,i] .== x_ext)
        for j in 1:length(i_ext)
            push!(rules, Cells((i_ext[j],i)) => (highlight_style,))
        end
    end
end


function add_rules_max_row!(rules, body, highlight_style)

    for i in 1:size(body,1)
        x_ext = maximum(body[i,:])
        i_ext = findall(body[i,:] .== x_ext)
        for j in 1:length(i_ext)
            push!(rules, Cells((i,i_ext[j])) => (highlight_style,))
        end
    end
end


function add_rules_min_row!(rules, body, highlight_style)

    for i in 1:size(body,1)
        x_ext = minimum(body[i,:])
        i_ext = findall(body[i,:] .== x_ext)
        for j in 1:length(i_ext)
            push!(rules, Cells((i,i_ext[j])) => (highlight_style,))
        end
    end
end


repeat_n(x::String, n) = repeat([x], n)
repeat_n(x::AbstractVector, n) = x


end
