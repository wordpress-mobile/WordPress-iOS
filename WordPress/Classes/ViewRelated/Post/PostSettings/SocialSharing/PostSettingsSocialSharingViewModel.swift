import Foundation
import SwiftUI
import Combine
import WordPressData
import WordPressKit
import WordPressShared

@MainActor
final class PostSettingsSocialSharingViewModel: NSObject, ObservableObject {
    let blog: Blog
    @Binding var settings: PostSettings
    let coreDataStack: CoreDataStackSwift
    private let persistentStore: UserPersistentRepository

    @Published private(set) var state: SocialSharingState = .hidden

    var isHidden: Bool {
        if case .hidden = state { return true }
        return false
    }

    var blogID: Int? {
        blog.dotComID?.intValue
    }

    /// A temporary workaround for showing the sharing view controller.
    weak var viewController: UIViewController?

    enum SocialSharingState {
        case noConnection(JetpackSocialNoConnectionViewModel)
        case hasConnections(PrepublishingAutoSharingModel)
        case hidden
    }

    init(
        blog: Blog,
        settings: Binding<PostSettings>,
        coreDataStack: CoreDataStackSwift = ContextManager.shared,
        persistentStore: UserPersistentRepository = UserPersistentStoreFactory.instance()
    ) {
        self.blog = blog
        self._settings = settings
        self.coreDataStack = coreDataStack
        self.persistentStore = persistentStore
        super.init()

        isNoConnectionDismissed = false
        refresh()
    }

    func refresh() {
        guard canDisplaySocialRow() else {
            state = .hidden
            return
        }

        if hasExistingConnections {
            let viewModel = makeAutoSharingViewModel()
            state = .hasConnections(viewModel)

            if viewModel.sharingLimit != nil {
                WPAnalytics.track(.jetpackSocialShareLimitDisplayed, properties: ["source": Constants.trackingSource])
            }
        } else {
            let viewModel = makeNoConnectionViewModel()
            state = .noConnection(viewModel)
            WPAnalytics.track(.jetpackSocialNoConnectionCardDisplayed, properties: ["source": Constants.trackingSource])
        }
    }

    // MARK: - Eligibility

    private func canDisplaySocialRow(
        isJetpack: Bool = AppConfiguration.isJetpack,
        isFeatureEnabled: Bool = RemoteFeatureFlag.jetpackSocialImprovements.enabled()
    ) -> Bool {
        guard isJetpack &&
                isFeatureEnabled &&
                !isPostPrivate &&
                post.blog.supportsPublicize() &&
                !getPublisizeServices().isEmpty
        else {
            return false
        }

        guard hasExistingConnections else {
            // if the site has no connections, ensure that the No Connection view hasn't been dismissed before.
            return !isNoConnectionDismissed
        }

        return true
    }

    private var postBlogID: Int? {
        blog.dotComID?.intValue
    }

    private var isPostPrivate: Bool {
        settings.status == .publishPrivate
    }

    private var hasExistingConnections: Bool {
        !(blog.connections ?? []).isEmpty
    }

    private func getPublisizeServices() -> [PublicizeService] {
        let context = blog.managedObjectContext ?? coreDataStack.mainContext
        do {
            return try PublicizeService.allSupportedServices(in: context)
        } catch {
            wpAssertionFailure("Failed to fetch publicize services", userInfo: ["error": error.localizedDescription])
            return []
        }
    }

    // MARK: - No Connection Management

    private var isNoConnectionDismissed: Bool {
        get {
            guard let postBlogID,
                  let dictionary = persistentStore.dictionary(forKey: Constants.noConnectionKey) as? [String: Bool],
                  let storedValue = dictionary["\(postBlogID)"] else {
                return false
            }
            return storedValue
        }

        set {
            guard let postBlogID else {
                return
            }
            var dictionary = (persistentStore.dictionary(forKey: Constants.noConnectionKey) as? [String: Bool]) ?? .init()
            dictionary["\(postBlogID)"] = newValue
            persistentStore.set(dictionary, forKey: Constants.noConnectionKey)
        }
    }

