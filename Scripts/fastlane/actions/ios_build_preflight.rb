module Fastlane
  module Actions
    class IosBuildPreflightAction < Action
      def self.run(params) 
        Action.sh("cd .. && rm -rf ~/Library/Developer/Xcode/DerivedData")
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
