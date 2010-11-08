# encoding: utf-8
%w(sinatra/base haml time yaml ostruct rdiscount).each do |lib|
  require lib
end

$KCODE='u' if RUBY_VERSION < '1.9.0'

module Ouiche
  DATADIR = File.join(File.dirname(__FILE__), 'data')
  GLOB    = File.join(DATADIR, '*')

  Words = {
    :title   => 'Ouiche',
    :error   => 'Error',
    :no_page => 'No such page.<br /> <a href="/">Return to index</a>',
    :go_home => '<a href="/" title="Return to index">↑</a>',
    :powered => 'powered by <a href="http://github.com/madx/ouiche">Ouiche</a>'
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
      }.reject {|p| (p.slug.index('+') || 1).zero? || p.slug.index(':') }
    end

    def slugs
      Dir[GLOB].map {|f| File.basename(f) }
    end

    def read(slug)
      File.open(File.join(DATADIR, slug)) do |io|
        return OpenStruct.new({
          :title => io.readline.chomp, 
          :body  => (io.rewind; Markdown.new(io.read).to_html)
        })
      end
    end
  end

  class App < Sinatra::Base
    configure do
      set    :haml, :attr_wrapper => '"'
      enable :inline_templates
    end

    helpers do
      def open(page)
        if !Ouiche.slugs.member?(page)
          response.status = 404
          @title = Ouiche::Words[:error]
          haml :no_page
        else
          @page  = Ouiche.read(page)
          @title = @page.title
          haml :page
        end
      end
    end

    get '/' do
      @page = Ouiche.read('+index')
      haml :index
    end

    get '/style.css' do
      content_type 'text/css'
      File.read(File.join(File.dirname(__FILE__), 'style.css'))
    end

    get '/:page' do
      open(params[:page])
    end

    get '/p/:page' do
      open('+' + params[:page])
    end
  end
end

__END__
@@ index
#page~ @page.body
%ul#menu
  - Ouiche.pages.each do |page|
    %li
      %a{ :href => '/' + page.slug }= page.title

@@ page
#go_home= Ouiche::Words[:go_home]
#page~ @page.body

@@ layout
!!! Strict
%html{html_attrs}
  %head
    %title== #{("%s -" % @page.title) if @page} #{Ouiche::Words[:title]}
    %meta{'http-equiv' => 'Content-Type', :content => "text/html;charset=utf-8"}
    %link{:rel => 'stylesheet', :href => '/style.css', :type => 'text/css',
          :media => 'screen', :charset => 'utf-8'}
  %body
    #ouiche
      = yield
      %p#foot= Ouiche::Words[:powered]

@@ no_page
%p#error= Ouiche::Words[:no_page]