    // MARK: - Actions

    func connectSocialAccounts() {
        guard let sharingVC = SharingViewController(blog: blog, delegate: self) else {
            return
        }

        WPAnalytics.track(.jetpackSocialNoConnectionCTATapped, properties: ["source": Constants.trackingSource])

        let navigationController = UINavigationController(rootViewController: sharingVC)
        viewController?.show(navigationController, sender: nil)
    }

    func dismissNoConnection() {
        WPAnalytics.track(.jetpackSocialNoConnectionCardDismissed, properties: ["source": Constants.trackingSource])

        withAnimation {
            isNoConnectionDismissed = true
            state = .hidden
        }
    }

    // MARK: - Model Creation

    private func makeNoConnectionViewModel() -> JetpackSocialNoConnectionViewModel {
        let services = getPublisizeServices()
        return JetpackSocialNoConnectionViewModel(
            services: services,
            padding: EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0),
            onConnectTap: { [weak self] in
                self?.connectSocialAccounts()
            },
            onNotNowTap: { [weak self] in
                self?.dismissNoConnection()
            }
        )
    }

    private func makeAutoSharingViewModel() -> PrepublishingAutoSharingModel {
        let supportedServices = getPublisizeServices()
        let connections = blog.sortedConnections

        // first, build a dictionary to categorize the connections.
        var connectionsMap = [PublicizeService.ServiceName: [PublicizeConnection]]()
        connections.filter { !$0.requiresUserAction() }.forEach { connection in
            let serviceName = PublicizeService.ServiceName(rawValue: connection.service) ?? .unknown
            var serviceConnections = connectionsMap[serviceName] ?? []
            serviceConnections.append(connection)
            connectionsMap[serviceName] = serviceConnections
        }

        // then, transform [PublicizeService] to [PrepublishingAutoSharingModel.Service].
        let modelServices = supportedServices.compactMap { service -> PrepublishingAutoSharingModel.Service? in
            // skip services without connections.
            guard let serviceConnections = connectionsMap[service.name],
                  !serviceConnections.isEmpty else {
                return nil
            }

            return PrepublishingAutoSharingModel.Service(
                name: service.name,
                connections: serviceConnections.map {
                    .init(account: $0.externalDisplay,
                          keyringID: $0.keyringConnectionID.intValue,
                          enabled: !settings.disabledPublicizeConnectionKeyringIDs.contains($0.keyringConnectionID.intValue))
                }
            )
        }

        return PrepublishingAutoSharingModel(
            services: modelServices,
            message: settings.publicizeMessage ?? "",
            sharingLimit: blog.sharingLimit
        )
    }

    // MARK: - Constants

    private enum Constants {
        static let trackingSource = "post_settings"
        static let noConnectionKey = "post-settings-social-no-connection-view-hidden"
    }
}

// MARK: - SharingViewControllerDelegate

extension PostSettingsSocialSharingViewModel: @preconcurrency SharingViewControllerDelegate {
    func didChangePublicizeServices() {
        refresh()
    }
}

// MARK: - PrepublishingSocialAccountsDelegate

extension PostSettingsSocialSharingViewModel: @preconcurrency PrepublishingSocialAccountsDelegate {
    func didUpdateSharingLimit(with newValue: PublicizeInfo.SharingLimit?) {
        refresh()
    }

    func didFinish(with connectionChanges: [Int: Bool], message: String?) {
        // Update the settings binding
        connectionChanges.forEach { (keyringID, enabled) in
            if enabled {
                settings.disabledPublicizeConnectionKeyringIDs.remove(keyringID)
            } else {
                settings.disabledPublicizeConnectionKeyringIDs.insert(keyringID)
            }
        }
        
        let isMessageEmpty = message?.isEmpty ?? true
        settings.publicizeMessage = isMessageEmpty ? nil : message
        
        refresh()
    }
}
