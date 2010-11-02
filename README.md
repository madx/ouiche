Ouiche
======

Ouiche is a lightweight personal wiki engine that uses flat text files.

Ouiche is written in [Ruby][1] with the [Sinatra][2] web framework. The data
files are written in Markdown, so you need to have [RDiscount][3].

It is completely Open-Source (published under the WTFPL): you can do whatever
you want with the source code, and I'll happily accept any patches or
improvements (use GitHub for that). If we meet, you can also buy me a beer.

[1]: http://ruby-lang.org/
[2]: http://sinatra.github.com/
[3]: http://github.com/rtomayko/rdiscount

## Usage #######################################################################

Pages are stored in the `data/` folder. File names will be used in the URLs, so
pay attention to these.

The file format is easy:

    Title
    ---
    Some text in Markdown.

The title will be used as the page title (awesome!), the part after the `---`'s
will be the body of the page. Period.

You can have private pages: just prepend the filename with a `+`. You can access
such pages by visiting `/p/<page>`, and they will be skipped from the index.
