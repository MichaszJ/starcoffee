using Dates

function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

# MIT License

# Copyright (c) 2021 Matthijs Cox

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# https://github.com/matthijscox/Blog/blob/main/utils.jl
struct PostInfo
    title::String
    pagename::String
    date::String
    tags::String
end

function get_post_info(post_file)
    file_path = joinpath("./posts", post_file)
    
    title = open(file_path) do file
        read_file = read(file, String)
        m = match(r"@def title = \"(.*?)\"", read_file)
        return string(first(m.captures))
    end

    date = open(file_path) do file
        read_file = read(file, String)
        m = match(r"@def published = \"(.*?)\"", read_file)
        return string(first(m.captures))
    end

    tags = open(file_path) do file
        read_file = read(file, String)
        m = match(r"@def tags = \[(.*?)\]", read_file)
        return string(first(m.captures))
    end
    
    pagename = first(splitext(post_file))
    
    return PostInfo(title, pagename, date, tags)
end

function strip_tags_str(tags_str::String)
    return split(replace(tags_str, '\"' => "", ", " => ","), ",")
end

function parse_date(date_string::String)
    matches = match(r"(^\w+)[^\d]*(\d+)[^\d]*(\d+)", date_string)
    captures_vec = String.(matches.captures)
    return Date(parse(Int,captures_vec[3]), Dates.LOCALES["english"].month_value[captures_vec[1]], parse(Int,captures_vec[2]))
end

function hfun_blogposts(params)
    tag_filter, sorted = params
    sorted = parse(Bool, sorted)

    post_section = "<ul class=blogposts>"
    list = readdir("./posts")

    post_info = get_post_info.(list)

    if sorted
        post_dates = [parse_date(info.date) for info in post_info]
        posts_sorted = post_info[sortperm(post_dates, rev=true)]
    else
        posts_sorted = post_info
    end

    for post in posts_sorted
        if occursin(tag_filter, post.tags)
            if sorted
                post_link = "<p><a href=\"/posts/$(post.pagename)/\">$(post.title)</a> - $(post.date) </p>"
            else
                post_link = "<p><a href=\"/posts/$(post.pagename)/\">$(post.title)</a></p>"
            end
            post_div = "<li class=postlink>$post_link</li>"

            post_section *= post_div
        end
    end
    post_section *= "</ul>"
end