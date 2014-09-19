require 'bundler/setup'
require 'dotenv'
Dotenv.load

Bundler.require(:default)

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
ActiveRecord::Base.establish_connection(YAML::load(File.open('./db/config.yml'))["development"])

DB = PG.connect({:dbname => 'whosmyrep_console_development'})

	CONSUMER_KEY       = ENV['twitter_consumer_key']
	CONSUMER_SECRET    = ENV['twitter_consumer_secret']
	OAUTH_TOKEN        = ENV['twitter_oauth_token']
	OAUTH_TOKEN_SECRET = ENV['twitter_oauth_token_secret']
	GOOGLE_API_KEY	   = ENV['google_api_key']


	TweetStream.configure do |config|
	  config.consumer_key       = CONSUMER_KEY       
	  config.consumer_secret    = CONSUMER_SECRET    
	  config.oauth_token        = OAUTH_TOKEN        
	  config.oauth_token_secret = OAUTH_TOKEN_SECRET 
	  config.auth_method        = :oauth
	end


def main
	@client = TweetStream::Client.new
	@client.on_error do |message|
	  puts "ERROR: #{message}"
	end

	puts "enter term"
	term = gets.chomp.to_s

	track(term)
end

def track (term)

	@client.track(term) do |status|

		puts status.user.screen_name + " - " + status.text

		@twitter = Twitter::REST::Client.new do |config|
		  config.consumer_key        = ENV['twitter_consumer_key']
		  config.consumer_secret     = ENV['twitter_consumer_secret']
		  config.access_token        = ENV['twitter_oauth_token']
		  config.access_token_secret = ENV['twitter_oauth_token_secret']
		end

		@status = status

		if @status.hashtags != nil

		  	@status.hashtags.each do |hash|
		  		rep_search(hash.attrs[:text].downcase)

	            
	            	response = "@#{@status.user.screen_name}" + " " + @rep1_info + " " + @rep2_info
	            	
	            	scrub_reply(response)
	            	
	            	new_tweet = @twitter.update(response, :in_reply_to_status_id => status.id)
	            	
	            	puts new_tweet.text 
	            	puts "@" + (Time.now).to_s + "\n" + "\n"

	            	add_reply(new_tweet.id, response.to_s)
	            	
	           
	        end
       	end
	end
end

def add_reply(id, message)
	Reply.create(reply_id: id, message: message)
end

def scrub_reply (response)
	if Reply.find_by(message: response)
		duplicate = Reply.find_by(message: response)
		@twitter.destroy_status(duplicate.reply_id.to_i)
		duplicate.destroy 
	end
end

def rep_search(location)
	@civicaide = CivicAide::Client.new(GOOGLE_API_KEY)
	build_rep(@civicaide.representatives.at(location))
end

def build_rep(rep_hash)
	binding.pry

	name1 = rep_hash["officials"]["p3"]["name"]
	# emails1 = rep_hash["officials"]["p3"]["emails"].join("")
	# phones1 = rep_hash["officials"]["p3"]["phones"].join("")

	name2 = rep_hash["officials"]["p4"]["name"]
	# emails2 = rep_hash["officials"]["p4"]["emails"].join("")
	# phones2 = rep_hash["officials"]["p4"]["phones"].join("")

	@rep1_info = name1 
	@rep2_info = name2 
end

main