module Fastlane
  module Helpers
    module IosVersionHelper
      MAJOR_NUMBER = 0
      MINOR_NUMBER = 1
      HOTFIX_NUMBER = 2
      BUILD_NUMBER = 3

      def self.get_public_version
        version = get_build_version
        vp = get_version_parts(version)
        return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}" unless is_hotfix(version)
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
      end

      def self.calc_next_release_version(version)
        vp = get_version_parts(version)
        vp[MINOR_NUMBER] += 1
        if (vp[MINOR_NUMBER] == 10)
          vp[MAJOR_NUMBER] += 1
          vp[MINOR_NUMBER] = 0
        end

        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
      end

      def self.calc_prev_release_version(version)
        vp = get_version_parts(version)
        if (vp[MINOR_NUMBER] == 0)
          vp[MAJOR_NUMBER] -= 1
          vp[MINOR_NUMBER] = 9
        else
          vp[MINOR_NUMBER] -= 1
        end
        
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
      end

      def self.calc_next_build_version(version)
        vp = get_version_parts(version)
        vp[BUILD_NUMBER] += 1
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
      end

      def self.calc_next_hotfix_version(version)
        vp = get_version_parts(version)
        vp[HOTFIX_NUMBER] += 1
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}"
      end

      def self.calc_prev_build_version(version)
        vp = get_version_parts(version)
        vp[BUILD_NUMBER] -= 1 unless vp[BUILD_NUMBER] == 0
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}.#{vp[BUILD_NUMBER]}"
      end

      def self.calc_prev_hotfix_version(version)
        vp = get_version_parts(version)
        vp[HOTFIX_NUMBER] -= 1 unless vp[HOTFIX_NUMBER] == 0
        return "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}.#{vp[HOTFIX_NUMBER]}" unless vp[HOTFIX_NUMBER] == 0
        "#{vp[MAJOR_NUMBER]}.#{vp[MINOR_NUMBER]}"
      end

      def self.is_hotfix(version)
        vp = get_version_parts(version)
        return (vp.length > 2) && (vp[HOTFIX_NUMBER] != 0)
      end

      def self.get_build_version
        get_version_strings().split("\n")[1]
      end

      def self.get_internal_version
        get_version_strings().split("\n")[2]
      end

      private 

      def self.get_version_parts(version)
        version.split(".").fill("0", version.length...4).map{|chr| chr.to_i}
      end

      def self.get_version_strings
        Action.sh("./manage-version.sh get-version")
      end
    end
  end
end