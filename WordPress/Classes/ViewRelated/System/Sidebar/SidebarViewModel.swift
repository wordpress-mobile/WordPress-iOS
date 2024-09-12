import Foundation
import Combine
import WordPressKit
import WordPressAuthenticator

enum SidebarSelection: Hashable {
    case welcome
    case blog(TaggedManagedObjectID<Blog>)
    case notifications
    case reader
}

enum SidebarNavigationStep {
    case allSites(sourceRect: CGRect)
    case addSite(selection: AddSiteMenuViewModel.Selection)
    case domains
    case help
    case profile
    case signIn
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
    @Published private(set) var account: WPAccount?

    var navigate: (SidebarNavigationStep) -> Void = { _ in }

    private let contextManager: CoreDataStackSwift
    private var cancellables: [AnyCancellable] = []

    init(contextManager: CoreDataStackSwift = ContextManager.shared) {
        self.contextManager = contextManager

        // TODO: (wpsidebar) can it change during the root presenter lifetime?
        account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
        resetSelection()
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default
            .publisher(for: MySiteViewController.didPickSiteNotification)
            .sink { [weak self] in
                guard let site = $0.userInfo?[MySiteViewController.siteUserInfoKey] as? Blog else {
                    return wpAssertionFailure("invalid notification")
                }
                self?.selection = .blog(TaggedManagedObjectID(site))
            }.store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .init(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification))
            .sink { [weak self] _ in self?.resetSelection() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .WPAccountDefaultWordPressComAccountChanged)
            .sink { [weak self] _ in
                guard let self else { return }
                self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: self.contextManager.mainContext)
            }
            .store(in: &cancellables)
    }

    private func resetSelection() {
        let blog = Blog.lastUsedOrFirst(in: contextManager.mainContext)
        if let blog {
            selection = .blog(TaggedManagedObjectID(blog))
        } else {
            selection = .welcome
        }
    }
}
