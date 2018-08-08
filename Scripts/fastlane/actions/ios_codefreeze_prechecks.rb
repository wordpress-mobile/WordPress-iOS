module Fastlane
  module Actions
    class IosCodefreezePrechecksAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Skip confirm on code freeze: #{params[:skip_confirm]}"

        require_relative '../helpers/ios_version_helper.rb'

        # Checkout develop and update
        other_action.sh(command: "git checkout develop")
        other_action.sh(command:"git pull")

        # Create versions
        current_version = Fastlane::Helpers::IosVersionHelper::get_public_version
        current_build_version = Fastlane::Helpers::IosVersionHelper::get_build_version
        next_version = Fastlane::Helpers::IosVersionHelper::calc_next_release_version(current_version)

        # Ask user confirmation
        if (!params[:skip_confirm])
          if (!UI.confirm("Building a new release branch starting from develop.\nCurrent version is #{current_version} (#{current_build_version}).\nAfter codefreeze the new version will be: #{next_version}.\nDo you want to continue?"))
            UI.user_error!("Aborted by user request")
          end
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

        # Return the current version
        current_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs some prechecks before code freeze"
      end

      def self.details
        "Updates the develop branch, checks the app version and ensure the branch is clean"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: "FL_IOS_CODEFREEZE_PRECHECKS_SKIPCONFIRM",
                                       description: "Skips confirmation before codefreeze",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output

      end

      def self.return_value
        "Version of the app before code freeze"
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
