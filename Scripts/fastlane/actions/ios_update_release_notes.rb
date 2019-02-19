module Fastlane
    module Actions    
      class IosUpdateReleaseNotesAction < Action
        def self.run(params)
          # fastlane will take care of reading in the parameter and fetching the environment variable:
          UI.message "Updating the release notes..."

          require_relative '../helpers/ios_git_helper.rb'
          require_relative '../helpers/ios_version_helper.rb'
          next_version = Fastlane::Helpers::IosVersionHelper.calc_next_release_version(params[:new_version])
          Fastlane::Helpers::IosGitHelper.update_release_notes(next_version)
          
          UI.message "Done."
        end
  
        #####################################################
        # @!group Documentation
        #####################################################
  
        def self.description
          "Updates the release notes file for the next app version"
        end
  
        def self.details
          "Updates the release notes file for the next app version"
        end
  
        def self.available_options
            [
              FastlaneCore::ConfigItem.new(key: :new_version,
                                           env_name: "FL_IOS_UPDATE_RELEASE_NOTES_VERSION", 
                                           description: "The new version to add to the release notes",
                                           is_string: true)
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