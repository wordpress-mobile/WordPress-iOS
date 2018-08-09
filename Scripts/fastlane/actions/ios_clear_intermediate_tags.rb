module Fastlane
  module Actions
    class IosClearIntermediateTagsAction < Action
      def self.run(params)
        UI.message("Deleting tags for version: #{params[:version]}")
        
        require_relative '../helpers/ios_git_helper.rb'
        Fastlane::Helpers::IosGitHelper.delete_tags(params[:version])

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
