module Fastlane
  module Actions    
    class IosBumpVersionReleaseAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Bumping app release version..."
        
        other_action.sh(command: "./manage-version.sh bump-release")
        other_action.sh(command: "cd .. && git add ./config/.")
        other_action.sh(command: "git add fastlane/Deliverfile")
        other_action.sh(command: "git add fastlane/download_metadata.swift")
        other_action.sh(command: "git add ../WordPress/Resources/AppStoreStrings.po")
        other_action.sh(command: "git commit -m \"Bump version number\"")
        other_action.sh(command: "git push")
        
        UI.message "Done."
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Bumps the version of the app and creates the new release branch"
      end

      def self.details
        "Bumps the version of the app and creates the new release branch"
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
