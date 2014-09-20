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

	# track(term)
	rep_search(term)
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

	            
	            	response1 = "@#{@status.user.screen_name}" + " Sen. " + @rep1_info
	            	
	            	scrub_reply(response1)

	            	response2 = "@#{@status.user.screen_name}" + " Sen. " + @rep2_info
	            	
	            	scrub_reply(response2)
	            	
	            	new_tweet1 = @twitter.update(response1, :in_reply_to_status_id => status.id)

	            	new_tweet2 = @twitter.update(response2, :in_reply_to_status_id => status.id)
	            	
	            	puts new_tweet1.text + "\n\n"

	            	puts new_tweet2.text + "\n\n"

	            	puts "@" + (Time.now).to_s + "\n\n"

	            	add_reply(new_tweet1.id, response1.to_s)
					
					add_reply(new_tweet2.id, response2.to_s)
	            	
	           
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
	names = []
	parties = []
	phones = []
	emails = []
	twitters = []
	rep_ids = []

	rep_hash["offices"].each do |office_tag|
	    office_tag.each do |office|  
	        if office["name"] == "United States Senate"    
	           office["official_ids"].each do |id|
	           rep_ids << id
		       end  
		    end  
	    end  
	end  

	rep_ids.each do |id|
	  id.downcase!  
	  names << rep_hash["officials"][id]["name"]
	  
	  if rep_hash["officials"][id]["party"] == "Democratic"
	  	parties << "D "
	  elsif rep_hash["officials"][id]["party"] == "Republican"
	  	parties << "R "
	  else
	  	parties << "I "
	  end

	  if rep_hash["officials"][id]["emails"] != nil
	  	emails << rep_hash["officials"][id]["emails"].first
	  else
	  	emails << rep_hash["officials"][id]["urls"].first
	  end

	  if rep_hash["officials"][id]["phones"] != nil
	  	phones << rep_hash["officials"][id]["phones"].first
	  else
	  	phones << rep_hash["officials"][id]["urls"].first
	  end

	  if rep_hash["officials"][id]["channels"].find { |t| t["type"] == "Twitter"} != nil
		
		twitters << "@" + rep_hash["officials"][id]["channels"].find { |t| t["type"] == "Twitter"} ["id"]
	  
	  else
	  	twitters << "#VOTE" 
	  end
  	    	    
	end 

	@rep1_info = names[0] + " " + parties[0] + emails[0] + " " + phones[0] + " " + twitters[0]

	@rep2_info = names[1] + " " + parties[1] + emails[1] + " " + phones[1] + " " + twitters[1]
	binding.pry 
end

main