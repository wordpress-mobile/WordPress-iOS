module Fastlane
  module Actions
    class IosFinalTagAction < Action
      def self.run(params)
        version = other_action.ios_get_app_version()
        UI.message("Tagging final #{version}...")

        other_action.sh("git tag #{version}")
        other_action.sh("git push origin #{version}")
        other_action.ios_clear_intermediate_tags(version: version)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Finalize a relasae"
      end

      def self.details
        "Removes the temp tags and pushes the final one"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                        env_name: "FL_IOS_FINAL_TAG_VERSION", 
                                        description: "The version of the release to finalize", 
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
