require 'tweetstream'
require 'pry'
require 'oj'
require 'bundler/setup'
require 'pry'
require 'pg'

Bundler.require(:default)

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
ActiveRecord::Base.establish_connection(YAML::load(File.open('./db/config.yml'))["development"])

DB = PG.connect({:dbname => 'whosmyrep_console_development'})

@states = { "or" => "Oregon Information", 
			"ca" => "California Information",
			"fl" => "Florida Information",
			"tn" => "Tennessee Information",
			"mi" => "Michigan Information",
			"al" => "Alabama Information"}

	TweetStream.configure do |config|
	  config.consumer_key       = 'LDNk55uXbOoG1f4ZCvFspZW9l'
	  config.consumer_secret    = 'xlpFEIl8SkFgViLDwQe2b3yJ7clLCBsgNaxDOp1Q7wmpQuknqC'
	  config.oauth_token        = '150020012-5V4DUTwu9xJ6aF3ZY6mK0MdHLVMNKnSuXlRVA1IA'
	  config.oauth_token_secret = 'w0x56NiADq4fTuVtG8nsFYKL1BIwxUtx8x0ce9zO4KG9L'
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

		@twitter = Twitter::REST::Client.new do |config|
		  config.consumer_key        = 'LDNk55uXbOoG1f4ZCvFspZW9l'
		  config.consumer_secret     = 'xlpFEIl8SkFgViLDwQe2b3yJ7clLCBsgNaxDOp1Q7wmpQuknqC'
		  config.access_token        = '150020012-5V4DUTwu9xJ6aF3ZY6mK0MdHLVMNKnSuXlRVA1IA'
		  config.access_token_secret = 'w0x56NiADq4fTuVtG8nsFYKL1BIwxUtx8x0ce9zO4KG9L'
		end

		@status = status

		if @status.hashtags != nil
		  	@status.hashtags.each do |hash|
	            if @states.include?(hash.attrs[:text].downcase)
	            	response = "@#{@status.user.screen_name}" + " " + @states[hash.attrs[:text].downcase]
	            	
	            	scrub_reply(response)
	            	
	            	new_tweet = @twitter.update(response, :in_reply_to_status_id => status.id)
	            	
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