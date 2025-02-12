import Foundation
import SwiftUI
import AsyncImageKit
import WordPressCore
import WordPressAPIInternal

struct PluginDetailsView: View {
    let slug: PluginWpOrgDirectorySlug
    // TODO: This should be optional, to support installing a new plugin
    let plugin: InstalledPlugin
    let service: PluginServiceProtocol

    @State var newVersion: UpdateCheckPluginInfo? = nil
    @State private var tappedScreenshot: Screenshot? = nil
    @StateObject var viewModel: WordPressPluginDetailViewModel
    @State var isShowingSafariView = false
    @State private var showDeleteConfirmation = false

    @Environment(\.dismiss) var dismiss

    init(slug: PluginWpOrgDirectorySlug, plugin: InstalledPlugin, service: PluginServiceProtocol) {
        self.slug = slug
        self.plugin = plugin
        self.service = service
        _viewModel = StateObject(wrappedValue: .init(slug: slug, service: service))
    }

    var body: some View {
        List {
            banner()

            Section {
                HStack(alignment: .top) {
                    PluginIconView(slug: slug, service: service)

                    VStack(alignment: .leading) {
                        Text(plugin.name.makePlainText())
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(3, reservesSpace: false)
                        Text(Strings.author(plugin.author))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    Button(plugin.isActive ? Strings.activatedButton : Strings.activateButton) {
                        Task {
                            await viewModel.activate(plugin)
                        }
                    }
                    .font(plugin.isActive ? .callout : .callout.bold())
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(plugin.isActive || viewModel.isUninstalling)
                }
                .listRowSeparator(.hidden)

                Text(plugin.shortDescription.makePlainText())
                    .font(.body)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)

            if viewModel.isUninstalling {
                uninstallingView()
            } else if let newVersion {
                updateAvailableView(newVersion)
            }

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
        .task(id: 0) {
            await viewModel.onAppear()
        }
        .task(id: slug) {
            await viewModel.performQuery()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(Strings.deleteButton, systemImage: "trash")
                    }

                    if let url = plugin.possibleWpOrgDirectoryURL {
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
                    await viewModel.uninstall(plugin)
                    dismiss()
                }
            }
        } message: {
            Text(Strings.deletePluginMessage(plugin.name.makePlainText()))
        }
        .sheet(isPresented: $isShowingSafariView) {
            if let url = plugin.possibleWpOrgDirectoryURL {
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

            Button(Strings.updateNow) {
                // TODO: Handle update action
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private func uninstallingView() -> some View {
        HStack {
            ProgressView()

            VStack(alignment: .leading) {
                Text(Strings.uninstallingTitle)
                    .font(.headline)
                Text(Strings.uninstallingMessage)
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

@MainActor
final class WordPressPluginDetailViewModel: ObservableObject {
    let slug: PluginWpOrgDirectorySlug
    let service: PluginServiceProtocol

    @Published private(set) var isLoading = false
    @Published private(set) var isUninstalling = false
    @Published private(set) var plugin: PluginInformation?
    @Published private(set) var error: String?
    @Published private(set) var isActivating = false

    private var initialLoad = false

    init(slug: PluginWpOrgDirectorySlug, service: PluginServiceProtocol) {
        self.slug = slug
        self.service = service
    }

    func onAppear() async {
        guard !initialLoad else { return }

        initialLoad = true

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            try await service.fetchPluginInformation(slug: slug)
        } catch {
            self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
        }
    }

    func performQuery() async {
        for await update in await self.service.pluginInformationUpdates(query: .slug(slug)) {
            switch update {
            case let .success(plugin):
                self.plugin = plugin.first
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }

    func activate(_ plugin: InstalledPlugin) async {
        isActivating = true
        defer {
            isActivating = false
        }

        do {
            try await service.togglePluginActivation(slug: plugin.slug)
        } catch {
            // TODO: Show an error notice
        }
    }

    func uninstall(_ plugin: InstalledPlugin) async {
        isUninstalling = true
        defer {
            isUninstalling = false
        }

        do {
            try await service.uninstalledPlugin(slug: plugin.slug)
        } catch {
            // TODO: Show an error notice
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
            value: "Version %@ is available",
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

    static let activateButton = NSLocalizedString(
        "pluginDetails.activate.button",
        value: "Activate",
        comment: "Button label to activate a plugin"
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
}
