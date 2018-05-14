# WPiOS Scripts #

This folder contains some helper scripts that can be used to automate those boring repetitive tasks. 

## github-helper.rb
This script wraps some interfaces to the GitHub API and exposes some helpers for app release related tasks. 

### Requirements/Installation
The script requires the Octokit.rb library. If you don't have it, you can install running 'gem install octokit' in a shell. 

The script requires login credentials for connecting the API. Administrator privileges are required for some operations.
The script expects a `~/.netrc` file with the following content: 
`machine api.github.com
	login <username>
	password <password>`

If you use two factor authentication, you can substitute the password with an App key code. 

### Usage
The script exposes the following commands:

#### list_open
Lists the open issue and PRs set for the given milestone.

Usage: `github-helper.rb list_open <milestone>`

Example: `github-helper.rb list_open 10.0` 

#### set_prot
Sets the standard branch protection options that this project uses for release branches.

Usage: `github-helper.rb set_prot <milestone>`

Example: `github-helper.rb set_prot 10.0`

#### set_frozen
Sets the frozen flag for the given milestone.

Usage: `github-helper.rb set_frozen <milestone>`

Example: `github-helper.rb set_frozen 10.0`

#### get_frozen
Returns the state of the frozen flag for the given milestone

Usage: `github-helper.rb get_frozen <milestone>`

Example: `github-helper.rb get_frozen 10.0`


## Note: This is a partial list that shall be updated in the future. 
