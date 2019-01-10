
import Foundation

// MARK: - SiteVerticalsPromptService

/// The prompt provides valuable context to the user for searching site verticals.
/// It is influenced by the segment chosen in the preceding step.
///
public protocol SiteVerticalsPrompt {

    /// The primary text presented to the user.
    var title: String { get }

    /// Additional explanatory text.
    var subtitle: String { get }

    /// A hint to intended to guide the user's search.
    var hint: String { get }
}

public typealias SiteVerticalsPromptServiceCompletion = ((SiteVerticalsPrompt) -> ())

/// Abstracts retrieval of site verticals.
///
public protocol SiteVerticalsPromptService {
    func retrievePrompt(segmentIdentifier: Int64, completion: @escaping SiteVerticalsPromptServiceCompletion)
}

// MARK: - Mock service & result

final class DefaultSiteVerticalsPrompt: SiteVerticalsPrompt {

    let title = NSLocalizedString("What's the focus of your business?",
                                  comment: "Create site, step 2. Select focus of the business. Title")

    let subtitle = NSLocalizedString("We'll use your answer to add sections to your website.",
                                     comment: "Create site, step 2. Select focus of the business. Subtitle")

    let hint = NSLocalizedString("e.g. Landscaping, Consulting... etc.",
                                 comment: "Site creation. Select focus of your business, search field placeholder")
}

typealias MockSiteVerticalsPrompt = DefaultSiteVerticalsPrompt

/// Mock implementation of the prompt service
///
final class MockSiteVerticalsPromptService: SiteVerticalsPromptService {
    func retrievePrompt(segmentIdentifier: Int64, completion: @escaping SiteVerticalsPromptServiceCompletion) {
        completion(MockSiteVerticalsPrompt())
    }
}
