#coding: utf-8
%w(sinatra/base haml time yaml ostruct).each do |lib|
  require lib
end

$KCODE='u' if RUBY_VERSION < '1.9.0'

module Ouiche
  DATADIR = File.join(File.dirname(__FILE__), 'data')
  GLOB    = File.join(DATADIR, '*')

  Words = {
    :index   => 'Index',
    :error   => 'Error',
    :no_link => 'No such link.<br /> <a href="/">Return to index</a>',
    :no_page => 'No such page.<br /> <a href="/">Return to index</a>',
    :back    => '<a href="/" title="Return to index">←</a>',
    :power   => 'powered by <a href="http://github.com/madx/ouiche">Ouiche</a>'
  }

  class << self
    def pages
      [].tap { |res|
        Dir[GLOB].each do |f|
          next if File.directory?(f)
          File.open(f, 'r') do |io|
            res << OpenStruct.new({
              :slug  => File.basename(f),
              :title => io.readline.chomp
            })
          end
        end
      }.reject {|p| p.slug[0] == ':'[0] }
    end

    def slugs
      Dir[GLOB].map {|f| File.basename(f) }
    end

    def read(slug)
      file = File.join(DATADIR, slug)
      title, body, links = File.read(file).split(/^---+$/).map {|l| l.strip }
      OpenStruct.new({
        :title => title,
        :body  => Formatter.new(body).to_html(slug),
        :links => YAML.load(links || "")
      })
    end
  end

  # Code stolen and adapted from Challis
  class Formatter < String
    def to_html(slug)
      gsub(/\{\{\{(.*?)\}\}\}/m) {
        preserve = $~[1].strip.gsub(/\n {0,4}/, '&#10;').gsub(/(.)/, '\\\\\1')
        "{{{#{preserve}}}}"
      }.gsub(/\\([^\\\n]|\\(?!\n))/) { "&MarkupEscape#{$&[1]};" }.
        gsub(/&(?!#\d+;|#x[\da-fA-F]+;|\w+;)/, "&amp;").
        gsub(/^ {0,2}/, '').
        # gsub('<', '&lt;').
        # gsub('>', '&gt;').
        # gsub('"', '&quot;').
        gsub(/\*(.*?)\*(?=\W|$)/,  '<strong>\1</strong>').
        gsub(/_(.*?)_(?=\W|$)/,    '<em>\1</em>').
        gsub(/`(.*?)`(?=\W|$)/,    '<code>\1</code>').
        gsub(/~(.*?)~(?=\W|$)/,    '<del>\1</del>').
        gsub(/#(\w+)/,            '/'+slug+'/@/\1').
        gsub(/\[(\S+)\]/,         '<a href="\1">\1</a>').
        gsub(/\[(.*?)\s?(\S+)\]/, '<a href="\2">\1</a>').
        gsub(/\\\\\n/, "<br />\n").
        gsub(/\{\{\{(.*?)\}\}\}/, '<pre><code>\1</code></pre>').
        gsub(/&MarkupEscape(\d+);/) { $1.to_i.chr }.
        strip
    end
  end

  class App < Sinatra::Base
    helpers do
      def make_title
        if @page
          "#{@page.title} — Ouiche"
        else
          'Ouiche'
        end
      end
    end

    configure do
      set    :haml, :attr_wrapper => '"'
      enable :inline_templates
    end

    get '/' do
      @title = Ouiche::Words[:index]
      @index = Ouiche.read(':index')
      haml :index
    end

    get '/style.css' do
      content_type 'text/css'
      File.read(File.join(File.dirname(__FILE__), 'style.css'))
    end

    get '/:page' do
      if Ouiche.slugs.member?(params[:page])
        @page  = Ouiche.read(params[:page])
        @title = @page.title
        haml :page
      else
        response.status = 404
        @title = Ouiche::Words[:error]
        haml :no_page
      end
    end

    get '/:page/@/:link' do
      @title = Ouiche::Words[:error]

      if Ouiche.slugs.member?(params[:page])
        page = Ouiche.read(params[:page])
        if page.links && page.links[params[:link]]
          redirect page.links[params[:link]]
        else
          response.status = 404
          haml :no_link
        end
      else
        response.status = 404
        haml :no_page
      end
    end
  end

end

__END__
@@ index
#page= @index.body
%ul#menu
  - Ouiche.pages.each do |page|
    %li
      %a{ :href => '/' + page.slug }= page.title

@@ page
#page= @page.body

@@ layout
!!! Strict
%html{html_attrs}
  %head
    %title= make_title
    %meta{'http-equiv' => 'Content-Type', :content => "text/html;charset=utf-8"}
    %link{:rel => 'stylesheet', :href => '/style.css', :type => 'text/css', :media => 'screen', :charset => 'utf-8'}
  %body
    %h1
      = Ouiche::Words[:back] if @page
      = @title
    = yield
    %p#foot= Ouiche::Words[:power]

@@ no_page
%p#error= Ouiche::Words[:no_page]

@@ no_link
%p#error= Ouiche::Words[:no_link]
