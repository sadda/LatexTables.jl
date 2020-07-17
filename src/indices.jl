struct All <: Indices end

struct Cells <: Indices
    inds::Vector{<:CartesianIndex}
end

Cells(inds::Tuple{Int, Int}...) = Cells([CartesianIndex.(inds)...])

struct Rows <: Indices
    inds::Vector{<:Int}
end

Rows(ind::Int) = Rows([ind])
Rows(inds::Int...) = Rows([inds...])

struct Cols <: Indices
    inds::Vector{<:Int}
end

Cols(ind::Int) = Cols([ind])
Cols(inds::Int...) = Cols([inds...])



function setstyle!(c::Cell, args::LatexStyle...)
    for arg in args
        setstyle!(c.style, arg)
    end
end


function setstyle!(d::Dict{Symbol,LatexStyle}, s::LatexStyle)
    d[Symbol(lowercase(string(typeof(s))))] = s
end


function setstyle!(M::CellArray, args::LatexStyle...)
    for cell in M
        setstyle!(cell, args...)
    end
end


setstyle!(M::CellMatrix, r::All, args::LatexStyle...) = setstyle!(M, args...)
setstyle!(M::CellMatrix, r::Cells, args::LatexStyle...) = @views setstyle!(M[r.inds], args...)
setstyle!(M::CellMatrix, r::Rows, args::LatexStyle...) = @views setstyle!(M[r.inds, :], args...)
setstyle!(M::CellMatrix, r::Cols, args::LatexStyle...) = @views setstyle!(M[:, r.inds], args...)