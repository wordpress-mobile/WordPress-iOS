import Foundation
import SwiftUI
import AsyncImageKit
import WordPressCore
import WordPressAPIInternal

struct PluginDetailsView: View {
    private struct BasicPluginInfo {
        var name: String
        var author: String
        var shortDescription: String

        init(name: String, author: String, shortDescription: String) {
            self.name = name.makePlainText()
            self.author = author.makePlainText()
            self.shortDescription = shortDescription.makePlainText()
        }
    }

    let slug: PluginWpOrgDirectorySlug
    let service: PluginServiceProtocol

    private let pluginInfo: BasicPluginInfo

    @State private var tappedScreenshot: Screenshot? = nil
    @StateObject var viewModel: WordPressPluginDetailViewModel
    @State var isShowingSafariView = false
    @State private var showDeleteConfirmation = false

    @Environment(\.dismiss) var dismiss

    var wpOrgURL: URL? {
        URL(string: "https://wordpress.org/plugins/\(slug.slug)/")
    }

    var actionButton: ActionButton {
        if let plugin = viewModel.installed {
            return plugin.isActive
                ? .activated(plugin: plugin)
                : .activate(plugin: plugin) {
                    Task { await viewModel.updatePluginStatus(plugin, activated: true) }
                }
        } else {
            return .install(slug: slug) {
                Task { await viewModel.install(slug) }
            }
        }
    }

    init(plugin: PluginInformation, service: PluginServiceProtocol) {
        let slug = PluginWpOrgDirectorySlug(slug: plugin.slug)
        self.slug = slug
        // TODO: Use `shortDescription`
        self.pluginInfo = .init(name: plugin.name, author: plugin.author, shortDescription: plugin.author)
        self.service = service
        _viewModel = StateObject(wrappedValue: .init(service: service))
    }

    init(slug: PluginWpOrgDirectorySlug, plugin: InstalledPlugin, service: PluginServiceProtocol) {
        self.slug = slug
        self.pluginInfo = .init(name: plugin.name, author: plugin.author, shortDescription: plugin.shortDescription)
        self.service = service
        _viewModel = StateObject(wrappedValue: .init(service: service))
    }

