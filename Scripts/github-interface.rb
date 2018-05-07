#!/usr/bin/env ruby
require 'Octokit'

# TODO: Add proper logging
# TODO: Add login credential management
# TODO: Add comments!!
class GitHubInterface
  attr_reader :repository

  def initialize(repository)
    @repository = repository

    check_dependencies
    create_client
  end

  def check_dependencies
    unless Gem::Specification::find_all_by_name("octokit").any?
      raise "This script requires the \'octokit\' gem. You can install it by running \'gem install octokit\'\n"
    end
  end

  def create_client
    # Provide authentication credentials
    # TODO: Add login info here!
    @client = Octokit::Client.new(:login => '', :password => '')

    # Fetch the current user
    user = @client.user
    puts "Logged in as: " + user.name
  end

  def get_branch_protection(branch_name)
    @current_branch_name = branch_name
    @current_branch_prot = @client.branch_protection(@repository, @current_branch_name)
  end

  def set_branch_protection(branch_name)
    @current_branch_name = branch_name
    @current_branch_prot = {}

    branch_url = "https://api.github.com/repos/wordpress-mobile/WordPress-iOS/branches/" + @current_branch_name 
    @current_branch_prot[:required_status_checks] = {:url=>branch_url + "/protection/required_status_checks", :strict=>true, :contexts=>["Buddybuild : WordPress/57a120bbe0f5520100e11c19"], :contexts_url=>branch_url + "/protection/required_status_checks/contexts"}
    @current_branch_prot[:restrictions] = {:url=>branch_url + "/protection/restrictions", :users_url=>branch_url + "/protection/restrictions/users", :teams_url=>branch_url + "/protection/restrictions/teams", :users=>[], :teams=>[]}
    @current_branch_prot[:enforce_admins] = nil
    @current_branch_prot[:required_pull_request_reviews] = {:url=>branch_url + "/protection/required_pull_request_reviews", :dismiss_stale_reviews=>false, :require_code_owner_reviews=>false}
    @client.protect_branch(@repository, @current_branch_name, @current_branch_prot)
  end

  def print_current_branch_protection
    if (@current_branch_prot != nil)
      puts "Branch protection for: " +@current_branch_name
      puts "required_status_checks"
      @current_branch_prot[:required_status_checks]&.each do |key,value|
        puts " - " + key.to_s + "=>" + value.to_s
      end
      puts "restrictions"
      @current_branch_prot[:restrictions]&.each do |key,value|
        puts " - " + key.to_s + "=>" + value.to_s
      end
      puts "enforce_admins"
      @current_branch_prot[:enforce_admins]&.each do |key,value|
        puts " - " + key.to_s + "=>" + value.to_s
      end
      puts "required_pull_request_reviews"
      @current_branch_prot[:required_pull_request_reviews]&.each do |key,value|
        puts " - " + key.to_s + "=>" + value.to_s
      end
    else
      puts "No branch loaded"
    end
  end

  def list_opens_for(release)
    miles = @client.list_milestones(@repository)
    mile = nil
    miles&.each do |mm| 
      if mm[:title].start_with?(release)
        mile = mm
      end
    end

    if (mile == nil)
      raise "Release #{release} not found."
    end 

    open_prs = get_open_prs(mile[:number]) # TODO: Returning an array with PR titles and URL here... can be used. 
    puts "Release #{release} has"
    puts " - #{mile[:open_issues]} open issues" 
    puts " - #{open_prs.length} open PRs" 
    puts "   link: https://github.com/wordpress-mobile/WordPress-iOS/pulls?q=is%3Aopen+is%3Apr+milestone%3A#{release}" unless open_prs.length == 0
  end

  def get_open_prs(milestone_number)
    @client.auto_paginate = true
    prs = @client.pull_requests(@repository, :state => 'open')
    res = []
    prs&.each do |pr|
      if (pr[:milestone] != nil) && (pr[:milestone][:number] == milestone_number)
        res.push(pr)
      end
    end
    @client.auto_paginate = false
    res
  end
end


# Local helpers
def show_usage
  puts "Usage:"
  puts " github-interface <command> <branch name>"
  puts ""
  puts " Available commands:"
  puts " - list_open: lists the open issue and PRs set for the given milestone"
  puts " - set_prot: sets the branch protection for release branches"
  puts ""
end

# Script main
if (ARGV.length < 2)
  show_usage
  exit
end
begin
  gi = GitHubInterface.new('wordpress-mobile/wordpress-iOS')
  branch = ARGV[1]
  puts branch

  case ARGV[0]
  when "set_prot"
    gi.set_branch_protection("release/" + branch)
  when "list_open"
    gi.list_opens_for(branch)
  else
    exit
  end
rescue SystemExit
  show_usage
rescue Exception => e
  puts "An error occurred: " + e.message
  puts e.backtrace.inspect
else
  puts "Success!"
end