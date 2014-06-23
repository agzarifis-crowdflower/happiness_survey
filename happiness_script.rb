require 'mail' # $ gem install mail
require 'csv'
require 'crowdflower'

csv_name = 'CF_Employees.csv' #ENTER THE FILE PATH OF THE CSV, 
								#OR SIMPLY THE NAME IF RUNNING THE SCRIPT FROM THE SAME DIRECTORY,
								#CONTAINING THE NAMES AND EMAILS OF EVERY RECIPIENT

subject_message = 'Happiness Survey' #ENTER THE SUBJECT LINE OF THE EMAIL HERE

internal_link = 'https://tasks.crowdflower.com/channels/cf_internal/jobs/477026/work?secret=KXieSxvAnrRWCwPNO%2F%2F32yFuAz%2BTL3b8ftgKprZ6Dkph'

user_name = 'adrian.zarifis@crowdflower.com' #ENTER YOUR GMAIL LOGIN (CROWDFLOWER USER NAME @ DOMAIN) HERE, 
										#FOR EXAMPLE: adrian.zarifis@crowdflower.com

password = '' #ENTER YOUR GMAIL PASSWORD HERE

job_id = 477026
AUTH_KEY = "oQc2Qcas1Ay1p5CftCzf"
DOMAIN_BASE = "https://api.crowdflower.com"

CrowdFlower::Job.connect! AUTH_KEY, DOMAIN_BASE

job_resource = CrowdFlower::Job.new(job_id)
# worker_resource = CrowdFlower::Worker.new(job_resource)
unit = CrowdFlower::Unit.new(job_resource)

numrows = CSV.readlines(csv_name, :headers => true).size
time = Time.new
month = time.month

for i in 1..numrows
	unit.create("month"=>month)
end

max_judgments_per_ip = job_resource.get["max_judgments_per_ip"]
max_judgments_per_worker = job_resource.get["max_judgments_per_worker"]

max_judgments_per_ip = max_judgments_per_ip + 1
max_judgments_per_worker = max_judgments_per_worker + 1

job_resource.update("max_judgments_per_ip"=>max_judgments_per_ip)
job_resource.update("max_judgments_per_worker"=>max_judgments_per_worker)

#order = CrowdFlower::Order.new(job_resource)
#order.debit(numrows, ["cf_internal", "diamondtask"])

curl_command = "curl -X POST -d 'key=#{AUTH_KEY}&channels[0]=cf_internal&debit[units_count]=#{numrows}' https://api.crowdflower.com/v1/jobs/#{job_id}/orders.json"

`#{curl_command}`

#curl -X POST 'https://api.crowdflower.com/v1/jobs/#{job_id}/orders.json?key=#{AUTH_KEY}&channels[0]=on_demand&debit[units_count]=6'

#curl -X POST 'https://api.crowdflower.com/v1/jobs/#{job_id}/orders.json?key=#{AUTH_KEY}&cf_internal&debit%5Bunits_count%5D=2'

#### EMAIL ALL SERVICES MEMBERS WITH THE INTERNAL LINK TO THE JOB ####



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

CSV.foreach(csv_name, :headers => true) do |row|
	first_name = row["first_name"]
	last_name = row["last_name"]
	email = row["email"]

	body_message = "Hey #{first_name}! The Happiness Survey is live for this month. Please complete the survey within 72 hours of this email.\n\nThe survey can be found here: #{internal_link}" #ENTER THE BODY OF THE EMAIL HERE

	Mail.deliver do
		to email
		from user_name
		subject subject_message
		body body_message
	end
end