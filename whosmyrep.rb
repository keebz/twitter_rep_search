require 'bundler/setup'
require 'dotenv'
require 'rest_client'
require 'nokogiri'
require 'people'

Dotenv.load

Bundler.require(:default)

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

	puts "Tracking...@whosmyrep"
	track('@whosmyrep')
	# rep_search(['or'])
	# donor_info('FL')
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
			@keywords = []

		  	@status.hashtags.each do |hash|
		  		@keywords << hash.attrs[:text].downcase
	      end

			@rep1_info = "Nothing Found! Please use a hashtag followed by your state. Example: #OH or even #ohio."
			@rep2_info = nil
			@governor = nil

	        rep_search(@keywords)

        	response1 = "@#{@status.user.screen_name}" + " " + @rep1_info
        	new_tweet1 = @twitter.update(response1, :in_reply_to_status_id => status.id)
        	puts new_tweet1.text + "\n\n"

        	if @rep2_info != nil
        		response2 = "@#{@status.user.screen_name}" + " " + @rep2_info
        		new_tweet2 = @twitter.update(response2, :in_reply_to_status_id => status.id)
        		puts new_tweet2.text + "\n\n"
        	end

        	if @governor != nil
        		response3 = "@#{@status.user.screen_name}" + " " + @governor
        		new_tweet3 = @twitter.update(response3, :in_reply_to_status_id => status.id)
        		puts new_tweet3.text + "\n\n"
        	end

        	puts "@" + (Time.now).to_s + "\n\n"

       	end
	end
end

def rep_search(keywords)
	@civicaide = CivicAide::Client.new(GOOGLE_API_KEY)

	keywords.each do |keyword|
		begin
			build_rep(@civicaide.representatives.at(keyword))
			break
		rescue

		end
	end
end

def build_rep(rep_hash)
	@state = rep_hash["normalized_input"]["state"]
	@names = []
	parties = []
	phones = []
	emails = []
	twitters = []
	rep_ids = []
	@top_donors = []

	rep_hash["offices"].each do |office_tag|
	    office_tag.each do |office|
	        if office["name"] == "United States Senate"
           office["official_ids"].each do |id|
           		rep_ids << id
	       	 end

		      elsif office["name"] == "Governor"
	       		id = office["official_ids"].join.downcase
	       		name = ""
	       		party = ""
	       		phone = "Phone:Unlisted"
	       		email = "Email:Unlisted"
	       		url = "URL:Unlisted"

							name = rep_hash["officials"][id]["name"]
							party = rep_hash["officials"][id]["party"]
							if rep_hash["officials"][id]["phones"]
								phone = rep_hash["officials"][id]["phones"].first
							end

							if rep_hash["officials"][id]["emails"]
								email = rep_hash["officials"][id]["emails"].first
							end

							if rep_hash["officials"][id]["urls"]
								url = rep_hash["officials"][id]["urls"].first
							end

	       		@governor = "Gov. " + name + " " + party + " " + phone + " " + email + " " + url

		    	end
	    end
	end

	rep_ids.each do |id|
	  id.downcase!

	  np = People::NameParser.new
	  rep_name = rep_hash["officials"][id]["name"]
	  name = np.parse(rep_name)
	  lastname = name[:last].upcase!

	  donor_info(@state, lastname)

	  @names << rep_name

	  if rep_hash["officials"][id]["party"] == "Democratic"
	  	parties << "(D) "
	  elsif rep_hash["officials"][id]["party"] == "Republican"
	  	parties << "(R) "
	  else
	  	parties << "(I) "
	  end

	  if rep_hash["officials"][id]["emails"] != nil
	  	emails << rep_hash["officials"][id]["emails"].first
	  elsif rep_hash["officials"][id]["urls"] !=nil
	  	emails << rep_hash["officials"][id]["urls"].first
	  else
	  	emails << " UNLISTED Email"
	  end

	  if rep_hash["officials"][id]["phones"] != nil
	  	phones << rep_hash["officials"][id]["phones"].first
	  else
	  	phones << "UNLISTED Phone"
	  end

	  if rep_hash["officials"][id]["channels"].find { |t| t["type"] == "Twitter"} != nil

		twitters << "@" + rep_hash["officials"][id]["channels"].find { |t| t["type"] == "Twitter"} ["id"]

	  else
	  	twitters << "#VOTE"
	  end

	end

		@rep1_info = "Sen. " + @names[0] + " " + parties[0] + emails[0] + " " + phones[0] + " Funded By: " + @top_donors[0]

		@rep2_info = "Sen. " + @names[1] + " " + parties[1] + emails[1] + " " + phones[1] + " Funded By: " + @top_donors[1]

end

def donor_info(state, lastname)

	@CID = ""
	response = RestClient.get("http://www.opensecrets.org/api/?method=getLegislators&id=#{state}&apikey=#{ENV['donor_data_key']}")
	doc = Nokogiri::XML(response)

	doc.children.children.each do |rep|

		if rep.attributes["lastname"].value == lastname
			@CID = rep.attributes["cid"].value
		end
	end

	donorxml = RestClient.get("http://www.opensecrets.org/api/?method=candContrib&cid=#{@CID}&cycle=2012&apikey=#{ENV['donor_data_key']}")
	donordoc = Nokogiri::XML(donorxml)
	top_donor_name = donordoc.children.children.children.first.attributes["org_name"].value
	top_donor_amount = "$"+donordoc.children.children.children.first.attributes["total"].value
	@top_donor = top_donor_name + " = " + top_donor_amount
	@top_donors << @top_donor
end


main
