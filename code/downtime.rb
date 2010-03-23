#!/usr/bin/ruby
require 'yaml'
require 'time'
require 'date'
require 'optparse'

#    Copyright (C) 2009  John E. Vincent - http://dev.lusis.org/nagios/
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 2
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Set some default options
OPTIONS = {
    :config => "/etc/nagios/downtime.cfg"
}

OptionParser.new do |opts|
    script_name = File.basename($0)
    opts.banner = "Usage: #{script_name} [options]"
    opts.define_head    "Ruby script to schedule reoccuring downtime. Configuration is defined in config.yaml.
			Schedules are defined in 'host_schedule.yaml' and 'service_schedule.yaml'"

    opts.on("-v", "--verbose", "Run Verbosely") do |v|
        OPTIONS[:verbose] = v
    end
    opts.on("-d", "--display", "Display current configuration and schedules") do |d|
        OPTIONS[:display] = d
    end
    opts.on("-c", "--config c", String, "Config file to use. Defaults /etc/nagios/downtime.cfg") do |c|
        OPTIONS[:config] = c
    end
    opts.on("-a", "--add", "Schedule a new downtime.") do |a|
		OPTIONS[:add] = a
    end
    opts.on("-r", "--remove", "Remove a downtime.") do |r|
		OPTIONS[:remove] = r
    end
    opts.on("-i", "--initialize", "Initialize a new configuration") do |i|
		OPTIONS[:initialize] = i
    end
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

def parse_entry

end

def gen_svc_downtime(host,service,starttime,endtime,occurance,comment)
    starttime = gen_dstamp(starttime,occurance)
    endtime = gen_dstamp(endtime,occurance)
    return "[#{Time.now.to_i}] SCHEDULE_SVC_DOWNTIME;#{host};#{service};#{starttime};#{endtime};1;0;7200;Nagios System Account;#{comment}"
end

def gen_host_downtime

end

def schedule_downtime(nagcmdline)
    File.open(NAGIOS_CMD_FILE,'a') { |f| f.write("#{nagcmdline}\n") }
    puts "'#{nagcmdline}' written to #{NAGIOS_CMD_FILE}\n" if OPTIONS[:verbose]
end

def convert_occurance(occurance="daily", arr=[])
   case occurance
   when 'tomorrow'
	dtdate = Date.today + 1
   when 'daily'
       dtdate = Date.today
   when 'monthly'
       dtdate = Date.today >> 1
   when 'annually'
       dtdate = Date.today >> 12
   end
   return dtdate
end

def gen_dstamp(dttime,occurance)
    dtdate = convert_occurance(occurance)
    dstamp = Time.local(dtdate.year,dtdate.month,dtdate.day,dttime).to_i
    return dstamp
end

def display_config
    puts "Displaying the current configuration and schedules"
    puts ""
    puts "\t\e[4m\e[1mConfiguration Options\e[0m"
    puts "\t\t\e[1mConfiguration File\e[0m\t#{OPTIONS[:config]}"
    puts "\t\t\e[1mNagios Command File\e[0m\t#{NAGIOS_CMD_FILE}"
    puts "\t\t\e[1mService Schedule File\e[0m\t#{CONFIG['service_schedule_file']}"
    puts ""
    puts "\t\e[4m\e[1mDefined Schedules\e[0m"
    $svc_schedule.each_key do |host|
        puts "\t\t\e[1m#{host}\e[0m"
        $svc_schedule[host].each_key do |service|
	    details = $svc_schedule[host][service]
            puts "\t\t\t\e[1m#{service}\e[0m"
            puts "\t\t\t\t\e[1mDowntime Start\e[0m\t\e[32m#{details['start']}\e[0m"
            puts "\t\t\t\t\e[1mDowntime End\e[0m\t\e[31m#{details['stop']}\e[0m"
            puts "\t\t\t\t\e[1mOccurance\e[0m\t\e[34m#{details['occurance']}\e[0m"
            puts "\t\t\t\t\e[1mComment\e[0m\t\t\e[33m#{details['comment']}\e[0m"
            puts ""
        end
    end
    exit
end

def add_downtime_interactive
    new_entry = Hash.new
    puts "Please answer the following questions accurately. There is currently no validation for new entries. If you mistype the hostname or service name, no downtime will be created"
    puts "\e[1mHostname?\e[0m"
    host = gets.chomp
    new_entry[host] = Hash.new
    puts "\e[1mService?\e[0m"
    service = gets.chomp
    puts "\e[1mStart Time?\e[0m"
    start = gets.chomp
    puts "\e[1mStop Time?\e[0m"
    stop = gets.chomp
    puts "\e[1mOccurance? (currently only 'daily' is honored)\e[0m"
    occurance = gets.chomp
    puts "\e[1mComment?\e[0m"
    comment = gets.chomp
    new_entry[host][service] = {"start"=>start,"stop"=>stop,"occurance"=>occurance,"comment"=>comment}
    add_downtime(new_entry)
