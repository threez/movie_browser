require "rubygems"
require "activerecord"
require "yaml"

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.colorize_logging = true

db_config = File.open("config.yml") { |f| YAML.load(f.read) }
ActiveRecord::Base.establish_connection(db_config)

class Movie < ActiveRecord::Base
  serialize :data
  belongs_to :genre
  has_many :markers
  
  def color
    self.available ? 'green' : 'red'
  end
  
  def image_path
    "http://www.cinebank.de/fol/LOCANDINE/#{self.movie_id}.jpg"
  end
end

class Genre < ActiveRecord::Base
  has_many :movies
  belongs_to :movie_format
end

class MovieFormat < ActiveRecord::Base
  has_many :genres
end

class User < ActiveRecord::Base
  has_many :markers
  
  def self.login?(uid)
    unless find_by_uid(uid)
      User.create(:uid => uid)
    end
    true
  end
  
  def mark(category, movie_id)
    # remove not seen marker if :seen is going to be set
    if category == :seen and (marker = find_mark(:not_seen, movie_id)) then 
      unmark(marker.id)
    end 
    markers.create(:category => category, :movie_id => movie_id)
  end
  
  def find_mark(category, movie_id)
    markers.find(:first, :conditions => {
      :category => Marker::CATEGORYS[category], 
      :movie_id => movie_id}
    )
  end
  
  def unmark(marker_id)
    Marker.delete(marker_id) if markers.find(marker_id)
  end
end

class Marker < ActiveRecord::Base
  belongs_to :movie
  belongs_to :user
  
  CATEGORYS = {
    :not_seen => 0,
    :seen => 1
  }
  
  def self.find_movies_by_category(category)
    find_all_by_category(CATEGORYS[category], 
      :include => :movie).map { |m| m.movie }
  end
  
  def category=(symbol)
    write_attribute(:category, CATEGORYS[symbol])
  end
  
  def category
    CATEGORYS.each_pair do |key, value|
      return key if value == read_attribute(:category)
    end
  end
end

if __FILE__ == $0 && ARGV.shift == "create" then
  ActiveRecord::Schema.define do  
    create_table :movies do |t|
      t.string :movie_id
      t.boolean :available
      t.string :title
      t.text :data
      t.text :description
      t.integer :year 
      t.integer :age
      t.integer :duration
      t.string :producer
      t.integer :genre_id
      t.integer :audio
      t.string :regisseur
      t.text :actors
    end

    create_table :genres do |t|
      t.integer :legacy_nr
      t.string :name
      t.integer :movie_format_id
    end

    create_table :movie_formats do |t|
      t.integer :legacy_nr
      t.string :name
    end
    
    create_table :users do |t|
      t.string :uid
    end
    
    create_table :markers do |t|
      t.integer :category
      t.integer :movie_id
      t.integer :user_id
    end
  end
  
  GENRES_DVD = {
    "Action/Krieg" => 1,
    "Komödie" => 2,
    "Karate/Kung Fu" => 3,
    "Fantasy / Abenteuer" => 4,
    "Horror" => 5,
    "Unterhaltung" => 6,
    "Klassiker / Kult" => 7,
    "Serien" => 8,
    "Bollywood" => 9,
    "Kinderfilme" => 10,
    "Drama" => 11,
    "Science-Fiction" => 12,
    "Erotic/Lovestory/Gay-Kino" => 14,
    "Thriller" => 15
  }

  GENRES_BLUE_RAY = {
    "Action/Krieg" => 1,
    "Komödie" => 2,
    "Fantasy / Abenteuer" => 4,
    "Horror" => 5,
    "Klassiker / Kult" => 7,
    "Kinderfilme" => 10,
    "Drama" => 11,
    "Science-Fiction" => 12,
    "Thriller" => 15
  }

  GENRES_HARDCORE_DVD = {
    "Hetero" => 1,
    "Lesbo" => 2,
    "Fetisch/Bizarr/SM" => 3,
    "Reife Damen" => 4,
    "Gay" => 5,
    "Exotic" => 6,
    "Bi/Gang-Bang" => 7,
    "Manga" => 8,
    "Privat/Amateur" => 9,
    "Transsexuell" => 10,
    "over 18" => 11,
    "Anal" => 13
  }

  dvd = MovieFormat.create(:legacy_nr => 2, :name => "DVD")
  GENRES_DVD.each_pair do |name, nr|
    dvd.genres.create(:legacy_nr => nr, :name => name)
  end

  blue_ray = MovieFormat.create(:legacy_nr => 8, :name => "BlueRay")
  GENRES_BLUE_RAY.each_pair do |name, nr|
    blue_ray.genres.create(:legacy_nr => nr, :name => name)
  end

  hardcore_dvd = MovieFormat.create(:legacy_nr => 213, :name => "Hardcore-DVD")
  GENRES_HARDCORE_DVD.each_pair do |name, nr|
    hardcore_dvd.genres.create(:legacy_nr => nr, :name => name)
  end  
end
