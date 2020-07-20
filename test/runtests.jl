using LatexTables
using Test

body  = reshape(["v", 1, 2, 3], 1, :)
n_row = size(body)[1]

run_finished(s::String) = return true

@testset "Introduction" begin
    @test_throws Exception error("Kdo testuje, neveri koderum.")
end

@testset "Highlighting" begin
    @test_throws Exception table_to_tex(body; highlight_max_row=true, highlight_max_col=true)
    @test_throws Exception table_to_tex(body; highlight_min_row=true, highlight_min_col=true)
    @test run_finished(table_to_tex(body; highlight_max_row=true, highlight_max_style=Color(:blue)))
    @test run_finished(table_to_tex(body; highlight_max_row=true, highlight_max_style=[Color(:blue), Style(:italic), CellColor(:red)]))
    @test run_finished(table_to_tex(body; highlight_min_row=true, highlight_min_style=Color(:blue)))
    @test run_finished(table_to_tex(body; highlight_min_row=true, highlight_min_style=[Color(:blue), Style(:italic), CellColor(:red)]))
end

@testset "Types" begin
    @test_throws Exception table_to_tex(body; col_format=["", "a"])
    @test run_finished(table_to_tex(body; col_format=["s", "3f", "2d", 'd']))
end

@testset "Leading col" begin
    @test run_finished(table_to_tex(body; leading_col=repeat(["1"], n_row), alignment=""))
    @test run_finished(table_to_tex(body; leading_col=repeat([1], n_row), alignment='l'))
    @test run_finished(table_to_tex(body; leading_col=repeat(["1"], n_row), alignment="l"))
    @test run_finished(table_to_tex(body; leading_col=repeat([1], n_row), alignment="llll"))
    @test run_finished(table_to_tex(body; leading_col=repeat(["1"], n_row), alignment="lllll"))
end
