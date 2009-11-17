#coding: utf-8
%w(sinatra/base haml time yaml ostruct).each do |lib|
  require lib
end

$KCODE='u' if RUBY_VERSION < '1.9.0'

module Ouiche
  DATADIR = File.join(File.dirname(__FILE__), 'data')

  Words = {
    :lists   => 'Lists',
    :error   => 'Error',
    :no_link => 'No such link.<br /> <a href="/">Return to home</a>',
    :no_list => 'No such list.<br /> <a href="/">Return to home</a>',
    :power => 'powered by <a href="http://github.com/madx/ouiche">Ouiche</a>'
  }

  Lists = {}

  def self.read(file)
    title, items, links = File.read(file).split(/^---+$/).map {|l| l.strip }
    Lists[slug=File.basename(file, File.extname(file))] = OpenStruct.new({
      :title => title,
      :links => YAML.load(links),
      :items => items.split(/^\*/)[1..-1].map {|item|
        Formatter.new(item.strip).to_html(slug)
      }
    })
  end

  def self.load!
    Dir[File.join(DATADIR, '*')].each {|f| read(f) }
  end

  def self.[](key)
    Lists[key]
  end

  # Code stolen and adapted from Challis
  class Formatter < String
    def to_html(slug)
      gsub(/\{\{\{(.*?)\}\}\}/m) {
        preserve = $~[1].strip.gsub(/\n {0,2}/, '&#10;').gsub(/(.)/, '\\\\\1')
        "{{{#{preserve}}}}"
      }.gsub(/\\([^\\\n]|\\(?!\n))/) { "&MarkupEscape#{$&[1]};" }.
        gsub(/&(?!#\d+;|#x[\da-fA-F]+;|\w+;)/, "&amp;").
        gsub(/^ {0,2}/, '').
        gsub('<', '&lt;').
        gsub('>', '&gt;').
        gsub('"', '&quot;').
        gsub(/\*(.*?)\*(?=\W|$)/,  '<strong>\1</strong>').
        gsub(/_(.*?)_(?=\W|$)/,    '<em>\1</em>').
        gsub(/`(.*?)`(?=\W|$)/,    '<code>\1</code>').
        gsub(/~(.*?)~(?=\W|$)/,    '<del>\1</del>').
        gsub(/(?![^&])#(\w+)/,            '/'+slug+'/@/\1').
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
        if Ouiche[params[:list]]
          "#{Ouiche[params[:list]].title} — Ouiche"
        else
          'Ouiche'
        end
      end
    end

    configure do
      set :haml, :attr_wrapper => '"'
    end

    get '/' do
      if Ouiche::Lists.keys.size == 1
        redirect '/' + Ouiche::Lists.keys.first
      else
        @title = Ouiche::Words[:lists]
        haml :index
      end
    end

    get '/style.css' do
      content_type 'text/css'
      File.read(File.join(File.dirname(__FILE__), 'style.css'))
    end

    get '/_sync' do
      Ouiche.load!
      redirect '/'
    end

    get '/:list' do
      if @list = Ouiche[params[:list]]
        @title = @list.title
        haml :list
      else
        response.status = 404
        @title = Ouiche::Words[:error]
        haml :no_list
      end
    end

    get '/:list/@/:link' do
      @title = Ouiche::Words[:error]

      if list = Ouiche[params[:list]]
        if list.links && list.links[params[:link]]
          redirect list.links[params[:link]]
        else
          response.status = 404
          haml :no_link
        end
      else
        response.status = 404
        haml :no_list
      end
    end

    use_in_file_templates!
  end

end

__END__
@@ index
%ul#lists
  - Ouiche::Lists.keys.sort.each do |list|
    %li
      %a{ :href => '/'+list }= Ouiche[list].title

@@ list
%ul#list
  - @list.items.each do |item|
    %li= item

@@ layout
!!! Strict
%html{html_attrs}
  %head
    %title= make_title
    %link{:rel => 'stylesheet', :href => '/style.css', :type => 'text/css', :media => 'screen', :charset => 'utf-8'}
  %body
    %h1= @title
    = yield
    %p#foot= Ouiche::Words[:power]

@@ no_list
%p#error= Ouiche::Words[:no_list]

@@ no_link
%p#error= Ouiche::Words[:no_list]
