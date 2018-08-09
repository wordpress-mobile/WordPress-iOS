module Fastlane
  module Actions
    module SharedValues
      IOS_UPDATE_METADATA_CUSTOM_VALUE = :IOS_UPDATE_METADATA_CUSTOM_VALUE
    end

    class IosUpdateMetadataAction < Action
      def self.run(params)
        require_relative '../helpers/ios_git_helper.rb'

        Fastlane::Helpers::IosGitHelper.update_metadata()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Downloads translated metadata from the translation system"
      end

      def self.details
        "Downloads translated metadata from the translation system"
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