    var body: some View {
        List {
            banner()

            Section {
                HStack(alignment: .top) {
                    PluginIconView(slug: slug, service: service)

                    VStack(alignment: .leading) {
                        Text(pluginInfo.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(3, reservesSpace: false)
                        Text(Strings.author(pluginInfo.author))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    actionButton
                        .view
                        .disabled(viewModel.isLoading || (viewModel.operation?.isCompleted == false))
                }
                .listRowSeparator(.hidden)

                if let operation = viewModel.operation, !operation.isCompleted {
                    switch operation.operation {
                    case .install:
                        inlineProgressView(title: Strings.installingTitle, message: Strings.installingMessage)
                    case .uninstall:
                        inlineProgressView(title: Strings.uninstallingTitle, message: Strings.uninstallingMessage)
                    case .activate:
                        inlineProgressView(title: Strings.activatingTitle, message: Strings.activatingMessage)
                    case .deactivate:
                        inlineProgressView(title: Strings.deactivatingTitle, message: Strings.deactivatingMessage)
                    }
                } else if let error = viewModel.operation?.errorMessage {
                    errorView(title: SharedStrings.Error.generic, message: error)
                } else if let newVersion = viewModel.newVersion {
                    updateAvailableView(newVersion)
                }

                Text(pluginInfo.shortDescription)
                    .font(.body)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            if viewModel.isLoading {
                ProgressView(Strings.loadingPluginInformation)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            } else if let info = viewModel.plugin {
                pluginInfomationView(info)
            }
        }
        .listStyle(.plain)
        .task(id: slug) {
            await viewModel.loadData(slug)
        }
        .task(id: viewModel.installed?.slug) {
            await viewModel.versionUpdate()
        }
        .task(id: slug) {
            await viewModel.performQuery(slug)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.installed != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(Strings.deleteButton, systemImage: "trash")
                        }
                    }

                    if let installed = viewModel.installed, installed.isActive {
                        Button {
                            Task { await viewModel.updatePluginStatus(installed, activated: false) }
                        } label: {
                            Label(Strings.deactivateButton, systemImage: "circle.slash")
                        }
                    }

                    if let url = wpOrgURL {
                        Section {
                            ShareLink(item: url)
                            Button {
                                isShowingSafariView = true
                            } label: {
                                Label(Strings.viewOnWordPressOrgButton, systemImage: "safari")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(Strings.deletePluginTitle, isPresented: $showDeleteConfirmation) {
            Button(SharedStrings.Button.cancel, role: .cancel) { }
            Button(SharedStrings.Button.delete, role: .destructive) {
                Task { @MainActor in
                    if let plugin = viewModel.installed, await viewModel.uninstall(plugin) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(Strings.deletePluginMessage(pluginInfo.name))
        }
        .sheet(isPresented: $isShowingSafariView) {
            if let url = wpOrgURL {
                SafariView(url: url)
            }
        }
    }

    @ViewBuilder
    private func banner() -> some View {
        CachedAsyncImage(url: viewModel.plugin?.bannerURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "photo")
                .frame(width: 44, height: 44)
        }
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 300)
        .listRowInsets(.zero)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func updateAvailableView(_ info: UpdateCheckPluginInfo) -> some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(Strings.updateAvailable)
                    .font(.headline)
                Text(Strings.versionAvailable(info.newVersion))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private func inlineProgressView(title: String, message: String) -> some View {
        HStack {
            ProgressView()

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private func errorView(title: String, message: String) -> some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.exclamationmark")

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private func pluginInfomationView(_ info: PluginInformation) -> some View {
        let screenshots = info.screenshotsList
        if !screenshots.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.screenshots)
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(screenshots) { screenshot in
                            CachedAsyncImage(url: URL(string: screenshot.src)) {image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .onTapGesture {
                                        tappedScreenshot = screenshot
                                    }
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 150, height: 200)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .pagingIfAvailable()
            }
            .padding(.vertical)
            .listRowInsets(.zero)
            .listRowSeparator(.hidden)
            .fullScreenCover(item: $tappedScreenshot) {
                if let viewController = self.lightbox(screenshot: $0) {
                    LightboxView(viewController: viewController)
                        .ignoresSafeArea()
                } else {
                    EmptyView()
                }
            }
        }

        if let content = info.sectionContent(id: "description") {
            NavigationLink(Strings.description) {
                PluginInfoSectionContentView(title: Strings.description, content: content)
            }
        }

        if let content = info.sectionContent(id: "installation") {
            NavigationLink(Strings.installation) {
                PluginInfoSectionContentView(title: Strings.installation, content: content)
            }
        }

        if let content = info.sectionContent(id: "faq") {
            NavigationLink(Strings.faq) {
                PluginInfoSectionContentView(title: Strings.faq, content: content)
            }
        }

        if let content = info.sectionContent(id: "changelog") {
            NavigationLink(Strings.changelog) {
                PluginInfoSectionContentView(title: Strings.changelog, content: content)
            }
        }

        if let content = info.sectionContent(id: "reviews") {
            NavigationLink {
                PluginInfoSectionContentView(title: Strings.reviews, content: content)
            } label: {
                HStack {
                    Text(Strings.reviews)
                    Spacer()
                    RatingView(percentage: info.rating)
                }
            }
        }
    }

    private func lightbox(screenshot: Screenshot) -> LightboxViewController? {
        guard let url = URL(string: screenshot.src) else { return nil }

        let lightbox = LightboxViewController(.asset(.init(sourceURL: url)))
        lightbox.configureZoomTransition()
        return lightbox
    }
}

private struct RatingView: View {
    let rating: Double
    let maxRating: Int = 5

    init(percentage: UInt32) {
        self.rating = Double(percentage) / 100 * Double(maxRating)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                if Double(index) <= rating {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                } else if Double(index) - rating < 1 {
                    Image(systemName: "star.leadinghalf.filled")
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.yellow)
                }
            }
        }
        .imageScale(.small)
    }
}

enum ActionButton {
    case install(slug: PluginWpOrgDirectorySlug, action: () -> Void)
    case activate(plugin: InstalledPlugin, action: () -> Void)
    case activated(plugin: InstalledPlugin)

    @ViewBuilder
    var view: some View {
        button
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
    }

    @ViewBuilder
    private var button: some View {
        switch self {
        case let .install(_, action):
            Button(Strings.installButton, action: action)
                .font(.callout.bold())
        case let .activate(_, action):
            Button(Strings.activateButton, action: action)
                .font(.callout.bold())
        case .activated:
            Button(Strings.activatedButton, action: { })
                .font(.callout)
                .disabled(true)
        }
    }
}

private enum PluginOperation: Hashable {
    case install
    case uninstall
    case activate
    case deactivate
}

private struct PluginOperationStatus {
    var operation: PluginOperation
    var result: Result<Void, Error>?

    var isCompleted: Bool {
        result != nil
    }

    var errorMessage: String? {
        if case let .failure(error)? = result {
            return (error as? WpApiError)?.errorMessage ?? error.localizedDescription
        }
        return nil
    }
}

@MainActor
final class WordPressPluginDetailViewModel: ObservableObject {
    let service: PluginServiceProtocol

    @Published private(set) var isLoading = false
    @Published private(set) var plugin: PluginInformation?
    @Published private(set) var installed: InstalledPlugin?
    @Published var newVersion: UpdateCheckPluginInfo?
    @Published private(set) var error: String?

    @Published private(set) fileprivate var operation: PluginOperationStatus?

    var previouslyLoadedSlug: PluginWpOrgDirectorySlug?

    init(service: PluginServiceProtocol) {
        self.service = service
    }

    func loadData(_ slug: PluginWpOrgDirectorySlug) async {
        guard previouslyLoadedSlug != slug else { return }
        previouslyLoadedSlug = slug

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            self.installed = try await service.findInstalledPlugin(slug: slug)
            try await service.fetchPluginInformation(slug: slug)

            // Re-fetch installed plugins to ensure a more accurate check of whether the plugin is already installed
            try await service.fetchInstalledPlugins()
            self.installed = try await service.findInstalledPlugin(slug: slug)
        } catch {
            self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
        }
    }

    func performQuery(_ slug: PluginWpOrgDirectorySlug) async {
        for await update in await self.service.pluginInformationUpdates(query: .slug(slug)) {
            switch update {
            case let .success(plugin):
                self.plugin = plugin.first
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }

    func versionUpdate() async {
        if let slug = installed?.slug {
            for await update in await service.newVersionUpdates(query: .slug(slug)) {
                newVersion = (try? update.get().first)
            }
        } else {
            newVersion = nil
        }
    }

    func updatePluginStatus(_ plugin: InstalledPlugin, activated: Bool) async {
        if let operation, !operation.isCompleted {
            DDLogWarn("Can't update plugin status at the moment, because there is another operation in progress: \(operation)")
            return
        }

        let operation = activated ? PluginOperation.activate : PluginOperation.deactivate

        do {
            self.operation = .init(operation: operation)
            self.installed = try await service.updatePluginStatus(plugin: plugin, activated: false)
            self.operation = .init(operation: operation, result: .success(()))
        } catch {
            self.operation = .init(operation: operation, result: .failure(error))
        }
    }

    func uninstall(_ plugin: InstalledPlugin) async -> Bool {
        if let operation, !operation.isCompleted {
            DDLogWarn("Can't uninsatll plugin at the moment, because there is another operation in progress: \(operation)")
            return false
        }

        do {
            self.operation = .init(operation: .uninstall)
            try await service.uninstalledPlugin(slug: plugin.slug)
            self.operation = .init(operation: .uninstall, result: .success(()))
            return true
        } catch {
            self.operation = .init(operation: .uninstall, result: .failure(error))
            return false
        }
    }

    func install(_ slug: PluginWpOrgDirectorySlug) async {
        if let operation, !operation.isCompleted {
            DDLogWarn("Can't install plugin at the moment, because there is another operation in progress: \(operation)")
            return
        }

        do {
            self.operation = .init(operation: .install)
            self.installed = try await service.installPlugin(slug: slug)
            self.operation = .init(operation: .install, result: .success(()))
        } catch {
            self.operation = .init(operation: .install, result: .failure(error))
        }
    }
}

private extension PluginInformation {
    var bannerURL: URL? {
        if !banners.high.isEmpty, let url = URL(string: banners.high) {
            return url
        }
        if !banners.low.isEmpty, let url = URL(string: banners.low) {
            return url
        }
        return nil
    }

    func sectionContent(id: String) -> String? {
        guard let content = sections[id] else { return nil }
        return content.isEmpty ? nil : content
    }

    var screenshotsList: [Screenshot] {
        switch screenshots {
        case let .named(dict):
            return dict.sorted(by: { $0.key < $1.key }).map(\.value)
        case let .unnamed(list):
            return list
        }
    }
}

extension Screenshot: @retroactive Identifiable {
    public var id: String { src }
}

extension Ratings {
    var numberOfRatings: UInt32 {
        oneStar + twoStar + threeStar + fourStar + fiveStar
    }
}

private struct LightboxView: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private enum Strings {
    static let screenshots = NSLocalizedString(
        "pluginDetails.section.screenshots",
        value: "Screenshots",
        comment: "Title of the screenshots section in plugin details"
    )

    static let details = NSLocalizedString(
        "pluginDetails.section.details",
        value: "Details",
        comment: "Title of the details section in plugin details"
    )

    static let description = NSLocalizedString(
        "pluginDetails.section.description",
        value: "Description",
        comment: "Title of the description section in plugin details"
    )

    static let installation = NSLocalizedString(
        "pluginDetails.section.installation",
        value: "Installation",
        comment: "Title of the installation section in plugin details"
    )

    static let faq = NSLocalizedString(
        "pluginDetails.section.faq",
        value: "FAQ",
        comment: "Title of the FAQ section in plugin details"
    )

    static let changelog = NSLocalizedString(
        "pluginDetails.section.changelog",
        value: "Changelog",
        comment: "Title of the changelog section in plugin details"
    )

    static let reviews = NSLocalizedString(
        "pluginDetails.section.reviews",
        value: "Reviews",
        comment: "Title of the reviews section in plugin details"
    )

    static let updateAvailable = NSLocalizedString(
        "pluginDetails.update.title",
        value: "Update Available",
        comment: "Title shown when a plugin update is available"
    )

    static func versionAvailable(_ version: String) -> String {
        let format = NSLocalizedString(
            "pluginDetails.update.versionAvailable",
            value: "Version %@ is available. Please update it from your WordPress site dashboard.",
            comment: "Message shown when a plugin update is available. The placeholder is the new version number"
        )
        return String(format: format, version)
    }

    static let updateNow = NSLocalizedString(
        "pluginDetails.update.action",
        value: "Update Now",
        comment: "Button title to update a plugin"
    )

    static let loadingPluginInformation = NSLocalizedString(
        "pluginDetails.loading",
        value: "Loading plugin information...",
        comment: "Message shown while loading plugin details"
    )

    static func author(_ author: String) -> String {
        let format = NSLocalizedString(
            "pluginDetails.author",
            value: "By %@",
            comment: "Plugin author information. The placeholder is the author name"
        )
        return String(format: format, author)
    }

    static let deletePluginTitle = NSLocalizedString(
        "pluginDetails.delete.confirmationTitle",
        value: "Delete Plugin?",
        comment: "Title of the confirmation alert when deleting a plugin"
    )

    static let deletePluginMessage = { (name: String) in
        let format = NSLocalizedString(
            "pluginDetails.delete.confirmationMessage",
            value: "Are you sure you want to delete %@?",
            comment: "Message of the confirmation alert when deleting a plugin. The placeholder is the plugin name"
        )
        return String(format: format, name)
    }

    static let deleteButton = NSLocalizedString(
        "pluginDetails.delete.button",
        value: "Delete",
        comment: "Button label to delete a plugin"
    )

    static let viewOnWordPressOrgButton = NSLocalizedString(
        "pluginDetails.viewOnWordPressOrg.button",
        value: "View on WordPress.org",
        comment: "Button label to view plugin on WordPress.org"
    )

    static let installButton = NSLocalizedString(
        "pluginDetails.install.button",
        value: "Install",
        comment: "Button label to install a plugin"
    )

    static let activateButton = NSLocalizedString(
        "pluginDetails.activate.button",
        value: "Activate",
        comment: "Button label to activate a plugin"
    )

    static let deactivateButton = NSLocalizedString(
        "pluginDetails.deactivate.button",
        value: "Deactivate",
        comment: "Button label to deactivate a plugin"
    )

    static let activatedButton = NSLocalizedString(
        "pluginDetails.activated.button",
        value: "Activated",
        comment: "Button label showing plugin is activated"
    )

    static let uninstallingTitle = NSLocalizedString(
        "pluginDetails.uninstalling.title",
        value: "Uninstalling Plugin",
        comment: "Title shown while a plugin is being uninstalled"
    )

    static let uninstallingMessage = NSLocalizedString(
        "pluginDetails.uninstalling.message",
        value: "Please wait while the plugin is being removed...",
        comment: "Message shown while a plugin is being uninstalled"
    )

    static let installingTitle = NSLocalizedString(
        "pluginDetails.install.title",
        value: "Install Plugin",
        comment: "Title shown while a plugin is being installed"
    )

    static let installingMessage = NSLocalizedString(
        "pluginDetails.install.message",
        value: "Please wait while the plugin is being installed...",
        comment: "Message shown while a plugin is being installed"
    )

    static let activatingTitle = NSLocalizedString(
        "pluginDetails.activating.title",
        value: "Activating Plugin",
        comment: "Title shown while a plugin is being activated"
    )

    static let activatingMessage = NSLocalizedString(
        "pluginDetails.activating.message",
        value: "Please wait while the plugin is being activated...",
        comment: "Message shown while a plugin is being activated"
    )

    static let deactivatingTitle = NSLocalizedString(
        "pluginDetails.deactivating.title",
        value: "Deactivating Plugin",
        comment: "Title shown while a plugin is being deactivated"
    )

    static let deactivatingMessage = NSLocalizedString(
        "pluginDetails.deactivating.message",
        value: "Please wait while the plugin is being deactivated...",
        comment: "Message shown while a plugin is being deactivated"
    )
}

private extension View {

    @ViewBuilder
    func pagingIfAvailable() -> some View {
        if #available(iOS 17.0, *) {
            scrollTargetBehavior(.paging)
        }
    }

}
