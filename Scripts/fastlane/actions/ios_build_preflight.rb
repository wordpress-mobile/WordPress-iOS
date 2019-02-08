module Fastlane
  module Actions
    class IosBuildPreflightAction < Action
      def self.run(params)

        # Validate mobile configuration secrets
        other_action.configure_validate

        Action.sh("cd .. && rm -rf ~/Library/Developer/Xcode/DerivedData")

        # Verify that ImageMagick exists on this machine and can be called from the command-line.
        # Internal Builds use it to generate the App Icon as part of the build process
        begin
            Action.sh("which convert")
        rescue
            UI.user_error!("Couldn't find ImageMagick. Please install it by running `brew install imagemagick`")
            raise
        end

        # Verify that Ghostscript exists on this machine and can be called from the command-line.
        # Internal Builds use it to generate the App Icon as part of the build process
        begin
            Action.sh("which gs")
        rescue
            UI.user_error!("Couldn't find Ghostscript. Please install it by running `brew install ghostscript`")
            raise
        end

        # Check gems and pods are up to date. This will exit if it fails
        begin
          Action.sh("bundle check")
        rescue 
          UI.user_error!("You should run 'rake dependencies' to make sure gems are up to date")
          raise
        end

        Action.sh("rake dependencies:pod:clean")
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
