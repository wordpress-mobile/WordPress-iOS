import Foundation
import WordPressCore
import WordPressData
import WordPressShared
import WordPressAPI

@MainActor
class JetpackConnectionViewModel: ObservableObject {
    @Published var stepStages: [JetpackConnectionStep: StepStage] = [:]
    @Published var isCompleted = false
    @Published var currentStep: JetpackConnectionStep = .login
    @Published var isConnecting = false

    let steps = Array(JetpackConnectionStep.allCases).sorted { $0.rawValue < $1.rawValue }

    private let blogID: TaggedManagedObjectID<Blog>
    private weak var presentingViewController: UIViewController?
    private let completionHandler: () -> Void
    private let connectionService: JetpackConnectionService
    private var stepContext: StepContext = .initial

    init(blog: Blog, presentingViewController: UIViewController, connectionService: JetpackConnectionService, completionHandler: @escaping () -> Void) {
        self.blogID = TaggedManagedObjectID(blog)
        self.presentingViewController = presentingViewController
        self.connectionService = connectionService
        self.completionHandler = completionHandler

        for step in steps {
            stepStages[step] = .pending
        }
    }

    func connect() {
        guard !isConnecting else { return }

        WPAnalytics.track(.jetpackConnectStarted)
        isConnecting = true
        Task {
            await processCurrentStep()
        }
    }

    private func processCurrentStep() async {
        stepStages[currentStep] = .processing

        WPAnalytics.track(currentStep.event, properties: [
            "state": "started"
        ])

        do {
            switch currentStep {
            case .login:
                try await performLogin()
            case .install:
                try await performInstall()
            case .siteConnection:
                try await performSiteConnection()
            case .userConnection:
                try await performUserConnection()
            case .finalize:
                try await performFinalization()
            }

            stepStages[currentStep] = .success

            WPAnalytics.track(currentStep.event, properties: [
                "state": "completed"
            ])

            if let nextStep = self.nextStep() {
                currentStep = nextStep
                await processCurrentStep()
            } else {
                isCompleted = true
                WPAnalytics.track(.jetpackConnectCompleted)
            }
        } catch {
            stepStages[currentStep] = .error(error.localizedDescription)

            WPAnalytics.track(currentStep.event, properties: [
                "state": "failed",
                "error_domain": (error as NSError).domain,
                "error_code": (error as NSError).code
            ])
        }
    }

    private func performLogin() async throws {
        guard let presentingViewController else {
            wpAssertionFailure("The presenting view controller should not be nil")
            throw JetpackConnectionError.unexpectedContext
        }

        let accountID = try await connectionService.performLogin(from: presentingViewController, blogID: blogID)
        stepContext = .loggedIn(account: accountID)
    }

