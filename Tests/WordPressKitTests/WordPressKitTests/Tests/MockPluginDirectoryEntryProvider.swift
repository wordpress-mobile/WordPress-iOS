import Foundation
@testable import WordPressKit

struct MockPluginDirectoryProvider {
    static func getPluginDirectoryEntry() -> PluginDirectoryEntry {
        let plugin = PluginDirectoryEntry(name: "Jetpack by WordPress.com",
                                          slug: "jetpack",
                                          version: "5.5.1",
                                          lastUpdated: nil,
                                          icon: URL(string: "https://ps.w.org/jetpack/assets/icon-256x256.png?rev=969908"),
                                          banner: URL(string: "https://ps.w.org//jetpack//assets//banner-1544x500.png?rev=1791404"),
                                          author: "Automattic",
                                          authorURL: URL(string: "https://profiles.wordpress.org/automattic"),
                                          descriptionHTML: self.getJetpackDescriptionHTML(),
                                          installationHTML: self.getJetpackInstallationHTML(),
                                          faqHTML: self.getJetpackFAQHTML(),
                                          changelogHTML: self.getJetpackChangeLogHTML(),
                                          rating: 82)
        return plugin
    }

    static func getJetpackDescriptionHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let description = sections["description"] as? String else {
            return nil
        }

        return description
    }

    static func getJetpackFAQHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let faq = sections["faq"] as? String else {
            return nil
        }

        return faq
    }

    static func getJetpackInstallationHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let installation = sections["installation"] as? String else {
            return nil
        }

        return installation
    }

    static func getJetpackChangeLogHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let changeLog = sections["changelog"] as? String else {
            return nil
        }

        return changeLog
    }

    static func getPluginDirectoryMockData(with mockName: String, sender: AnyClass, type: String = "json") throws -> Data {
        let mockPath = Bundle(for: sender).path(forResource: mockName, ofType: type)!
        let data = try Data(contentsOf: URL(fileURLWithPath: mockPath))

        return data
    }

}
