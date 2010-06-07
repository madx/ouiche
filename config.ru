require ::File.join(::File.dirname(__FILE__), 'ouiche')

# Uncomment and change the value below to change the index page's title
# Ouiche::Words[:index] = 'Index'

run Ouiche::App
