using LatexTables
using Test

body  = reshape(["v", 1, 2, 3], 1, :)
#body  = vcat(["v" 1 2 3],  ["a" 2 1 0.5])
n_row = size(body)[1]

run_finished(s::String) = return true
compare_strings(s1::String, s2::String) = remove_spaces(s1) == remove_spaces(s2)
compare_strings_rows(s1::String, s2::String) = split_string(s1) == split_string(s2)

function compare_strings_rows_subset(s1::String, s2::String)
    s1_spl = split_string(s1)
    s2_spl = split_string(s2)
    return is_subset(s1_spl, s2_spl) && !is_subset(s2_spl, s1_spl)
end

function compile_success(file_name, s::String)

    dir_name = "output"
    file_pdf = file_name * ".pdf"
    file_tex = file_name * ".tex"

    isfile(joinpath(dir_name, file_pdf)) && rm(joinpath(dir_name, file_pdf))

    make_tex_file(file_tex, s; dir_name=dir_name, compile=true)

    return isfile(joinpath(dir_name, file_pdf))
end


result1 = "\\begin{table}[!ht] \n\\centering \n\\caption{cap} \n\\label{lab} \n\\begin{tabular}{@{} llll @{}} \n\\toprule \nv & \$1\$ & \$2\$ & \$3\$ \\\\ \n\\bottomrule \n\\end{tabular} \n\\end{table} \n"
result2 = "\\begin{table}[!ht] \n\\centering \n\\caption{cap} \n\\label{lab} \n\\begin{tabular}{@{} llll @{}} \n\\hline \nv & \$1\$ & \$2\$ & \$3\$ \\\\ \n\\hline \n\\end{tabular} \n\\end{table} \n"

function split_string(s::String)
    s = remove_spaces(s)
    s = sort(split(s, "\n"))
    return s[.!isempty.(s)]
end

function remove_spaces(s::String)
    ii = [t[1] for t in collect.(findall(" ", s))]
    jj = setdiff(1:length(s), ii)
    return s[jj]
end

function is_subset(s1::AbstractArray, s2::AbstractArray)
    all([any(x1 .== s2) for x1 in s1])
end

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

@testset "Comparison" begin
    @test compare_strings_rows(result1, table_to_tex(body; table_type=:booktabs, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=true))
    @test compare_strings_rows(result1, table_to_tex(body; table_type=:booktabs, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=false))
    @test compare_strings_rows(result2, table_to_tex(body; table_type=:tabular, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=true))
    @test compare_strings_rows(result2, table_to_tex(body; table_type=:tabular, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=false))
    @test !compare_strings_rows_subset(result1, table_to_tex(body; table_type=:booktabs, position="!ht", centering=true, alignment="l", caption_position_top=true, floating_table=false))
    @test compare_strings_rows_subset(table_to_tex(body; table_type=:booktabs, position="!ht", centering=true, alignment="l", caption_position_top=true, floating_table=false), result1)
end

@testset "Compile" begin
    @test compile_success("test12344321", table_to_tex(body; table_type=:booktabs, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=true, highlight_max_row=true, highlight_min_row=true))
    @test compile_success("test12344322", table_to_tex(body; table_type=:booktabs, position="!ht", caption="cap", label="lab", centering=true, alignment="l", caption_position_top=true, highlight_max_col=true, highlight_min_col=true))
end
