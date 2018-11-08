module Fastlane
  module Actions
    class IosBuildPreflightAction < Action
      def self.run(params)
        # Ensure mobile secrets are up to date. This will do nothing if not a git repo
        secrets_git_dir = File.expand_path('~/.mobile-secrets/.git')
        if File.exist?(secrets_git_dir)
          Action.sh("git --git-dir \"#{secrets_git_dir}\" pull")
        end

        Action.sh("cd .. && rm -rf ~/Library/Developer/Xcode/DerivedData")
        Action.sh("rake clobber")
        Action.sh("rake dependencies")
        other_action.cocoapods()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Clean the environment to ensure a safe build"
      end

      def self.details
        "Clean the environment to ensure a safe build"
      end

      def self.available_options
        
      end

      def self.output
        
      end

      def self.return_value
       
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
