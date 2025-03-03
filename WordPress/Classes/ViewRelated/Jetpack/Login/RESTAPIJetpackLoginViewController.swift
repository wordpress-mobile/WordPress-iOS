import Foundation
import UIKit
import SwiftUI
import WordPressCore
import WordPressAPIInternal

class RESTAPIJetpackLoginViewController: UIViewController, JetpackConnectionSupport {

    required init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var blog: Blog

    var promptType: JetpackLoginPromptType = .stats

    var completionBlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = JetpackConnectionViewModel(blog: blog, presentingViewController: self, completionHandler: { [weak self] in
            self?.completionBlock?()
        })
        let jetpackView = JetpackConnectionView(promptType: promptType, viewModel: viewModel)

        let hostingController = UIHostingController(rootView: jetpackView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    func refreshUI() {
        // Do nothing.
    }
}

private enum JetpackConnectionStep: Int, CaseIterable {
    case login
    case install
    case siteConnection
    case userConnection
    case finalize

    var title: String {
        switch self {
        case .login:
            return Strings.stepLoginTitle
        case .install:
            return Strings.stepInstallTitle
        case .siteConnection:
            return Strings.stepSiteConnectionTitle
        case .userConnection:
            return Strings.stepUserConnectionTitle
        case .finalize:
            return Strings.stepFinalizeTitle
        }
    }
}

private enum StepContext {
    case initial
    case loggedIn(account: TaggedManagedObjectID<WPAccount>)
    case installed(account: TaggedManagedObjectID<WPAccount>)
    case activated(account: TaggedManagedObjectID<WPAccount>)
    case connected(account: TaggedManagedObjectID<WPAccount>)
    case finalized
}

private enum StepStage {
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

private struct JetpackConnectionView: View {
    let promptType: JetpackLoginPromptType
    @ObservedObject private var viewModel: JetpackConnectionViewModel

    init(promptType: JetpackLoginPromptType, viewModel: JetpackConnectionViewModel) {
        self.promptType = promptType
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(promptType.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)

            Text(promptType.connectMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.steps, id: \.rawValue) { step in
                        StepView(
                            step: step,
                            stage: viewModel.stepStages[step] ?? .pending,
                            onRetry: {
                                if step == viewModel.currentStep {
                                    viewModel.retryCurrentStep()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            if !viewModel.isConnecting {
                Button(Strings.connectButtonTitle) {
                    viewModel.connect()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.bottom, 12)
            } else if viewModel.isCompleted {
                CompletedAnimationView {
                    viewModel.finish()
                }
                .padding(.bottom, 12)
            }
        }
    }
}

private struct CompletedAnimationView: View {
    let onAnimationComplete: () -> Void
    let animationDuration: TimeInterval = 0.5

    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var hasTriggeredCallback = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 36))
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                let animation = Animation.spring(response: animationDuration)

                if #available(iOS 17.0, *) {
                    withAnimation(animation) {
                        scale = 1.0
                        opacity = 1.0
                    } completion: {
                        onAnimationComplete()
                    }
                } else {
                    withAnimation(animation) {
                        scale = 1.0
                        opacity = 1.0
                    }

                    guard !hasTriggeredCallback else { return }
                    hasTriggeredCallback = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        onAnimationComplete()
                    }
                }
            }
    }
}

private struct StepView: View {
    let step: JetpackConnectionStep
    let stage: StepStage
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            statusIndicator
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(step.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(stage.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if case .error = stage {
                Button(action: onRetry) {
                    Text(Strings.retryButtonTitle)
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(3)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(indicatorBackgroundColor)
                .frame(width: 22, height: 22)

            switch stage {
            case .pending:
                Text(verbatim: "\(step.rawValue + 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            case .processing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.5)
            case .success:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            case .error:
                Image(systemName: "exclamationmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var indicatorBackgroundColor: Color {
        switch stage {
        case .pending:
            return Color.gray
        case .processing:
            return Color.blue
        case .success:
            return Color.green
        case .error:
            return Color.red
        }
    }

    private var borderColor: Color {
        switch stage {
        case .pending:
            return Color(.systemGray5)
        case .processing:
            return Color.blue.opacity(0.3)
        case .success:
            return Color.green.opacity(0.3)
        case .error:
            return Color.red.opacity(0.3)
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

private class JetpackConnectionService {
    private let blog: Blog
    private let client: WordPressClient
    private let jetpackConnectionClient: JetpackConnectionClient

    init(blog: Blog) {
        self.blog = blog
        self.client = try! .init(site: WordPressSite(blog: blog))
        self.jetpackConnectionClient = .init(
            siteUrl: try! .parse(input: blog.url!),
            urlSession: .init(configuration: .ephemeral),
            authentication: .init(username: try! blog.getUsername(), password: try! blog.getApplicationToken())
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

    func performInstall(account: TaggedManagedObjectID<WPAccount>) async throws {
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

    func performSiteConnection(account: TaggedManagedObjectID<WPAccount>) async throws {
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
    }
}

@MainActor
private class JetpackConnectionViewModel: ObservableObject {
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

    init(blog: Blog, presentingViewController: UIViewController, completionHandler: @escaping () -> Void) {
        self.blogID = TaggedManagedObjectID(blog)
        self.presentingViewController = presentingViewController
        self.completionHandler = completionHandler
        self.connectionService = JetpackConnectionService(blog: blog)

        for step in steps {
            stepStages[step] = .pending
        }
    }

    func connect() {
        guard isConnecting == false else { return }

        isConnecting = true
        Task {
            await processCurrentStep()
        }
    }

    private func processCurrentStep() async {
        stepStages[currentStep] = .processing

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

            if let nextStep = self.nextStep() {
                currentStep = nextStep
                await processCurrentStep()
            } else {
                isCompleted = true
            }
        } catch {
            stepStages[currentStep] = .error(error.localizedDescription)
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

        try await connectionService.performInstall(account: account)
        stepContext = .installed(account: account)
    }

    private func performSiteConnection() async throws {
        guard case .installed(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performSiteConnection(account: account)
        stepContext = .activated(account: account)
    }

    private func performUserConnection() async throws {
        guard case .activated(let account) = stepContext else {
            throw JetpackConnectionError.unexpectedContext
        }

        try await connectionService.performUserConnection(account: account)
        stepContext = .connected(account: account)
    }

    private func performFinalization() async throws {
        guard case .connected(let account) = stepContext else {
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
        stepStages[currentStep] = .pending
        Task {
            await processCurrentStep()
        }
    }
}

extension PluginSlug {
    static let jetpack = Self.init(slug: "jetpack/jetpack")
}

extension PluginWpOrgDirectorySlug {
    static let jetpack = Self.init(slug: "jetpack")
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

    static let retryButtonTitle = NSLocalizedString(
        "jetpack.connection.retry.button",
        value: "Retry",
        comment: "Title for the retry button shown when a connection step fails"
    )

    static let connectButtonTitle = NSLocalizedString(
        "jetpack.connection.connect.button",
        value: "Connect your site",
        comment: "Title for the button that starts the Jetpack connection process"
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
