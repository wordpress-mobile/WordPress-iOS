import SwiftUI
import UIKit
import WordPressKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
struct DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    private let blog: Blog
    private let domainType: DomainType
    private let onDismiss: () -> Void

    private var domainSuggestionViewController: RegisterDomainSuggestionsViewController

    init(blog: Blog, domainType: DomainType, onDismiss: @escaping () -> Void) {
        self.blog = blog
        self.domainType = domainType
        self.onDismiss = onDismiss
        self.domainSuggestionViewController = DomainsDashboardFactory.makeDomainsSuggestionViewController(blog: blog, domainType: domainType, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> LightNavigationController {
        let navigationController = LightNavigationController(rootViewController: domainSuggestionViewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: LightNavigationController, context: Context) { }
}
