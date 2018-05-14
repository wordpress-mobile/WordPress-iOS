#!/usr/bin/env ruby
require 'Octokit'

# TODO: Add proper logging
# A helper interface for performing some actions on GitHub
# It relies on GitHub's Octokit wrapper
class GitHubInterface
  attr_reader :repository   # The repository on which we work

  def initialize(repository)
    @repository = repository

    check_dependencies
    create_client
  end

  # Gets the protection state for branch_name
  def get_branch_protection(branch_name)
    @client.branch_protection(@repository, branch_name)
  end

  # Sets the "release branch" protection state for branch_name
  def set_branch_protection(branch_name)
    branch_prot = {}

    branch_url = "https://api.github.com/repos/#{@repository}/branches/" + branch_name
    branch_prot[:required_status_checks] = {:url=>branch_url + "/protection/required_status_checks", :strict=>true, :contexts=>["Buddybuild : WordPress/57a120bbe0f5520100e11c19"], :contexts_url=>branch_url + "/protection/required_status_checks/contexts"}
    branch_prot[:restrictions] = {:url=>branch_url + "/protection/restrictions", :users_url=>branch_url + "/protection/restrictions/users", :teams_url=>branch_url + "/protection/restrictions/teams", :users=>[], :teams=>[]}
    branch_prot[:enforce_admins] = nil
    branch_prot[:required_pull_request_reviews] = {:url=>branch_url + "/protection/required_pull_request_reviews", :dismiss_stale_reviews=>false, :require_code_owner_reviews=>false}
    @client.protect_branch(@repository, branch_name, branch_prot)
  end

  # Retrieves open PRs and open issues for milestone
  # It returns nil on not found milestones
  # otherwise returns an hash with:
  # :milestone_title -> the title of the milestone
  # :is_frozen -> true if the milestone has the frozen flag, false otherwise
  # :open_issues -> the list of open issues
  # :open_prs -> the list of open prs
  # :open_prs_link -> a link to the list of open prs on the web
  def get_opens_for(milestone)
    mile = get_milestone(milestone)

    if (mile == nil)
      return nil
    end 

    open_prs = get_open_prs(mile[:number]) # TODO: Returning an array with PR titles and URL here... can be used. 
    return {:milestone_title => mile[:title], :is_frozen => is_frozen(mile), :open_issues => mile[:open_issues], :open_prs => open_prs, :open_prs_link => "https://github.com/#{@repository}/pulls?q=is%3Aopen+is%3Apr+milestone%3A#{milestone}"}
  end

  # True if the milestone has the frozen flag
  def get_milestone_frozen_flag(milestone)
    return is_frozen(get_milestone(milestone))
  end

  # Sets the milestone's frozen flag
  def set_milestone_frozen_flag(milestone_title, freeze = true)
    milestone = get_milestone(milestone_title)
    if (milestone.nil?)
      raise "Milestone #{milestone} not found."
    end

    mile_title = milestone[:title]
    puts freeze
    if freeze
      # Check if the state needs changes 
      if (is_frozen(milestone))
        puts "Milestone #{mile_title} is already frozen. Nothing to do"
        return  # Already frozen: nothing to do
      end

      mile_title = mile_title + " ❄️"
    else
      mile_title = milestone_title
    end

    puts "New milestone: #{mile_title}"
    @client.update_milestone(@repository, milestone[:number], {:title => mile_title})
  end 


  private
  def check_dependencies
    unless Gem::Specification::find_all_by_name("octokit").any?
      raise "This script requires the \'octokit\' gem. You can install it by running \'gem install octokit\'\n"
    end
  end

  def create_client
    # Provide authentication credentials
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

  def get_milestone(release)
    miles = @client.list_milestones(@repository)
    mile = nil
    
    miles&.each do |mm| 
      if mm[:title].start_with?(release)
        mile = mm
      end
    end

    return mile
  end
end


# Local helpers
def show_usage
  puts "Usage:"
  puts " github-interface <command> <branch name> [optionals]"
  puts ""
  puts " Available commands:"
  puts " - list_open: lists the open issue and PRs set for the given milestone"
  puts " - set_prot: sets the branch protection for release branches"
  puts " - get_frozen: gets the state of the frozen flag for the given milestone"
  puts " - set_frozen: sets the state of the frozen flag for the given milestone. Add optional parameter 'false' to remove the flag."
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
    if (ARGV.length != 2)
      show_usage
      exit
    end
    gi.set_branch_protection("release/" + release)
  when "list_open"
    if (ARGV.length != 2)
      show_usage
      exit
    end
    release_data = gi.get_opens_for(release)
    if (release_data.nil?)
      puts "Releasae #{release} not found in GitHub milestones"
    else
      milestone_description = release_data[:milestone_title]
      milestone_description = milestone_description + " (frozen)" unless !release_data[:is_frozen]
      puts "Release #{milestone_description} has"
      puts " - #{release_data[:open_issues]} open issues" 
      puts " - #{release_data[:open_prs].length} open PRs" 
      puts "   link: #{release_data[:open_prs_link]}" unless release_data[:open_prs].length == 0
    end
  when "get_frozen"
    if (ARGV.length != 2)
      show_usage
      exit
    end
    puts "Release #{release} is " + (gi.get_milestone_frozen_flag(release) ? "frozen" : "not frozen")
  when "set_frozen"
    if (ARGV.length < 2) || ((ARGV.length > 3))
      show_usage
      exit
    end
    if (ARGV.length == 2)
      gi.set_milestone_frozen_flag(release)
    else
      gi.set_milestone_frozen_flag(release, ARGV[2] == "false" ? false : true)
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