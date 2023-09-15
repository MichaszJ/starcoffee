@def title = "Starting jl-note"
@def subtitle = "Starting a new project related to literate programming"
@def published = "September 12th, 2023"
@def author = "Michal Jagodzinski"
@def tags = ["Blogging", "Programming", "Julia"]

@def mintoclevel=1

@def reeval = true

{{ generate_title "starting-jl-note.md" }}

@@im-100
![](https://source.unsplash.com/an-aerial-view-of-a-rocky-beach-with-clear-blue-water-fOZB5P4DcjM)
@@

@@img-caption
Photo by [Liam Gamba](https://unsplash.com/photos/an-aerial-view-of-a-rocky-beach-with-clear-blue-water-fOZB5P4DcjM)
@@


\tableofcontents

# Introduction

Hello and welcome back to Star Coffee. This past week (as of writing) I've started working on `jl-note`, a simple tool for [literate programming](https://en.wikipedia.org/wiki/Literate_programming). It's a quite simple tool, it reads in the content of a plaintext file that contains blocks of Julia code, evaluates the blocks, and writes their output or value back to the file. 

This project was heavily inspired by [Babel for Org](https://orgmode.org/worg/org-contrib/babel/) which is in general the same idea. However, I had some problems trying to get Babel to work well with Julia code, and I wanted a more lightweight/universal tool than having to use Emacs.

# The Code

The tool is quite simple in its current state, it's by no means optimized or works super smoothly. It also has to evaluate the code from scratch everytime it's run, which means waiting for all of the precompilation Julia needs to do (or it can be run in a Julia REPL, which removes the need for precompilation every time it's run). I'll try to tackle these problems and make it a much more streamlined tool, at which point I might open-source it.

The heavy lifting in `jl-note` is done by `IOCapture.jl`, which captures IO from evaluated Julia code and let's you access the results. At the moment, this is the only dependency for `jl-note`:

```julia
using IOCapture 
```

First the script grabs the file path supplied to `jl-note` via the command line:

```julia
file_path = ARGS[1]
```

Next I defined some `struct`s to store the contents of a file:

```julia
struct InputChunk
    content::String
    is_code::Bool
end

struct InputFile
    file_path::String
    file_contents::Vector{InputChunk}
end
```

The `InputChunk` `struct` stores a block of text, and denotes whether the text contains Julia code. The `InputFile` `struct` simply stores the file path and a vector of `InputChunk`s. Next I wrote a function to parse a plaintext file and return an `InputFile`:

```julia
function get_file_chunks(file_path::String)::InputFile
    file_chunks = InputChunk[]

    reading_code_chunk = false
    code_chunk_start = 0
    
    current_chunk = ""

    for (i, line) in enumerate(eachline(file_path))
        if (!reading_code_chunk && !occursin("```", line)) || (reading_code_chunk && !occursin("```", line))
            if line != "\n"
                current_chunk *= line * '\n'
            end
        end

        if occursin("```", line) && !reading_code_chunk
            if current_chunk != ""
                push!(file_chunks, InputChunk(current_chunk, false))
            end

            reading_code_chunk = true
            code_chunk_start = i

            current_chunk = line * '\n'
        
        elseif reading_code_chunk && i != code_chunk_start && occursin("```", line)
            reading_code_chunk = false

            current_chunk *= line * '\n'

            if !occursin("```STDOUT", current_chunk) && !occursin("```OUTPUT", current_chunk)
                push!(file_chunks, InputChunk(current_chunk, true))
            end

            current_chunk = ""
        end
    end
    
    return InputFile(file_path, file_chunks)
end
```

I know the code is quite messy, but it works, optimizing comes later. This function basically goes line-by-line through the input file, and splits the file into chunks, alternating between text and code. Next I defined a `CodeChunk` `struct` to encode information about the code chunks, and I wrote a function to parse the `InputFile` to return a `Vector{CodeChunk}`:

```julia
struct CodeChunk
    properties::Vector{String}
    chunk::String
end

function get_code_chunks(input_file::InputFile)::Vector{CodeChunk}
    filtered = filter((chunk) -> chunk.is_code == true, input_file.file_contents)

    return [CodeChunk(String[], replace(chunk.content, "```julia\n" => "", "\n```" => "")) for chunk in filtered]
end
```

As of yet, I have not implemented any properties for the code chunks, so the `properties` field is unused, but I included it for now to allow for future development. Now for the interesting part, next is the function that takes a `Vector{CodeChunk}` and evaluates the code itself, capturing the output using `IOCapture.jl`:

```julia
function get_io_captures(code_chunks::Vector{CodeChunk})::Vector
    io_captures = []
    
    for chunk in code_chunks
        parsed_entry = replace(chunk.chunk, "\n\t" => "", '\n' => ';')

        io_capture = IOCapture.capture() do
            eval(Meta.parse(parsed_entry))
        end

        push!(io_captures, io_capture)
    end

    return io_captures
end
```

This function is pretty simple, it first converts the text into a single line and replaces any newline characters with semicolons, and then the code inside each chunk is evaluated. I do not return a concrete type from this function, because the return type from `IOCapture.capture()` is quite complicated and varies depending on the evaluated code. Next we have a function that takes in the `InputFile` and the `Vector` from `get_io_captures`, and inserts the results of the captures after each code block:

```julia
function insert_code_chunks(input_file::InputFile, code_chunks)::Vector{String}
    final_chunks = String[]
    code_counter = 1

    for chunk in input_file.file_contents
        push!(final_chunks, chunk.content)

        if chunk.is_code && code_counter <= length(code_chunks)
            code_output = ""

            if code_chunks[code_counter].output != ""
                code_output *= """\```STDOUT
                $(code_chunks[code_counter].output)
                \```
                """
            end

            if code_chunks[code_counter].value !== nothing
                code_output = """\```OUTPUT
                $(code_chunks[code_counter].value)
                \```
                """
            end

            push!(final_chunks, code_output)
            
            code_counter += 1;
        end
    end

    return final_chunks
end
```

This function returns a `Vector{String}` which contains each chunk of the original file with the results of the Julia code blocks inserted. Please note the \ characters in front of each \`\`\` in the function above, I needed to insert the backslashes to not make `Franklin.jl` crash when writing this blog post. If you're using this code (please feel free to!) just remove those backslashes. Finally, we come to our last function, the one that puts all of the building blocks together and writes the result to the original file:

```julia
function run_note!(file_path::String)
    input_file = get_file_chunks(file_path)

    io_captures = get_code_chunks(input_file) |> get_io_captures

    full_string = insert_code_chunks(input_file, io_captures) |> join
    
    open(file_path, "w") do file
        write(file, full_string);
    end
end
```

And that's it (for now). Running the `run_note!` function either in the file itself or in the Julia REPL with a supplied `file_path` results in the script reading the file contents, evaluating any Julia code blocks, and writing the results back to the supplied file. See [this tweet of mine to see it in action](https://x.com/astra_kawa/status/1701369995177910407).

# Conclusion

Thanks for reading this short post! I'm very happy with the progress I made on this project so far, and I'm excited to keep working at it in my free time. I recently found a job working at the Canadian Space Agency so I'm a bit busy these days, but I'd like to find some time every now and again to work on projects and write on this blog.

I hope you found this project interesting, feel free to use my code and play around with it. If people are interested I'll try to improve this script and open-source it, but we'll see what happens. Until next time.