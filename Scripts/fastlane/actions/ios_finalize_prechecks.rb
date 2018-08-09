module Fastlane
  module Actions
    class IosFinalizePrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        
        require_relative '../helpers/ios_version_helper.rb'
        require_relative '../helpers/ios_git_helper.rb'

        UI.user_error!("This is not a release branch. Abort.") unless other_action.git_branch.start_with?("release/")

        version = Fastlane::Helpers::IosVersionHelper::get_public_version
        message = "Finalizing release: #{version}\n"
        if (!params[:skip_confirm])
          if (!UI.confirm("#{message}Do you want to continue?"))
            UI.user_error!("Aborted by user request")
          end
        else 
          UI.message(message)
        end

        version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs some prechecks before finalizing a release"
      end

      def self.details
        "Runs some prechecks before finalizing a release"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: "FL_IOS_FINALIZE_PRECHECKS_SKIPCONFIRM",
                                       description: "Skips confirmation",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output
        
      end

      def self.return_value
        "The current app version"
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
