import SwiftUI
import WordPressCore

enum PluginInstallationState: Equatable {
    case start
    case installing
    case installationError(Error)
    case installationCancelled
    case installationComplete

    static func == (lhs: PluginInstallationState, rhs: PluginInstallationState) -> Bool {
        return switch (lhs, rhs) {
        case (.start, .start): true
        case (.installing, .installing): true
        case (.installationError, .installationError): true
        case (.installationCancelled, .installationCancelled): true
        case (.installationComplete, .installationComplete): true
        default: false
        }
    }
}

protocol PluginInstallerProtocol {
    func installAndActivatePlugin(slug: String) async throws
}

struct PluginInstallationPrompt: View {
    @Environment(\.dismiss) private var _dismiss
    @Environment(\.openURL) private var openURL

    let pluginDetails: RecommendedPlugin
    let installer: PluginInstallerProtocol
    let wasDismissed: ((PluginInstallationState) -> Void)?

    @State
    private var state: PluginInstallationState = .start

    @State
    private var error: Error? = nil

    @State
    private var isCancelling: Bool = false

    @State
    private var installationTask: Task<Void, Error>? = nil

    public init(
        plugin: RecommendedPlugin,
        installer: PluginInstallerProtocol,
        wasDismissed: ((PluginInstallationState) -> Void)? = nil
    ) {
        self.pluginDetails = plugin
        self.installer = installer
        self.wasDismissed = wasDismissed
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = self.pluginDetails.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                } placeholder: {
                    ProgressView()
                }
            }

            Group {
                switch self.state {
                case .start:
                    self.installationPrompt
                case .installationError(let error): self.installationProgress(error: error)
                case .installing, .installationComplete: self.installationProgress()
                case .installationCancelled:
                    self.installationCancelled
                }
            }.padding()
        }
        .presentationDetents(self.presentationDetents)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    var installationPrompt: some View {
        VStack(alignment: .leading) {
            Text(pluginDetails.usageTitle)
                    .font(.title)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

            Text(pluginDetails.usageDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

            Link("Learn More", destination: pluginDetails.helpUrl)
                .environment(\.openURL, OpenURLAction { url in  print("Open \(url)")
                    return .handled
                })

            Spacer()

            Button {
                self.installPlugin()
            } label: {
                Text("Install Plugin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("installPluginButton")

            Button {
                self.dismiss()
            } label: {
                Spacer()
                Text("Dismiss")
                Spacer()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("dismissInstallPromptButton")
        }
    }

    @ViewBuilder
    func installationProgress(error: Error? = nil) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(self.progressHeader)
                    .font(.title)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }

            Text(self.progressBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)

            if case .installing = state {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView().controlSize(.extraLarge)
                    Spacer()
                }
            }

            Spacer()

            if case .installationComplete = self.state {
                Button(role: .none) {
                    self.dismiss()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("dismissPluginInstallationButton")
            }

            if case .installationError = self.state {
                Button(role: .none) {
                    self.installPlugin()
                } label: {
                    Text("Retry").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("installPluginButton")

                Button(role: .destructive) {
                    self.isCancelling = true
                } label: {
                    Text("Cancel").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("cancelPluginInstallationButton")
            }

        }.alert("Are you sure you want to cancel installation?", isPresented: self.$isCancelling) {

            Button("Continue Installation", role: .cancel) {
                self.isCancelling = false
            }

            Button("Cancel Installation", role: .destructive) {
                self.dismiss()
            }
        }
    }

    @ViewBuilder
    var installationCancelled: some View {
        Text("Installation Cancelled")
                .font(.title)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

        Spacer()

        Button(role: .none) {
            self.dismiss()
        } label: {
            Text("Done").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier("dismissPluginInstallationButton")
    }

    func installPlugin() {
        self.installationTask = Task {
            self.state = .installing

            do {
                try await self.installer.installAndActivatePlugin(slug: pluginDetails.slug)
                self.state = .installationComplete
            } catch {
                self.state = .installationError(error)
            }
        }
    }

    func dismiss() {
        self.wasDismissed?(self.state)
        self._dismiss()
    }

    func cancelPluginInstallation() {
        self.installationTask?.cancel()
        self.state = .installationCancelled
    }

    private var progressHeader: String {
        return switch self.state {
        case .installing: "Installing \(pluginDetails.name)"
        case .installationError: "Installation Failed"
        case .installationComplete: "Installation Complete"
        default: preconditionFailure("Unhandled state")
        }
    }

    private var progressBody: String {
        return switch self.state {
        case .installing: "Installing the \(pluginDetails.name) Plugin on your site. This should only take a moment."
        case .installationError(let error): error.localizedDescription
        case .installationComplete: pluginDetails.successMessage
        default: preconditionFailure("Unhandled state")
        }
    }

    private var presentationDetents: Set<PresentationDetent> {
        return switch UIDevice.current.userInterfaceIdiom {
        case .phone: [.medium]
        case .pad, .mac: [.large]
        default: preconditionFailure("Unhandled device idiom")
        }
    }
}

fileprivate struct DummyInstaller: PluginInstallerProtocol {
    func installAndActivatePlugin(slug: String) async throws {

        try await Task.sleep(for: .seconds(1))

        if Bool.random() {
            throw NSError(domain: "org.wordpress.plugins", code: 1, userInfo: nil)
        }
    }
}

fileprivate let gutenbergDetails = RecommendedPlugin(
    name: "Gutenberg",
    slug: "gutenberg",
    usageTitle: "Install Gutenberg",
    usageDescription: "To see your theme styles as you write, you'll need to install the Gutenberg plugin.",
    successMessage: "Now you can see your theme styles as you write.",
    imageUrl: URL(string: "https://ps.w.org/gutenberg/assets/banner-1544x500.jpg?rev=1718710"),
    helpUrl: URL(string: "https://jetpack.com/support/")!
)

fileprivate let jetpackDetails = RecommendedPlugin(
    name: "Jetpack",
    slug: "jetpack",
    usageTitle: "Install Jetpack to continue",
    usageDescription: "To preview posts and pages you'll need to install the Jetpack plugin.",
    successMessage: "Now you can preview and edit your content.",
    imageUrl: URL(string: "https://ps.w.org/jetpack/assets/banner-1544x500.png?rev=2653649"),
    helpUrl: URL(string: "https://wordpress.org/support/article/managing-plugins/#installing-plugins")!
)

fileprivate let noBannerDetails = RecommendedPlugin(
    name: "No Banner",
    slug: "no-banner",
    usageTitle: "Install No Banner to continue",
    usageDescription: "To preview posts and pages you'll need to install the Jetpack plugin.",
    successMessage: "Now you can preview and edit your content.",
    imageUrl: nil,
    helpUrl: URL(string: "https://wordpress.org/support/article/managing-plugins/#installing-plugins")!
)

#Preview("Gutenberg") {
    PluginInstallationPrompt(
        plugin: gutenbergDetails,
        installer: DummyInstaller()
    )
}

#Preview("Jetpack") {
    PluginInstallationPrompt(
        plugin: jetpackDetails,
        installer: DummyInstaller()
    )
}

#Preview("No Banner") {
    PluginInstallationPrompt(
        plugin: noBannerDetails,
        installer: DummyInstaller()
    )
}
