# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
set :path, File.expand_path(File.join(File.dirname(__FILE__)))
set :cron_log, "#{path}/log/cron_log.log"

every 1.hours do
  command "cd #{path} && ruby import.rb sync"
end

# Learn more: http://github.com/javan/whenever
