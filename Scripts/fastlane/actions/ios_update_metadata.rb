module Fastlane
  module Actions
    module SharedValues
      IOS_UPDATE_METADATA_CUSTOM_VALUE = :IOS_UPDATE_METADATA_CUSTOM_VALUE
    end

    class IosUpdateMetadataAction < Action
      def self.run(params)
        other_action.sh("cd .. && ./Scripts/update-translations.rb")
        other_action.sh("cd ../WordPress && git add .")
        other_action.sh("git commit -m \"Updates translation\"")

        other_action.sh("./download_metadata.swift")
        other_action.sh("git add ./fastlane/metadata/.")
        other_action.sh("git commit -m \"Updates metadata translation\"")

        other_action.sh("git push")
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
