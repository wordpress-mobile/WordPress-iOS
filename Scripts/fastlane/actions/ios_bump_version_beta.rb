module Fastlane
  module Actions
    class IosBumpVersionBetaAction < Action
      def self.run(params)
        UI.message "Bumping app release version..."
         
        require_relative '../helpers/ios_git_helper.rb'
        Fastlane::Helpers::IosGitHelper.bump_version_beta
        
        UI.message "Done."
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Bumps the version of the app for a new beta"
      end

      def self.details
        "Bumps the version of the app for a new beta"
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
