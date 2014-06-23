require 'mail' # $ gem install mail
require 'csv'
require 'crowdflower'

subject_message = 'Happiness Survey - Follow Up' #ENTER THE SUBJECT LINE OF THE EMAIL HERE

user_name = 'adrian.zarifis@crowdflower.com' #ENTER YOUR GMAIL LOGIN (CROWDFLOWER USER NAME @ DOMAIN) HERE, 
										#FOR EXAMPLE: adrian.zarifis@crowdflower.com

password = '' #ENTER YOUR GMAIL PASSWORD HERE

job_id = 477026
AUTH_KEY = "oQc2Qcas1Ay1p5CftCzf"
DOMAIN_BASE = "https://api.crowdflower.com"

internal_link = 'https://tasks.crowdflower.com/channels/cf_internal/jobs/477026/work?secret=KXieSxvAnrRWCwPNO%2F%2F32yFuAz%2BTL3b8ftgKprZ6Dkph'

CrowdFlower::Job.connect! AUTH_KEY, DOMAIN_BASE

job_resource = CrowdFlower::Job.new(job_id)
#worker_resource = CrowdFlower::Worker.new(job_resource)
#unit = CrowdFlower::Unit.new(job_id)

time = Time.new
month = time.month
month = month.to_s

HTTParty.post("https://api.crowdflower.com/v1/jobs/#{job_id}/regenerate?type=full&key=#{AUTH_KEY}")

puts "Regenerated the Full Report"

job_resource.download_csv(:full, "happiness_report_#{month}.zip")

puts "Downloaded the Full Report"

`open happiness_report_#{month}.zip`

puts "Opened the Full Report"

class String
	def initial
		self[0,1]
	end
end

worked = []

full = "f#{job_id}.csv"

puts "Waiting 5 seconds for the file to stablize"
sleep(5)

CSV.foreach(full, :headers => true) do |row|
	date = row["_created_at"]
	if date.initial == month
		worked << row["_worker_id"]
	end
end

puts "Constructed the list of worker IDs who completed the survey this month"

headers = []

CSV.foreach("CF_Employees.csv") do |row|
	row_counter = 1
	headers = row
	row_counter += 1
	break if row_counter > 1
end

more_headers = ["#{month}"]

CSV.open("CF_Employees_modified.csv", "wb", :headers => headers + more_headers, :write_headers => true) do |out|
	CSV.foreach("CF_Employees.csv", :headers => true) do |row|

		email = row["email"]
		first_name = row["first_name"]
		last_name = row["last_name"]
		id = row["id"]

		if worked.include? id
			row << "true"
		else
			row << "false"
		end

		out << row

	end

end

puts "Determined which services members completed the survey this month"

options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'crowdflower.com',
            :user_name            => user_name,
            :password             => password,
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

Mail.defaults do
	delivery_method :smtp, options
end

slackers = []

CSV.foreach("CF_Employees_modified.csv", :headers => true) do |row|
	first_name = row["first_name"]
	last_name = row["last_name"]
	email = row["email"]
	did_it = row[month]
	full_name = "#{first_name} #{last_name}"

	if did_it == "false"
		body_message = "#{first_name}, quit being a slacker and complete the Happiness Survey. It's been 3 days already!\n\nThe survey can be found here: #{internal_link}" #ENTER THE BODY OF THE EMAIL HERE
		slackers << full_name

		Mail.deliver do
			to email
			from user_name
			subject subject_message
			body body_message
		end
	end
end

puts "Emailed everyone who did not yet complete the survey"

slacker_list = slackers.join("\n")

Mail.deliver do
	to "borourke@crowdflower.com"
	from user_name
	subject "Happiness Survey Slackers"
	body "Here is the list of slackers who have not yet completed the Happiness Survey:\n#{slacker_list}"
end

puts "Emailed Bryan with the list of slackers"

	
		












