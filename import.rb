require "rubygems"
require "rexml/document"
require "httparty"
require "db"

class FilmOnline
  include HTTParty
  base_uri 'essen.filmonline.biz'
  
  def self.query_all(format, filter, customer_id = "")
    movies = []
  
    response = query(format, filter, 0, customer_id)
    movies += parse_repsonse(response)
    movie_count = response["result"]["moviecount"].to_i
    
    (30..movie_count).step(30) do |offset|
      response = query(format, filter, offset, customer_id)
      movies += parse_repsonse(response)
    end
    movies
  end
  
  def self.query(format, filter, offset = 0, customer_id = "")
    format = case format
               when :dvd then 2
               when :blue_ray then 8
               when :hardcore_dvd then 213
             end
    
    # request
    get('/filmonline/movies.aspx', :query => {
      :a => "", # action ?
      :r => 2, # 0 => anon, 2 => customer ?
      :fo => format, # 8 = blue ray, 2 = dvd, 213 = hardcore dvd (format)
      :fi => filter, # listentyp (filter)
      :c => customer_id,
      :ms => offset, # movie start (offset) ? in 15ner Schritten
      :m => (offset == 0) ? 0 : 14   # movieid ? machmal 15 manchmal 0 ???
    })
  end
  
  # parse data and create movie objects
  def self.parse_repsonse(response)
    movies = []
    raw = "<root>" + 
          response["result"]["contentjs"].gsub(/&nbsp;/, "").gsub("\n", "").
            gsub(/<\/?br>/, "").gsub(/&\s/, "&amp; ").
            gsub(/<\/?b>/, "").gsub(/<a([^<]*)>/, "").gsub(/<\/a>/, "|") + 
          "</root>"
    doc = REXML::Document.new(raw)
    movie_format = MovieFormat.find_by_legacy_nr(response["result"]["format"].to_i)
    doc.root.each do |element|
      if element.is_a? REXML::Element
        movie = Movie.new()
        element.each do |e|
          if e.is_a? REXML::Element
            case e.attribute("id").value
              when /id_\d+/
                movie.movie_id = e.text
              when /a_\d+/
                movie.available = (e.text =~ /true/) ? true : false
              when /t_\d+/
                movie.title = e.text
              #when /i_\d+/
              #  movie.image_src = e.text
              when /d_\d+/
                table = e.elements[1]
                table.each do |tr|
                  if tr.respond_to? :elements and tr.elements[1].text
                    name = tr.elements[1].text.gsub(/:/, "").strip.downcase.to_sym
                    value = tr.elements[2].text
                    value = value.split(/\|/) if value =~ /\|/
                    case name
                      when :daten
                        # ignore
                      when :altersfreigabe
                        movie.age = value.split(" ").first.to_i
                      when :genre
                        movie.genre = movie_format.genres.find_by_name(value)
                      when :produktionsjahr
                        movie.year = value.to_i
                      when :regisseur
                        movie.regisseur = value.join(",") 
                      when :audio
                        movie.audio = value.to_i 
                      when :darsteller
                        movie.actors = value.join(",")
                      when :vertrieb
                        movie.producer = value.join(",") 
                      when :laufzeit
                        movie.duration = value.split(" ").first.to_i
                      else
                        movie.data[name] = value
                    end
                  end
                end
              when /c_\d+/
                movie.description = e.text
            end
          end
        end
        movies << movie
      end
    end
    movies
  end
  
  # AKTUELL (dvd, blue ray, hardcore dvd)
  #  "Neuerscheinungen" => :aktuell_1,
  #  "Topfilme" => :aktuell_2,
  #  "Gesamtliste" => :aktuell_3,
  #  "Verfügbar, nicht gesehen" => :aktuell_6,
  def self.all_movies
    movies = []
    movies += query_all(:dvd, :aktuell_3)
    movies += query_all(:blue_ray, :aktuell_3)
    movies += query_all(:hardcore_dvd, :aktuell_3)
    movies
  end
end

if __FILE__ == $0 then
  case ARGV.shift
    when /import/
      movies = FilmOnline.all_movies
      movies.each { |movie| movie.save }
    when /sync/
      movies = FilmOnline.all_movies
      movies.each do |movie|
        # add missing movies
        unless Movie.find(:first, :conditions => { :title => movie.title, :genre_id => movie.genre_id })
          movie.save
        end
      end
    else
      puts "usage: #{$0} <import|sync>"
  end
end