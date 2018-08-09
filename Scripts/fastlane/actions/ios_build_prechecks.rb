module Fastlane
  module Actions
    class IosBuildPrechecksAction < Action
      def self.run(params)
        require_relative '../helpers/ios_version_helper.rb'

        message = ""
        message << "Building version #{Fastlane::Helpers::IosVersionHelper.get_internal_version()} and uploading to HockeyApp\n" unless !params[:internal]
        message << "Building version #{Fastlane::Helpers::IosVersionHelper.get_build_version()} and uploading to TestFlight\n" unless !params[:external]

        if (!params[:skip_confirm])
          if (!UI.confirm("#{message}Do you want to continue?"))
            UI.user_error!("Aborted by user request")
          end
        else 
          UI.message(message)
        end

        # Check local repo status
        #other_action.ensure_git_status_clean()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs some prechecks before the build"
      end

      def self.details
        "Runs some prechecks before the build"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: "FL_IOS_BUILD_PRECHECKS_SKIP_CONFIRM", 
                                       description: "True to avoid the system ask for confirmation", 
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :internal,
                                       env_name: "FL_IOS_BUILD_PRECHECKS_INTERNAL_BUILD",
                                       description: "True if this is for an internal build",
                                       is_string: false, 
                                       default_value: false), 
            FastlaneCore::ConfigItem.new(key: :external,
                                        env_name: "FL_IOS_BUILD_PRECHECKS_EXTERNAL_BUILD",
                                        description: "True if this is for a public build",
                                        is_string: false, 
                                        default_value: false), 
        ]
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
