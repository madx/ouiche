require ::File.join(::File.dirname(__FILE__), 'ouiche')

Ouiche.load!

run Ouiche::App
