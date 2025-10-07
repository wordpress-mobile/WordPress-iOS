import Combine
import Foundation
import WordPressData
import WordPressKit
import WordPressShared

enum SidebarNavigationStep {
    case allSites(sourceRect: CGRect)
    case addSite(selection: AddSiteMenuViewModel.Selection)
    case help
    case profile
    case signIn
}

enum SidebarMode: Hashable, CaseIterable {
    case sites
    case reader

    var localizedTitle: String {
        switch self {
        case .sites: Strings.sites
        case .reader: Strings.reader
        }
    }
}

final class SidebarViewModel: ObservableObject {
    @Published var mode: SidebarMode = .sites

    @Published private(set) var siteViewModel: SiteMenuViewModel?
    let readerPresenter = ReaderPresenter()

    @Published private(set) var account: WPAccount?

    var navigate: (SidebarNavigationStep) -> Void = { _ in }

    private let contextManager: CoreDataStackSwift
    private var cancellables: [AnyCancellable] = []

    init(contextManager: CoreDataStackSwift = ContextManager.shared) {
        self.contextManager = contextManager

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
                self?.didSelectSite(site)
            }.store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .init(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification))
            .sink { [weak self] _ in self?.resetSelection() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .wpAccountDefaultWordPressComAccountChanged)
            .sink { [weak self] _ in
                guard let self else { return }
                self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: self.contextManager.mainContext)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: ContextManager.shared.mainContext)
            .sink { [weak self] in
                self?.handleCoreDataChanges($0)
            }
            .store(in: &cancellables)

        $mode.sink {
            UserDefaults.standard.isReaderSelected = $0 == .reader
        }.store(in: &cancellables)
    }

    private func resetSelection() {
        let site = Blog.lastUsedOrFirst(in: contextManager.mainContext)
        self.siteViewModel = site.map(SiteMenuViewModel.init)
        self.mode = UserDefaults.standard.isReaderSelected ? .reader : .sites
    }

    func didSelectSite(_ site: Blog?) {
        self.siteViewModel = site.map(SiteMenuViewModel.init)
        self.mode = .sites
    }

    // MARK: - Events

    private func handleCoreDataChanges(_ notification: Foundation.Notification) {
        // Automatically switch to a site or show the sign in screen, when the current blog is removed.
        guard let blog = siteViewModel?.site,
              let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
              deleted.contains(blog)
        else {
            return
        }

        if let newSite = Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext) {
            self.siteViewModel = SiteMenuViewModel(site: newSite)
        } else if AccountHelper.isDotcomAvailable() {
            self.siteViewModel = nil // Show "Empty" state
        } else {
            WordPressAppDelegate.shared?.windowManager.showSignInUI()
        }
    }
}

private enum Strings {
    static let sites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "Sites", comment: "Sidebar section title on iPad")
    static let reader = SharedStrings.Reader.title
}
