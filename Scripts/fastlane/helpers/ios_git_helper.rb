module Fastlane
  module Helpers
    module IosGitHelper
     
      def self.git_checkout_and_pull(branch)
        Action.sh("git checkout #{branch}")
        Action.sh("git pull")
      end

      def self.git_checkout_and_pull_release_branch_for(version)
        branch_name = "release/#{version}"
        Action.sh("git pull")
        begin
          Action.sh("git checkout #{branch_name}")
          Action.sh("git pull origin #{branch_name}")
          return true
        rescue
          return false
        end
      end

      def self.branch_for_hotfix(tag_version, new_version)
        Action.sh("git checkout #{tag_version}")
        Action.sh("git checkout -b release/#{new_version}")
        Action.sh("git push origin release/#{new_version}")
      end
    end
  end
end