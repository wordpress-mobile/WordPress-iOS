import Foundation
import WordPressData

@MainActor
protocol PostSettingsDataProvider: AnyObject {
    var blog: Blog { get }
    var capabilities: PostSettingsCapabilities { get }

    // Post identity and state
    var postContent: String { get }
    var isScheduled: Bool { get }
    var isDraftOrPending: Bool { get }
    var isPost: Bool { get }
    var postID: Int? { get }
    var hasRemote: Bool { get }
    var isDeleted: Bool { get }

    // Display strings
    var navigationTitle: String { get }
    var authorFallbackDisplayName: String { get }
    var suggestedSlug: String? { get }
    var permalinkTemplate: String? { get }
    var lastEditedText: String? { get }

    // Settings management
    func makeSettings() -> PostSettings
    func makeFeaturedImageViewModel() -> PostSettingsFeaturedImageViewModel?
    func resolveDisplayedCategories(for settings: PostSettings) -> [String]
    func customTaxonomies() -> [SiteTaxonomy]
    func resolveTerms(in settings: inout PostSettings) async

    // Persistence
    func applyLocally(settings: PostSettings)
    func save(settings: PostSettings) async throws
    func publish(settings: PostSettings) async throws

    // Optional features
    var isEligibleForSocialSharing: Bool { get }
    func parentPageText(for pageID: Int?) -> String?
    func suggestedTags() async throws -> [String]
    var supportsJetpackMetadata: Bool { get }
    var hasTermNames: Bool { get }
}

extension PostSettingsDataProvider {
    func parentPageText(for pageID: Int?) -> String? { nil }

    func suggestedTags() async throws -> [String] { [] }
}
