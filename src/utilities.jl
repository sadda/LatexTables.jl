function make_tex_file(dir_name::String, file_name::String, s::String)

    full_name = joinpath(dir_name, file_name)

    f = open(full_name, "w")

    write(f, "\\documentclass{article}\n\n")
    write(f, "\\usepackage{xcolor}\n")
    write(f, "\\usepackage{colortbl}\n")
    write(f, "\\usepackage{booktabs}\n\n")
    write(f, "\\begin{document}\n\n")
    write(f, s)
    write(f, "\n")
    write(f, "\\end{document}\n")

    close(f)

    cmd = `pdflatex -quiet -output-directory $dir_name $full_name`;
    run(cmd)
end
