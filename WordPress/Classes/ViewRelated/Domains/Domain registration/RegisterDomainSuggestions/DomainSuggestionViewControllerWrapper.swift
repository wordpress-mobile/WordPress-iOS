import SwiftUI
import UIKit
import WordPressKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
struct DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    private let blog: Blog
    private let domainSelectionType: DomainSelectionType
    private let onDismiss: () -> Void

    private var domainSuggestionViewController: DomainSelectionViewController

    init(blog: Blog, domainSelectionType: DomainSelectionType, onDismiss: @escaping () -> Void) {
        self.blog = blog
        self.domainSelectionType = domainSelectionType
        self.onDismiss = onDismiss
        self.domainSuggestionViewController = DomainsDashboardFactory.makeDomainsSuggestionViewController(
            blog: blog,
            domainSelectionType: domainSelectionType,
            onDismiss: onDismiss
        )
    }

    func makeUIViewController(context: Context) -> LightNavigationController {
        let navigationController = LightNavigationController(rootViewController: domainSuggestionViewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: LightNavigationController, context: Context) { }
}
