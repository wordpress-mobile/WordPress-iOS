module Fastlane
  module Actions
    class IosFinalTagAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Parameter API Token: #{params[:api_token]}"

        # sh "shellcommand ./path"

        # Actions.lane_context[SharedValues::IOS_FINAL_TAG_CUSTOM_VALUE] = "my_val"
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
