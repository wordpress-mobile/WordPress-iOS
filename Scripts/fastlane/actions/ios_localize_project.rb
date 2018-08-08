module Fastlane
  module Actions
    class IosLocalizeProjectAction < Action
      def self.run(params)
        UI.message "Updating project localisation..."

        other_action.sh(command: "cd .. && ./Scripts/localize.py")
        other_action.sh(command: "cd .. && git add ./WordPress/Resources/.")
        other_action.sh(command: "git commit -m \"Updates strings for localization\"")
        ohter_action.sh("git push")
        
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
