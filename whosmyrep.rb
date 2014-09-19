require 'tweetstream'
require 'pry'
require 'oj'
@states = { "or" => "Oregon Information", 
			"ca" => "California Information",
			"fl" => "Florida Information"}

	TweetStream.configure do |config|
	  config.consumer_key       = 'LDNk55uXbOoG1f4ZCvFspZW9l'
	  config.consumer_secret    = 'xlpFEIl8SkFgViLDwQe2b3yJ7clLCBsgNaxDOp1Q7wmpQuknqC'
	  config.oauth_token        = '150020012-5V4DUTwu9xJ6aF3ZY6mK0MdHLVMNKnSuXlRVA1IA'
	  config.oauth_token_secret = 'w0x56NiADq4fTuVtG8nsFYKL1BIwxUtx8x0ce9zO4KG9L'
	  config.auth_method        = :oauth
	end

	@twitter = Twitter::REST::Client.new do |config|
	  config.consumer_key        = 'LDNk55uXbOoG1f4ZCvFspZW9l'
	  config.consumer_secret     = 'xlpFEIl8SkFgViLDwQe2b3yJ7clLCBsgNaxDOp1Q7wmpQuknqC'
	  config.access_token        = '150020012-5V4DUTwu9xJ6aF3ZY6mK0MdHLVMNKnSuXlRVA1IA'
	  config.access_token_secret = 'w0x56NiADq4fTuVtG8nsFYKL1BIwxUtx8x0ce9zO4KG9L'
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
		@status = status
		if @status.hashtags != nil
		  	@status.hashtags.each do |hash|
	            if @states.include?(hash.attrs[:text].downcase)
					time = Time.new
	            	response = "as of " + time.to_s + " @#{@status.user.screen_name}" + " " + @states[hash.attrs[:text].downcase]
	            	@twitter.update(response, :in_reply_to_status_id => status.id)
	            end
	        end
    	end
	end
end

main