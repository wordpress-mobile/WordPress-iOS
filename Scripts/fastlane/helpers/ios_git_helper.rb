module Fastlane
  module Helpers
    module IosGitHelper
     
      def self.git_checkout_and_pull(branch)
        Action.sh("git checkout #{branch}")
        Action.sh("git pull")
      end

      def self.git_checkout_and_pull_release_branch_for(version)
        branch_name = "release/#{version}"
        Action.sh("git pull")
        begin
          Action.sh("git checkout #{branch_name}")
          Action.sh("git pull origin #{branch_name}")
          return true
        rescue
          return false
        end
      end

      def self.branch_for_hotfix(tag_version, new_version)
        Action.sh("git checkout #{tag_version}")
        Action.sh("git checkout -b release/#{new_version}")
        Action.sh("git push --set-upstream origin release/#{new_version}")
      end

      def self.bump_version_release()
        Action.sh("./manage-version.sh bump-release")
        Action.sh("cd .. && git add ./config/.")
        Action.sh("git add fastlane/Deliverfile")
        Action.sh("git add fastlane/download_metadata.swift")
        Action.sh("git add ../WordPress/Resources/AppStoreStrings.po")
        Action.sh("git commit -m \"Bump version number\"")
        Action.sh("git push")
      end

      def self.bump_version_hotfix(version)
        Action.sh("./manage-version.sh update #{version}")
        Action.sh("cd .. && git add ./config/.")
        Action.sh("git add fastlane/Deliverfile")
        Action.sh("git add fastlane/download_metadata.swift")
        Action.sh("git add ../WordPress/Resources/AppStoreStrings.po")
        Action.sh("git commit -m \"Bump version number\"")
        Action.sh("git push")
      end

      def self.bump_version_beta()
        Action.sh("./manage-version.sh bump-internal")
        Action.sh("cd .. && git add ./config/.")
        Action.sh("git commit -m \"Bump version number\"")
        Action.sh("git push")
      end

      def self.delete_tags(version)
        Action.sh("git tag | xargs git tag -d; git fetch --tags")
        tags = Action.sh("git tag")
        tags.split("\n").each do | tag |
          if (tag.split(".").length == 4) then
            if tag.start_with?(version) then
              UI.message("Removing: #{tag}")
              Action.sh("git tag -d #{tag}")
              Action.sh("git push origin :refs/tags/#{tag}")
            end
          end
        end
      end

      def self.final_tag(version)
        Action.sh("git tag #{version}")
        Action.sh("git push origin #{version}")
      end

      def self.localize_project()
        Action.sh("cd .. && ./Scripts/localize.py")
        Action.sh("cd .. && git add ./WordPress/Resources/.")
        Action.sh("git commit -m \"Updates strings for localization\"")
        Action.sh("git push")
      end

      def self.tag_build(itc_version, internal_version)
        Action.sh("cd .. && git tag #{itc_version} && git tag #{internal_version} && git push origin #{itc_version} && git push origin #{internal_version}") 
      end

      def self.update_metadata()
        Action.sh("cd .. && ./Scripts/update-translations.rb")
        Action.sh("cd ../WordPress && git add .")
        Action.sh("git commit -m \"Updates translation\"")

        Action.sh("cd fastlane && ./download_metadata.swift")
        Action.sh("git add ./fastlane/metadata/")
        Action.sh("git commit -m \"Updates metadata translation\"")

        Action.sh("git push")
      end
    end
  end
end