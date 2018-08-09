module Fastlane
  module Actions
    class IosLocalizeProjectAction < Action
      def self.run(params)
        UI.message "Updating project localisation..."

        require_relative '../helpers/ios_git_helper.rb'
        Fastlane::Helpers::IosGitHelper.localize_project()
        
        UI.message "Done."
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Gathers the string to localise"
      end

      def self.details
        "Gathers the string to localise"
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
