Ouiche
======

Ouiche is a system that helps you publishing lists.\\
You can use it to share your wishlists, store bookmarks, manage your todolists,
etc.

Ouiche is written in Ruby with the lightweight Sinatra web framework. The
source is available on Github.

Lists are stored in plain text files and are written in a compact and easy to
learn format. Ouiche auto-discovers lists that are in it's data folder and
generates an index page for you if you have multiple lists.

Generated HTML is clean, and the stylesheet is very short, so you can easily
customize Ouiche to fit your design needs.

Last but not least, Ouiche is completely Open-Source (published under the
WTFPL): you can do whatever you want with the source code, and I'll happily
accept any patches or improvements (use GitHub for that!)

## Usage #######################################################################

Lists are stored in the `data/` folder. The file name will be used (extension
stripped) as the url of your list, so be smart when naming these files!

The file format is easy:

  title
  ---
  * item
  * other item
  ---
  links in yaml format

The title will be used as the page title (awesome!), the part between the `---`'s
will be split on leading `*`'s and returned elements parsed with
`Ouiche::Formatter`.

The last part is where you can put a yaml dictionnary of shortcuts for links,
for example `google: http://google.com/`. In the list items, just use `#google`
to expand to the full URL and `[#google]` to create a link.


For more formatting info, see `data/about` wich is a sample about page.


