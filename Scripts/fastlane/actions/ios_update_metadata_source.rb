module Fastlane
  module Actions
    class IosUpdateMetadataSourceAction < Action
      def self.run(params)
        other_action.gp_update_metadata_source(po_file_path: params[:po_file_path],
          source_files: params[:source_files], 
          release_version: params[:release_version])

        Action.sh("git add #{params[:po_file_path]}")
        params[:source_files].each do | key, file |
          Action.sh("git add #{file}")
        end

        Action.sh("git commit -m \"Update metadata strings\"")
        Action.sh("git push")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Updates the AppStoreStrings.po file with the data from text source files"
      end

      def self.details
        "Updates the AppStoreStrings.po file with the data from text source files"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :po_file_path,
                                        env_name: "FL_IOS_UPDATE_METADATA_SOURCE_PO_FILE_PATH", 
                                        description: "The path of the .po file to update", 
                                        is_string: true,
                                        verify_block: proc do |value|
                                          UI.user_error!("No .po file path for UpdateMetadataSourceAction given, pass using `po_file_path: 'file path'`") unless (value and not value.empty?)
                                          UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                        end),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                        env_name: "FL_IOS_UPDATE_METADATA_SOURCE_RELEASE_VERSION",
                                        description: "The release version of the app (to use to mark the release notes)",
                                        verify_block: proc do |value|
                                          UI.user_error!("No relase version for UpdateMetadataSourceAction given, pass using `release_version: 'version'`") unless (value and not value.empty?) 
                                        end),
          FastlaneCore::ConfigItem.new(key: :source_files,
                                        env_name: "FL_IOS_UPDATE_METADATA_SOURCE_SOURCE_FILES",
                                        description: "The hash with the path to the source files and the key to use to include their content",
                                        is_string: false,
                                        verify_block: proc do |value|
                                          UI.user_error!("No source file hash for UpdateMetadataSourceAction given, pass using `source_files: 'source file hash'`") unless (value and not value.empty?)
                                        end)
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
