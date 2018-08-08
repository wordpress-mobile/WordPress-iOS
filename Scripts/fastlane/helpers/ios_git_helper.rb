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
          return true
        rescue
          return false
        end
      end

    end
  end
end