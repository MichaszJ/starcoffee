@def title = "Dynamically Listing Blog Posts"
@def published = "April 20th, 2023"
@def tags = ["Julia", "Programming", "Blogging"]

# Dynamically Listing Blog Posts

_By Michal Jagodzinski - April 20th, 2023_

Welcome back to Star Coffee! This will be a short post about the system I wrote to dynamically generate the list of posts for this blog.

My old system of listing blog posts, such as on my [homepage](https://michaszj.github.io/starcoffee/) or on [project pages](https://michaszj.github.io/starcoffee/posts/satellite-analysis-toolkit/), was to manually type out the link and date for each post. It worked and didn't take too long to do, but I'm lazy. So I decided to automate this work.

## The Code

Since I am using [Franklin.jl](https://franklinjl.org/) to build this site, I can automate this task using Julia. I initially planned to just use [Matthijs Cox's](https://scientificcoder.com/) code that he uses on his blog [Functional Noise](https://www.functionalnoise.com/), but I found that it did not fully suit my needs. He did a lot of the initial heavy lifting for me, so credits to his work.

The following code is inside of the `utils.jl` file in the main directory of my `Franklin.jl` project. See the following `Franklin.jl` documentation to learn more about this code: [Utils](https://franklinjl.org/syntax/utils/). First, I define a struct to contain the metadata of each blog post:

```julia
struct PostInfo
    title::String
    pagename::String
    date::String
    tags::String
end
```

For reference, here is the metadata that I include in the markdown files for each blog post:

```julia
@def title = "Dynamically Listing Blog Posts"
@def published = "April 20th, 2023"
@def tags = ["Julia", "Programming", "Blogging"]
```

Next, a function to read in a post's filename and return a `PostInfo` struct based on that post:

```julia
function get_post_info(post_file)
    file_path = joinpath("./posts", post_file)

    title = open(file_path) do file
        read_file = read(file, String)
        m = match(r"\@def title = \"(.*?)\"", read_file)
        return string(first(m.captures))
    end

    date = open(file_path) do file
        read_file = read(file, String)
        m = match(r"\@def published = \"(.*?)\"", read_file)
        return string(first(m.captures))
    end

    tags = open(file_path) do file
        read_file = read(file, String)
        m = match(r"\@def published = \"(.*?)\"", read_file)
        return string(first(m.captures))
    end

    pagename = first(splitext(post_file))

    return PostInfo(title, pagename, date, tags)
end
```

Please note the \ character in the beginning of each regex string. In the actual code this character is not actually there, I had to put that there as I was getting the following error on compiling the Franklin project:

```
ERROR: Base.Meta.ParseError("\"\\\" is not a unary operator")
```

I am not sure why this is happening but if you are using this code, make sure to remove the three \ characters in the `get_post_info` function.

Next, some helper functions:

```julia
function strip_tags_str(tags_str::String)
    return split(replace(tags_str, '\"' => "", ", " => ","), ",")
end
```

```julia
function parse_date(date_string::String)
    matches = match(r"(^\w+)[^\d]*(\d+)[^\d]*(\d+)", date_string)
    captures_vec = String.(matches.captures)
    return Date(
        parse(Int, captures_vec[3]),
        Dates.LOCALES["english"].month_value[captures_vec[1]],
        parse(Int, captures_vec[2])
    )
end
```

The first function parses the tags string that gets read in. For reference, here is the tags string for this blog post:

```
["Julia", "Programming", "Blogging"]
```

Again, this is the _string_ that is read in by the `get_post_info` function. The `strip_tags_str` function takes this string and converts it to a vector of strings of the individual tags.

Next, the `parse_date` function converts a date string and converts it into a `Date` type. For reference, here is the publishing date of this post:

```
"April 20th, 2023"
```

This function is somewhat complicated because of the formatting of this string. But I'd like this format to be displayed both on the blog post itself and in the list of posts, which is why I decided to keep this format.

Finally, the function to actually generate the list of posts:

```julia
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
```

First thing to note is that this `hfun` function takes in some parameters, `tag_filter` and `sorted`. When I call the function in a markdown file, I can specify a tag to filter by and whether to sort the posts by date. For example, here is the function calls I use in the [homepage](https://michaszj.github.io/starcoffee/) of this blog to list project pages and all blog posts:

```markdown
## Ongoing Projects

{{ blogposts Project false }}

## All Posts

{{ blogposts Blogging true }}
```

I wanted to have a customizable method of listing blog posts. For the [Ongoing Projects](https://michaszj.github.io/starcoffee/#ongoing_projects) section of my homepage, I wanted the project pages (each with the tag "Project") to not be sorted by publishing date. On the other hand, for the [All Posts](https://michaszj.github.io/starcoffee/#all_posts) section, I did want the posts sorted by date. I also did not want to include project pages in my list of blog posts, as they are not really blog posts, they are closer to showcases or documentation. This is why I defined the `hfun_blogposts` in this way, allowing for arbitrary filtering and sorting.

## Wrapping Up

Thanks for reading, I hope this post was useful. This is the system I am using as of writing for this `Franklin.jl` blog. Feel free to adapt my code for your own, it seems to work well enough for me.

I will be back with some more aerospace engineering stuff soon. Until next time.
