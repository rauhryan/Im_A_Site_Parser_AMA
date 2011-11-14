require 'sinatra'
require 'httparty'
require 'nokogiri'


class NokogiriParser < HTTParty::Parser
    SupportedFormats.merge!('text/xml' => :xml)
    def xml
        Nokogiri::XML(body)
    end
end
class Reddit
    include HTTParty
    parser NokogiriParser
end

get '/' do 
    return "welcome"
end

get '/:thread' do 
    @doc = Reddit.get("http://www.reddit.com/r/IAmA/comments/#{params[:thread]}/.rss")
    @thread = []
    previous = nil
    author = /submitted by <a href=".*">\s*(?<author>\w+)/.match(@doc.css("rss channel item:first").css("description").text)[:author]
    puts "Author = #{author.to_s}"
    @doc.css("rss channel item").each do |node|
        r = /^<title>#{author} on/
            if r.match(node.css("title").to_s)  
                @thread << {
                    :question => {
                        :author => /(\w+)/.match(previous.css("title").text)[0],
                        :text => previous.css("description").text,
                        :permalink => previous.css("link").text
                },
                    :answer => {
                        :author => author,
                        :text => node.css("description").text,
                        :permalink => node.css("link").text
                }
                }
            end
        previous = node
    end
    erb :index
end