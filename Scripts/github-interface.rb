#!/usr/bin/env ruby
require 'Octokit'

# TODO: Add proper logging
# TODO: Add comments!!
class GitHubInterface
  attr_reader :repository

  def initialize(repository)
    @repository = repository

    check_dependencies
    create_client
  end

  def get_branch_protection(branch_name)
    @client.branch_protection(@repository, branch_name)
  end

  def set_branch_protection(branch_name)
    branch_prot = {}

    branch_url = "https://api.github.com/repos/wordpress-mobile/WordPress-iOS/branches/" + branch_name
    branch_prot[:required_status_checks] = {:url=>branch_url + "/protection/required_status_checks", :strict=>true, :contexts=>["Buddybuild : WordPress/57a120bbe0f5520100e11c19"], :contexts_url=>branch_url + "/protection/required_status_checks/contexts"}
    branch_prot[:restrictions] = {:url=>branch_url + "/protection/restrictions", :users_url=>branch_url + "/protection/restrictions/users", :teams_url=>branch_url + "/protection/restrictions/teams", :users=>[], :teams=>[]}
    branch_prot[:enforce_admins] = nil
    branch_prot[:required_pull_request_reviews] = {:url=>branch_url + "/protection/required_pull_request_reviews", :dismiss_stale_reviews=>false, :require_code_owner_reviews=>false}
    @client.protect_branch(@repository, branch_name, branch_prot)
  end

  def get_opens_for(release)
    miles = @client.list_milestones(@repository)
    mile = nil
    miles&.each do |mm| 
      if mm[:title].start_with?(release)
        mile = mm
      end
    end

    if (mile == nil)
      return nil
    end 

    open_prs = get_open_prs(mile[:number]) # TODO: Returning an array with PR titles and URL here... can be used. 
    return {:mile => mile, :is_frozen => is_frozen(mile), :open_prs => open_prs}
  end

  private
  def check_dependencies
    unless Gem::Specification::find_all_by_name("octokit").any?
      raise "This script requires the \'octokit\' gem. You can install it by running \'gem install octokit\'\n"
    end
  end

  def create_client
    # Provide authentication credentials
    # TODO: Add login info here!
    @client = Octokit::Client.new(:netrc => true)

    # Fetch the current user
    user = @client.user
    puts "Logged in as: " + user.name
  end

  def is_frozen(milestone)
    unless (milestone.nil?)
      return milestone[:title].include?("❄️")
    end

    return false
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
  release = ARGV[1]
  puts release

  case ARGV[0]
  when "set_prot"
    gi.set_branch_protection("release/" + release)
  when "list_open"
    release_data = gi.get_opens_for(release)
    if (release_data.nil?)
      puts "Releasae #{release} not found in GitHub milestones"
    else
      milestone_description = release_data[:mile][:title]
      milestone_description = milestone_description + " (frozen)" unless !release_data[:is_frozen]
      puts "Release #{milestone_description} has"
      puts " - #{release_data[:mile][:open_issues]} open issues" 
      puts " - #{release_data[:open_prs].length} open PRs" 
      puts "   link: https://github.com/wordpress-mobile/WordPress-iOS/pulls?q=is%3Aopen+is%3Apr+milestone%3A#{release}" unless release_data[:open_prs].length == 0
    end
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