end

def del_downtime_interactive
    hostsvcpair = Hash.new
    x = 0
    allhosts = enum_hosts($svc_schedule)
    allhosts.each do |host|
		hostservices = enum_services(host)
		hostservices.each do |service|
			x = x+1
			hostsvcpair[x] = {"host"=>host,"service"=>service}
			puts "\e[1m#{x}\e[0m - #{host} - #{service}"
		end
    end
    puts "Please pick a service to delete by entering the ID of the service entry:"
    service_id = gets.chomp.to_i
    puts "You are requesting to delete the downtime ID #{service_id}: #{hostsvcpair[service_id]["host"]} - #{hostsvcpair[service_id]["service"]}. Is this correct? (Y/N)"
    if enum_services(hostsvcpair[service_id]["host"]).length == 1 then
		puts "You are removing the only service for #{hostsvcpair[service_id]["host"]}. Doing so will remove the host from the configuration as well."
    end
    if gets.chomp == 'Y' then
		delete_downtime(hostsvcpair[service_id]["host"],hostsvcpair[service_id]["service"])
    else
		puts "Not deleting anything."
    end
    
    exit
end

def add_downtime(entry)
	if $svc_schedule.has_key?("#{entry.keys.to_s}") then
		host_schedule = $svc_schedule["#{entry.keys.to_s}"].merge(entry["#{entry.keys.to_s}"])
		$svc_schedule["#{entry.keys.to_s}"] = host_schedule
	else
		$svc_schedule.merge!(entry)
	end
	
    open(CONFIG['service_schedule_file'], 'w') { |f| YAML.dump($svc_schedule, f) }
    exit
end

def delete_downtime(host,service)
    $svc_schedule[host].delete(service)
    if enum_services(host).length == 0 then
		$svc_schedule.delete(host)
    end
    open(CONFIG['service_schedule_file'], 'w') { |f| YAML.dump($svc_schedule, f) }
    exit
end

def validate_downtime
    
end

def enum_hosts(svchash)
    hosts = Array.new
    svchash.each_key do |host|
		hosts << host
    end
    return hosts
end

def enum_services(host)
    services = Array.new
    $svc_schedule[host].each_key do |service|
		services << service
    end
    return services
end

def main
    $svc_schedule.each_key do |host|
        puts "Host - #{host}\n" if OPTIONS[:verbose]
        $svc_schedule[host].each_key do |service|
	    details = $svc_schedule[host][service]
            schedule_downtime(gen_svc_downtime(host,service,details['start'],details['stop'],details['occurance'],details['comment']))
        end
    end
end

def setup
	puts "You are about to be asked a series of questions to help setup your downtime scheduling."
	puts "Please verify each entry before submitting as there is currently NO validation for user input."
	puts "Enter the full path and filename of the Nagios External Command File (e.g. /var/spool/nagios/rw/nagios.cmd):"
	nagios_command_file	= gets.chomp
	puts "Enter the path for the Nagios configuration directory (usually /etc/nagios or /usr/local/etc/nagios):"
	config_path = gets.chomp
	puts "Three files will be created in the path you have entered: downtime.cfg, host_schedule.cfg and svc_schedule.cfg."
	puts "These are YAML files. Feel free to inspect them but be warned that if you break them, you will need to reinitialize and readd your services."
	puts "Do this at your own risk"
	config_file = config_path + "/downtime.cfg"
	service_file = config_path + "/svc_schedule.cfg"
	host_file = config_path + "/host_schedule.cfg"
	base_yaml = "--- #Empty schedule file"
	config = {"nagios_cmd_file"=>nagios_command_file, "service_schedule_file"=>service_file, "host_schedule_file"=>host_file}
	open(config_file, "w") { |f| YAML.dump(config, f) }
	File.open(service_file, 'w') {|f| f.write(base_yaml) }
	File.open(host_file, 'w') {|f| f.write(base_yaml) }
	puts "Config files created. Please run: 'downtime.rb -c #{config_file} -a' to add services"
	exit
end

setup if OPTIONS[:initialize]
begin
	CONFIG              = YAML::load(File.open(OPTIONS[:config]))
rescue
	setup
end

begin
	$svc_schedule        = YAML::load(File.open(CONFIG['service_schedule_file']))
        if $svc_schedule.nil? then
            $svc_schedule=Hash.new
        end
rescue
	$svc_schedule 		= Hash.new
end

NAGIOS_CMD_FILE     = CONFIG['nagios_cmd_file']
# We're not doing host downtime right now
#host_schedule       = YAML::load(File.open(config['host_schedule_file']))

display_config if OPTIONS[:display]
add_downtime_interactive if OPTIONS[:add]
del_downtime_interactive if OPTIONS[:remove]
main
