module Fastlane
  module Actions
    class IosCurrentBranchIsHotfixAction < Action
      def self.run(params)
        require_relative '../helpers/ios_version_helper.rb'
        Fastlane::Helpers::IosVersionHelper::is_hotfix(Fastlane::Helpers::IosVersionHelper::get_public_version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Checks if the current branch is for a hotfix"
      end

      def self.details
        "Checks if the current branch is for a hotfix"
      end

      def self.available_options
        
      end

      def self.output
        
      end

      def self.return_value
        "True if the branch is for a hotfix, false otherwise"
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
