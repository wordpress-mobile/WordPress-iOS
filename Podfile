xcodeproj 'WordPress/WordPress.xcodeproj'

platform :ios, '6.0'
pod 'AFNetworking',	'1.2.0'
pod 'Reachability',	'3.0.0'
pod 'JSONKit',		  '~> 1.4', :inhibit_warnings => true
pod 'NSURL+IDN', :podspec => 'https://raw.github.com/koke/NSURL-IDN/master/Podfile'
pod 'CTidy', :git => 'git://github.com/wordpress-mobile/CTidy.git'
pod 'DTCoreText',   '1.6.5'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', '~> 0.9'
pod 'SFHFKeychainUtils', '~> 0.0.1'
pod 'wpxmlrpc', '~> 0.1'
pod 'WordPressApi', :git => 'https://github.com/koke/WordPressApi.git'
pod 'NSObject-SafeExpectations', :podspec => 'https://raw.github.com/koke/NSObject-SafeExpectations/master/NSObject-SafeExpectations.podspec'
pod 'Mixpanel'
pod 'CocoaLumberjack', '~>1.6.2'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '1.3.0'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git'
pod 'Quantcast-Measure', '~> 1.2.10'
pod 'CocoaLumberjack', '~>1.6.2'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'

# The podspec for the XL fork is private, so manually adding the
# dependencies
pod 'InflectorKit'
pod 'TransformerKit'
pod 'AFIncrementalStore', :git =>
'git://github.com/xtremelabs/AFIncrementalStore.git', :tag => '0.5.5'


target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
end

# The post install hook add certain compiler flags for JSONKit files so that
# they won't generate warnings. This had been done in the podspec before, but
# was removed later for some reason.
post_install do |installer|
    # Adds the specified compiler flags to the given file in the project.
    #
    # @param [Xcodeproj::Project] project
    #                             The Xcode project instance.
    #
    # @param [String] filename
    #                 The name of the file to work with.
    #
    # @param [String] new_compiler_flags
    #                 The compiler flags to add.
    #
    # @example Disable some warning switches for JSONKit:
    #   add_compiler_flags(installer.project,
    #       "JSONKit.m",
    #       "-Wno-deprecated-objc-isa-usage -Wno-format")
    #
    def add_compiler_flags(project, filename, new_compiler_flags)
        # find all PBXFileReference objects of the given file
        files = project.files().select { |file|
            file.display_name() == filename
        }

        # get the PBXBuildFile references of the found files
        # PBXBuildFile actually contains flags for building the file
        build_files = files.map { |file|
            file.build_files()
        }.compact.flatten

        # compiler flags key in settings
        compiler_flags_key = "COMPILER_FLAGS"

        if build_files.length > 0
            build_files.each { |build_file|
                settings = build_file.settings
                if settings.nil?
                  # If we don't have settings for the file we create a new hash
                  settings = Hash[compiler_flags_key, new_compiler_flags]
                else
                  compiler_flags = settings[compiler_flags_key]
                  compiler_flags = (compiler_flags.nil?) ?
                      new_compiler_flags :
                      (compiler_flags + " " + new_compiler_flags)
                  settings[compiler_flags_key] = compiler_flags
                end
                build_file.settings = settings
            }
        else
            puts "No build file refs found for #{filename}!"
        end
    end

    # compiler flags that turn off the JSONKit's warnings
    JSONKIT_FLAGS = "-Wno-deprecated-objc-isa-usage -Wno-format -Wno-parentheses"
    add_compiler_flags(installer.project, "JSONKit.m", JSONKIT_FLAGS)
end


