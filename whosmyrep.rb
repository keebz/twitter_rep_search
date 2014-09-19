require 'bundler/setup'
require 'dotenv'
Dotenv.load

Bundler.require(:default)

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
ActiveRecord::Base.establish_connection(YAML::load(File.open('./db/config.yml'))["development"])

DB = PG.connect({:dbname => 'whosmyrep_console_development'})

@states = { "or" => "Oregon Information", 
			"ca" => "California Information",
			"fl" => "Florida Information",
			"tn" => "Tennessee Information",
			"mi" => "Michigan Information",
			"al" => "Alabama Information",
			"id" => "Idaho Information",
			"ny" => "New York Information",
			"tx" => "Texas Information",
			"co" => "Colorado Information",
			"ga" => "Georgia Information ",
			"ms" => "Mississippi Information",
			"wa" => "Washington Information"}

	CONSUMER_KEY       = ENV['twitter_consumer_key']
	CONSUMER_SECRET    = ENV['twitter_consumer_secret']
	OAUTH_TOKEN        = ENV['twitter_oauth_token']
	OAUTH_TOKEN_SECRET = ENV['twitter_oauth_token_secret']

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
	            if @states.include?(hash.attrs[:text].downcase)
	            	response = "@#{@status.user.screen_name}" + " " + @states[hash.attrs[:text].downcase]
	            	
	            	scrub_reply(response)
	            	
	            	new_tweet = @twitter.update(response, :in_reply_to_status_id => status.id)
	            	
	            	puts new_tweet.text 
	            	puts "@" + (Time.now).to_s + "\n" + "\n"

	            	add_reply(new_tweet.id, response.to_s)
	            	
	            end
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

main