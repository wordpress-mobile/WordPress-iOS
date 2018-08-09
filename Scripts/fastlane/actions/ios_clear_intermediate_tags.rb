module Fastlane
  module Actions
    class IosClearIntermediateTagsAction < Action
      def self.run(params)
        UI.message("Deleting tags for version: #{params[:version]}")
        
        other_action.sh("git tag | xargs git tag -d; git fetch --tags")
        tags = other_action.sh("git tag")
        tags.split("\n").each do | tag |
          if (tag.split(".").length == 4) then
            if tag.start_with?(params[:version]) then
              UI.message("Removing: #{tag}")
              other_action.sh("git tag -d #{tag}")
              other_action.sh("git push origin :refs/tags/#{tag}")
            end
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Cleans all the intermediate tags for the given version"
      end

      def self.details
        "Cleans all the intermediate tags for the given version"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_IOS_CLEAN_INTERMEDIATE_TAGS_VERSION",
                                       description: "The version of the tags to clear",
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
