import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCoreProtocols

public actor PluginRecommendationService: PluginRecommendationServiceProtocol {

    public typealias Feature = WordPressCoreProtocols.PluginRecommendationFeature
    public typealias Frequency = WordPressCoreProtocols.PluginRecommendationFrequency

    private let dotOrgClient: WordPressOrgApiClient
    private let userDefaults: UserDefaults

    public init(
        dotOrgClient: WordPressOrgApiClient = WordPressOrgApiClient(urlSession: .shared),
        userDefaults: UserDefaults = .standard
    ) {
        self.dotOrgClient = dotOrgClient
        self.userDefaults = userDefaults
    }

    public func recommendedPluginSlug(for feature: Feature) async throws -> String {
        feature.recommendedPlugin
    }

    public func recommendPlugin(for feature: Feature) async throws -> RecommendedPlugin {
        if let cachedPlugin = try await fetchCachedPlugin(for: feature.recommendedPlugin) {
            return cachedPlugin
        }

        let plugin = try await dotOrgClient.pluginInformation(slug: .init(slug: feature.recommendedPlugin))

        return RecommendedPlugin(
            name: plugin.name,
            slug: plugin.slug.slug,
            usageTitle: "Install \(unescapePluginTitle(plugin.name) ?? plugin.slug.slug)",
            usageDescription: feature.explanation,
            successMessage: feature.successMessage,
            imageUrl: try await cachePluginHeader(for: plugin),
            helpUrl: feature.helpArticleUrl
        )
    }

    public func shouldRecommendPlugin(for feature: Feature, frequency: Frequency) -> Bool {
        let featureTimestamp = self.userDefaults.double(forKey: feature.cacheKey)
        let globalTimestamp = self.userDefaults.double(forKey: "plugin-last-recommended")

        if featureTimestamp == 0 && globalTimestamp == 0 {
            return true
        }

        let earliestFeatureDate = Date(timeIntervalSince1970: featureTimestamp + frequency.timeInterval)
        let earliestGlobalDate = Date(timeIntervalSince1970: globalTimestamp + frequency.timeInterval)

        return earliestFeatureDate.hasPast && earliestGlobalDate.hasPast
    }

    public func displayedRecommendation(for feature: Feature, at date: Date = Date()) {
        self.userDefaults.set(date.timeIntervalSince1970, forKey: feature.cacheKey)
        self.userDefaults.set(date.timeIntervalSince1970, forKey: "plugin-last-recommended")
    }

    public func resetRecommendations() {
        for feature in Feature.allCases {
            self.userDefaults.removeObject(forKey: feature.cacheKey)
        }
        self.userDefaults.removeObject(forKey: "plugin-last-recommended")
    }

    private func unescapePluginTitle(_ string: String) -> String? {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#8211;", with: "–")
            .removingPercentEncoding
    }
}

public extension RecommendedPlugin {
    var pluginSlug: PluginWpOrgDirectorySlug {
        PluginWpOrgDirectorySlug(slug: self.slug)
    }
}

private extension PluginRecommendationService.Feature {
    var cacheKey: String {
        "plugin-recommendation-\(self)-\(recommendedPlugin)"
    }
}

// MARK: - RecommendedPlugin Cache
private extension PluginRecommendationService {
    private func cachedPluginData(for plugin: RecommendedPlugin) async throws {
        let cacheKey = "plugin-recommendation-\(plugin.slug)"
        try await DiskCache.shared.store(plugin, forKey: cacheKey)
    }

    private func fetchCachedPlugin(for slug: String) async throws -> RecommendedPlugin? {
        let cacheKey = "plugin-recommendation-\(slug)"
        return try await DiskCache.shared.read(RecommendedPlugin.self, forKey: cacheKey)
    }
}

// MARK: - Plugin Banner Cache
private extension PluginRecommendationService {
    func cachePluginHeader(for plugin: PluginInformation) async throws -> URL? {
        guard let pluginUrl = plugin.bannerUrl, let bannerFileName = plugin.bannerFileName else {
            return nil
        }

        let cachePath = self.storagePath(for: plugin, filename: bannerFileName)

        try FileManager.default.createDirectory(
            at: cachePath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        return try await cacheAsset(pluginUrl, at: cachePath)
    }

    func cacheAsset(_ url: URL, at path: URL) async throws -> URL {
        if FileManager.default.fileExists(at: path) {
            return path
        }

        let (tempPath, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempPath, to: path)

        return path
    }

    func storagePath(for plugin: PluginInformation, filename: String) -> URL {
        URL.cachesDirectory
            .appendingPathComponent("plugin-assets")
            .appendingPathComponent(plugin.slug.slug)
            .appendingPathComponent(filename)
    }
}

fileprivate extension PluginInformation {
    var bannerFileName: String? {
        bannerUrl?.lastPathComponent
    }

    var bannerUrl: URL? {
        URL(string: self.banners.high)
    }
}
