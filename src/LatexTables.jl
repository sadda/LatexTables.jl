module LatexTables

using Parameters, Formatting

export Cell, setstyle!, Color, Size, Format, Prefix, Suffix,
        apply, Table, Tabular, Cells, Rows, Cols, All, table_to_tex


abstract type LatexStyle end
abstract type Indices end

Base.show(io::IO, s::LatexStyle) = print(io, s.val)

@with_kw_noshow mutable struct Cell{T}
    val::T
    style::Dict{Symbol, LatexStyle} = Dict{Symbol, LatexStyle}() 
end

Cell(val; kwargs...) = Cell(; val = val, kwargs...)


function Base.show(io::IO, c::Cell)
    col = get(c.style, :color, Color(:default))
    fmt = get(c.style, :format, Format())
    printstyled(io, format(c.val; fmt.val...); color = col.val)
end


const CellMatrix = AbstractMatrix{<:Cell}
const CellArray = AbstractArray{<:Cell}


include("cellstyles.jl")
include("indices.jl")


@with_kw mutable struct Table
    position::String = "!ht"
    caption::String = ""
    label::String = ""
    centering::Bool = true
end

function apply(t::Table, x::String)
    rows = String[]
    push!(rows, string("\\begin{table}[", t.position,"] \n"))
    isempty(t.caption) || push!(rows, string("\\caption{", t.caption, "} \n"))
    isempty(t.label) || push!(rows, string("\\label{", t.label, "} \n"))
    t.centering && push!(rows, "\\centering \n")
    push!(rows, x)
    push!(rows, "\\end{table} \n")
    return reduce(string, rows)
end


function table_to_tex(body::AbstractMatrix,
                      formats::Pair...;
                      table = Table(),
                      header = [],
                      alignment = [])
    
    s_body = size(body)

    body_cells = Cell.(body)
    for (inds, style) in formats
        setstyle!(body_cells, inds, style...)
    end

    if isempty(header)
        header_cells = header
    elseif isa(header, AbstractVector) && length(header) == s_body[2]
        header_cells = Cell.(reshape(header, 1, :))
    elseif isa(header, AbstractMatrix) && size(header,2) == s_body[2]
        header_cells = Cell.(header)
    else
        throw(ArgumentError("wrong header"))
    end

    if isempty(alignment)
        align = fill("l", s_body[2])
    elseif isa(header, AbstractVector) && length(alignment) == s_body[2]
        align = alignment
    else
        throw(ArgumentError("wrong alignment"))
    end

    rows = String[]
    push!(rows, string("\\begin{tabular}[@{} ", align...," @{}] \n"))
    push!(rows, "\\toprule \n")
    if !isempty(header_cells)
        push!(rows, apply(header_cells))
        push!(rows, "\\midrule \n")
    end
    push!(rows, apply(body_cells))
    push!(rows, "\\bottomrule \n")
    push!(rows, "\\end{tabular} \n")

    tex_table = apply(table, reduce(string, rows))
    print(tex_table)

    return tex_table
end

end
