# Ruby AD-Unlocker
#  Author: Richard Kohlbrecher
#
# Last updated June.17.2013

require 'net/ldap'
require 'sinatra'
require 'twilio-ruby'
require 'logger'

before do
	@logfile = File.open('Log/ttuLogfile.log', File::WRONLY | File::APPEND | File::CREAT)
	@log = Logger.new(@logfile, 10, 1024000)
	@log.level = Logger::INFO
end

get '/password' do

status = "Error !"

numbers = Array.new
File.open('numbers.txt').each do |line|
	numbers << line.split('#')[0] if line.include? '#'
end
mobile = params[:From].split(//).last(10).join

password = "<LDAP Account Password>"

ldap = Net::LDAP.new :host => "<LDAP IP Address>",
	:port => 389,
	:auth => {
		:method => :simple,
		:username => "<cn=account, ou=path, dc=example, dc=com>",
		:password => password
	}

if ldap.bind
	ldapuser = "Error !"

	if (numbers.include?(mobile) == true)
		user = params[:Body]
		filter = Net::LDAP::Filter.eq("UserPrincipalName", "#{user}@ <domain> .com")
		status = "Invalid account name !"
	else
		filter = Net::LDAP::Filter.eq("mobile", mobile)
		status = "Number not recognised !"
	end #if
	treebase = ("<ou=pathTo, dc=liveUsers, dc=com>")

	ldap.search(:base => treebase, :filter => filter) do |entry|
		udn = entry.dn
		ldapuser = entry.userPrincipalName

		if (entry.lockoutTime == ["0"])
			status = "Account was not locked !"
		else
			ldap.replace_attribute udn, :lockoutTime, "0"
			status = "Account was unlocked !"
		end #if
	end #ldap.search

	@log.info("ttu_mobile=#{mobile} ttu_bind=Success ttu_admuser=#{user} ttu_user=#{ldapuser} ttu_status=#{status}")

else
	@log.error("ttu_moblie=#{mobile} ttu_bind=Fail ttu_status#{status}")
end #if

twiml = Twilio::TwiML::Response.new do |r|
	r.sms "#{status} #{user}"
end
twiml.text

end

after do
	@logfile.close
end

get "/" do
     "Hello"
end

not_found do
     redirect '/', 301
end

error do
     "An error occurred"
end