    private func performInstall() async throws {
        guard case .loggedIn(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performInstall()
        stepContext = .installed(account: account)
    }

    private func performSiteConnection() async throws {
        guard case .installed(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performSiteConnection()
        stepContext = .siteConnected(account: account)
    }

    private func performUserConnection() async throws {
        guard case .siteConnected(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performUserConnection(account: account)
        stepContext = .userConnected(account: account)
    }

    private func performFinalization() async throws {
        guard case .userConnected(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performFinalization(account: account)
        stepContext = .finalized
    }

    private func nextStep() -> JetpackConnectionStep? {
        if let index = steps.firstIndex(of: currentStep), steps.index(after: index) < steps.endIndex {
            return steps[steps.index(after: index)]
        }

        return nil
    }

    func finish() {
        completionHandler()
    }

    func retryCurrentStep() {
        WPAnalytics.track(.jetpackConnectStepRetried, properties: [
            "step": currentStep.event.value
        ])
        stepStages[currentStep] = .pending
        Task {
            await processCurrentStep()
        }
    }
}

private enum JetpackConnectionError: LocalizedError {
    case authenticationFailed
    case unexpectedContext

    var errorDescription: String {
        switch self {
        case .authenticationFailed:
            return Strings.errorAuthenticationFailed
        case .unexpectedContext:
            return Strings.errorUnexpectedContext
        }
    }
}

class JetpackConnectionService {
    private let blogId: TaggedManagedObjectID<Blog>
    private let client: WordPressClient
    private let jetpackConnectionClient: JetpackConnectionClient

    init?(blog: Blog) {
        // Requirements:
        // - Self-hosted site, and
        // - The site is authenticated with application password, and
        // - Jetpack is not installed, or the installed jetpack version is 14.2 or above.

        guard blog.account == nil else { return nil }

        if let jetpack = blog.jetpack, jetpack.isInstalled, let version = jetpack.version,
           // The `version` value is not a strict semantic version number.
           version.compare("14.2", options: .numeric) == .orderedAscending {
            return nil
        }

        guard let site = try? WordPressSite(blog: blog),
              case let .selfHosted(_, _, apiRootURL, username, password) = site
        else {
            return nil
        }

        self.blogId = TaggedManagedObjectID(blog)
        self.client = WordPressClientFactory.shared.instance(for: site)
        self.jetpackConnectionClient = .init(
            apiRootUrl: apiRootURL,
            urlSession: .init(configuration: .ephemeral),
            authentication: .init(username: username, password: password)
        )
    }

    func performLogin(from presentingViewController: UIViewController, blogID: TaggedManagedObjectID<Blog>) async throws -> TaggedManagedObjectID<WPAccount> {
        let defaultAccount: TaggedManagedObjectID<WPAccount>? = try await ContextManager.shared.performQuery { context in
            guard let account = try WPAccount.lookupDefaultWordPressComAccount(in: context) else { return nil }
            return .init(account)
        }

        if let defaultAccount {
            return defaultAccount
        }

        let email = try await ContextManager.shared.performQuery { context in
            try context.existingObject(with: blogID).jetpack?.connectedEmail
        }

        let authenticator = WordPressDotComAuthenticator(showProgressHUD: false)
        return try await authenticator.attemptSignIn(from: presentingViewController, context: .jetpackSite(accountEmail: email))
    }

    func performInstall() async throws {
        let plugins = try await client.api.plugins.listWithEditContext(params: .init())
        let jetpack = plugins.data.first { $0.plugin == .jetpack }

        if let jetpack {
            if jetpack.status == .inactive {
                let _ = try await client.api.plugins.update(
                    pluginSlug: jetpack.plugin,
                    params: .init(status: jetpack.networkOnly ? .networkActive : .active)
                )
            }
        } else {
            let _ = try await client.api.plugins.create(params: .init(slug: .jetpack, status: .active))
        }
    }

    func performSiteConnection() async throws {
        let _ = try await jetpackConnectionClient.connectSite(from: "jetpack-app")
    }

    func performUserConnection(account: TaggedManagedObjectID<WPAccount>) async throws {
        let authToken = try await ContextManager.shared.performQuery { context in
            try context.existingObject(with: account).authToken
        }
        guard let authToken else { throw JetpackConnectionError.authenticationFailed }

        let _ = try await jetpackConnectionClient.connectUser(wpComAuthentication: .bearer(token: authToken), from: "jetpack-app")
    }

    func performFinalization(account accountID: TaggedManagedObjectID<WPAccount>) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let account: WPAccount
                do {
                    account = try ContextManager.shared.mainContext.existingObject(with: accountID)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                let service = WordPressComSyncService(coreDataStack: ContextManager.shared)
                service.syncOrAssociateBlogs(
                    account: account,
                    isJetpackLogin: true,
                    onSuccess: { _ in continuation.resume(returning: ()) },
                    onFailure: { continuation.resume(throwing: $0) }
                )
            }
        }

        // Refresh the blog options, so that we can get the latest Jetpack related status.
        try await withCheckedThrowingContinuation { [blogId] (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let blog: Blog
                do {
                    blog = try ContextManager.shared.mainContext.existingObject(with: blogId)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                let service = BlogService(coreDataStack: ContextManager.shared)
                service.syncBlog(
                    blog,
                    success: { continuation.resume(returning: ()) },
                    failure: { continuation.resume(throwing: $0) }
                )
            }
        }
    }
}

extension PluginSlug {
    static let jetpack = Self.init(slug: "jetpack/jetpack")
}

extension PluginWpOrgDirectorySlug {
    static let jetpack = Self.init(slug: "jetpack")
}

enum JetpackConnectionStep: Int, CaseIterable {
    case login
    case install
    case siteConnection
    case userConnection
    case finalize

    var title: String {
        switch self {
        case .login:
            Strings.stepLoginTitle
        case .install:
            Strings.stepInstallTitle
        case .siteConnection:
            Strings.stepSiteConnectionTitle
        case .userConnection:
            Strings.stepUserConnectionTitle
        case .finalize:
            Strings.stepFinalizeTitle
        }
    }

    var event: WPAnalyticsEvent {
        switch self {
        case .login:
            return .jetpackConnectLogin
        case .install:
            return .jetpackConnectInstall
        case .siteConnection:
            return .jetpackConnectSiteConnection
        case .userConnection:
            return .jetpackConnectUserConnection
        case .finalize:
            return .jetpackConnectFinalize
        }
    }
}

private enum StepContext {
    case initial
    case loggedIn(account: TaggedManagedObjectID<WPAccount>)
    case installed(account: TaggedManagedObjectID<WPAccount>)
    case siteConnected(account: TaggedManagedObjectID<WPAccount>)
    case userConnected(account: TaggedManagedObjectID<WPAccount>)
    case finalized
}

enum StepStage {
    case pending
    case processing
    case success
    case error(String)

    var description: String {
        switch self {
        case .pending:
            return Strings.stagePending
        case .processing:
            return Strings.stageProcessing
        case .success:
            return Strings.stageSuccess
        case .error(let message):
            return message
        }
    }
}

private enum Strings {
    static let stepLoginTitle = NSLocalizedString(
        "jetpack.connection.step.login.title",
        value: "Login to WordPress.com",
        comment: "Title for the login step in Jetpack connection flow"
    )

    static let stepInstallTitle = NSLocalizedString(
        "jetpack.connection.step.install.title",
        value: "Install Jetpack",
        comment: "Title for the install step in Jetpack connection flow"
    )

    static let stepSiteConnectionTitle = NSLocalizedString(
        "jetpack.connection.step.site.title",
        value: "Connect to your site",
        comment: "Title for the site connection step in Jetpack connection flow"
    )

    static let stepUserConnectionTitle = NSLocalizedString(
        "jetpack.connection.step.user.title",
        value: "Connect to your WordPress.com account",
        comment: "Title for the user connection step in Jetpack connection flow"
    )

    static let stepFinalizeTitle = NSLocalizedString(
        "jetpack.connection.step.finalize.title",
        value: "Finalize Connection",
        comment: "Title for the finalization step in Jetpack connection flow"
    )

    static let stagePending = NSLocalizedString(
        "jetpack.connection.stage.pending",
        value: "Waiting to start",
        comment: "Status message when a connection step is pending"
    )

    static let stageProcessing = NSLocalizedString(
        "jetpack.connection.stage.processing",
        value: "In progress...",
        comment: "Status message when a connection step is in progress"
    )

    static let stageSuccess = NSLocalizedString(
        "jetpack.connection.stage.success",
        value: "Completed",
        comment: "Status message when a connection step is completed successfully"
    )

    static let errorAuthenticationFailed = NSLocalizedString(
        "jetpack.connection.error.authentication",
        value: "Invalid WordPress.com account",
        comment: "Error message shown when WordPress.com authentication fails"
    )

    static let errorUnexpectedContext = NSLocalizedString(
        "jetpack.connection.error.context",
        value: "This step is not ready yet",
        comment: "Error message shown when a connection step is attempted in an invalid order"
    )
}
