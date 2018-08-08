module Fastlane
  module Actions
    class IosBetabuildPrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        UI.message "Work on version: #{params[:base_version]}" unless params[:base_version].nil?
        
        require_relative '../helpers/ios_version_helper.rb'
        require_relative '../helpers/ios_git_helper.rb'

        # Checkout develop and update
        Fastlane::Helpers::IosGitHelper::git_checkout_and_pull("develop")

        # Check versions
        build_version = Fastlane::Helpers::IosVersionHelper::get_build_version
        message = "The following current version has been detected: #{build_version}\n"
        
        # Check branch
        app_version = Fastlane::Helpers::IosVersionHelper::get_public_version
        UI.user_error!("#{message}Release branch for version #{app_version} doesn't exist. Abort.") unless (!params[:base_version].nil? || Fastlane::Helpers::IosGitHelper::git_checkout_and_pull_release_branch_for(app_version))
        
        # Check user overwrite
        build_version = get_user_build_version(params[:base_version], message) unless params[:base_version].nil?
        next_version = Fastlane::Helpers::IosVersionHelper::calc_next_build_version(build_version)

        # Verify
        message << "Updating branch to version: #{next_version}.\n"
        if (!params[:skip_confirm])
          if (!UI.confirm("#{message}Do you want to continue?"))
            UI.user_error!("Aborted by user request")
          end
        else 
          UI.message(message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

        # Return the current version
        current_version
      end

      def self.get_user_build_version(version, message)
        UI.user_error!("Release branch for version #{version} doesn't exist. Abort.") unless Fastlane::Helpers::IosGitHelper::git_checkout_and_pull_release_branch_for(version)
        build_version = Fastlane::Helpers::IosVersionHelper::get_build_version
        message << "Looking at branch release/#{version} as requested by user. Detected version: #{build_version}.\n"
        build_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs some prechecks before preparing for a new test build"
      end

      def self.details
        "Updates the relevant release branch, checks the app version and ensure the branch is clean"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :base_version,
                                       env_name: "FL_IOS_BETABUILD_PRECHECKS_BASE_VERSION", 
                                       description: "The version to work on", # a short description of this parameter
                                       is_string: true,
                                       optional: true), # true: verifies the input is a string, false: every kind of value),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                        env_name: "FL_IOS_BETABUILD_PRECHECKS_SKIPCONFIRM",
                                        description: "Skips confirmation",
                                        is_string: false, # true: verifies the input is a string, false: every kind of value
                                        default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output
        
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
