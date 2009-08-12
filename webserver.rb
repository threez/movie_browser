require "rubygems"
require "sinatra"
require "db"
require "time"

configure do
  set :sessions, true
end

before do
  # sessioning only for things that are not in public directory
  if request.path_info =~ /(genre|show|user|search)/
    @user = User.find_by_uid(session[:uid]) if session[:uid]
  end
end

get "/" do
  redirect "/genre/" + Genre.find(:first).id.to_s
end

get "/newest" do
  @title = "Neuerscheinungen #{year}"
  @movies = Movie.newest
  erb :index
end

get "/feed.xml" do
  content_type "application/rss+xml"
  @movies = Movie.newest
  erb :rss, :layout => none
end

get "/genre/:id" do
  @genre = Genre.find(params[:id], :include => :movies)
  @title = "Genre #{@genre.name}"
  @movies = @genre.movies
  erb :index
end

get "/show/:id" do
  @title = "Filmansicht"
  @movie = Movie.find(params[:id], :include => { :genre => :movie_format })
  @marker = @user.markers.find_by_movie_id(@movie.id) if @user
  erb :show
end

get "/search" do
  search = "%" + params["name"] + "%"
  @title = "Suche '#{params["name"]}'"
  @movies = Movie.find(:all, :order => "title", :limit => 50,
    :conditions => ["title like ? or actors like ?", search, search])  
  erb :index
end

get "/user/login" do
  if params["uid"] and User.login?(params["uid"])
    session[:uid] = params["uid"]
    redirect "/"
  else
    @title = "Login"
    erb :login
  end
end

get "/user/logout" do
  session[:uid] = nil
  redirect "/"
end

get "/user/markers" do
  @title = "Markierungen"
  if @user
    @seen = @user.markers.find_movies_by_category(:seen)
    @not_seen = @user.markers.find_movies_by_category(:not_seen)
    erb :markers
  else
    redirect "/"
  end
end

get "/user/reserve/:movie_id" do
  # FIXME
end

get "/user/mark/:category/:movie_id" do
  if @user
    @user.mark(params[:category].to_sym, params[:movie_id].to_i)
    redirect "/user/markers"
  else  
    redirect "/"
  end
end

get "/user/unmark/:marker_id" do
  if @user
    # only delete the marker if it is assigned to the user
    @user.unmark(params[:marker_id].to_i)
    redirect "/user/markers"
  else  
    redirect "/"
  end
end
