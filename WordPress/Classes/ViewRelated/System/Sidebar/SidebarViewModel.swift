import Combine
import Foundation
import WordPressData
import WordPressKit
import WordPressShared

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

    let blogListViewModel = BlogListViewModel()

    var navigate: (SidebarNavigationStep) -> Void = { _ in }

    private let contextManager: CoreDataStackSwift
    private var previousReloadTimestamp: Date?
    private var cancellables: [AnyCancellable] = []

    init(contextManager: CoreDataStackSwift = ContextManager.shared) {
        self.contextManager = contextManager

        account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
        resetSelection()
        setupObservers()
    }

    func onAppear() {
        reloadMenuIfNeeded()
    }

    private func reloadMenuIfNeeded() {
        blogListViewModel.updateDisplayedSites()

        if Date.now.timeIntervalSince(previousReloadTimestamp ?? .distantPast) > 60 {
            previousReloadTimestamp = .now

            Task {
                try? await blogListViewModel.refresh()
            }
        }
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
            .publisher(for: .init(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification))
            .sink { [weak self] _ in self?.resetSelection() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .WPAccountDefaultWordPressComAccountChanged)
            .sink { [weak self] _ in
                guard let self else { return }
                self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: self.contextManager.mainContext)
            }
            .store(in: &cancellables)

        $selection.sink {
            UserDefaults.standard.isReaderSelected = $0 == .reader
        }.store(in: &cancellables)
    }

    private func resetSelection() {
        if UserDefaults.standard.isReaderSelected {
            selection = .reader
        } else if let blog = Blog.lastUsedOrFirst(in: contextManager.mainContext) {
            selection = .blog(TaggedManagedObjectID(blog))
        } else {
            selection = .welcome
        }
    }
}
