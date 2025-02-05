import SwiftUI
import AsyncImageKit
import WordPressUI
import WordPressAPI
import WordPressCore

struct InstalledPluginsListView: View {
    @StateObject private var viewModel: InstalledPluginsListViewModel

    init(client: WordPressClient) {
        self.init(service: PluginService(client: client))
    }

    init(service: PluginServiceProtocol) {
        _viewModel = StateObject(wrappedValue: .init(service: service))
    }

    var body: some View {
        ZStack {
            if let error = viewModel.error {
                EmptyStateView(error, systemImage: "exclamationmark.triangle.fill")
            } else if viewModel.isRefreshing && viewModel.displayingPlugins.isEmpty {
                Label { Text(Strings.loading) } icon: { ProgressView() }
            } else {
                List {
                    Section {
                        ForEach(viewModel.displayingPlugins, id: \.self) { plugin in
                            ZStack {
                                PluginListItemView(plugin: plugin, viewModel: viewModel)
                                if let slug = plugin.possibleWpOrgDirectorySlug {
                                    // Using `PluginListItemView` as `NavigationLink`'s content would show an disclosure
                                    // indicator on the list cell, which looks a bit off with the ellipsis button on the
                                    // list cell.
                                    // Here we use an empty transparent `NavigationLink` as a workaround to hide the
                                    // disclosure indicator.
                                    NavigationLink { PluginDetailsView(slug: slug, plugin: plugin, service: viewModel.service) } label: { EmptyView() }
                                        .opacity(0.0)
                                }
                            }
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                }
                .listStyle(.plain)
                .refreshable(action: viewModel.refreshItems)
            }
        }
        .navigationTitle(Strings.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(Strings.filterTitle, selection: $viewModel.filter) {
                        Text(Strings.filterOptionAll).tag(PluginDataStoreQuery.all)
                        Text(Strings.filterOptionActive).tag(PluginDataStoreQuery.active)
                        Text(Strings.filterOptionInactive).tag(PluginDataStoreQuery.inactive)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: 0) {
            await viewModel.onAppear()
        }
        .task(id: viewModel.filter) {
            await viewModel.performQuery()
        }
    }

    private enum Strings {
        static let title: String = NSLocalizedString("site.plugins.title", value: "Plugins", comment: "Installed plugins list title")
        static let loading: String = NSLocalizedString("site.plugins.loading", value: "Loading installed plugins…", comment: "Message displayed when fetching installed plugins from the site")
        static let noPluginInstalled: String = NSLocalizedString("site.plugins.noInstalledPlugins", value: "You haven't installed any plugins yet", comment: "No installed plugins message")
        static let filterTitle: String = NSLocalizedString("site.plugins.filter.title", value: "Filter", comment: "Title of the plugin filter picker")
        static let filterOptionAll: String = NSLocalizedString("site.plugins.filter.option.all", value: "All", comment: "The plugin fillter option for displaying all plugins")
        static let filterOptionActive: String = NSLocalizedString("site.plugins.filter.option.all", value: "Active", comment: "The plugin fillter option for displaying active plugins")
        static let filterOptionInactive: String = NSLocalizedString("site.plugins.filter.option.all", value: "Inactive", comment: "The plugin fillter option for displaying inactive plugins")
    }
}

@MainActor
final class InstalledPluginsListViewModel: ObservableObject {

    let service: PluginServiceProtocol
    private var initialLoad = false

    @Published var isRefreshing: Bool = false
    @Published var filter: PluginDataStoreQuery = .all
    @Published var displayingPlugins: [InstalledPlugin] = []
    @Published var error: String? = nil

    @Published var updating: Set<PluginSlug> = []

    init(service: PluginServiceProtocol) {
        self.service = service
    }

    func onAppear() async {
        if !initialLoad {
            initialLoad = true
            await refreshItems()
        }
    }

    @Sendable
    func refreshItems() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await self.service.fetchInstalledPlugins()
        } catch {
            self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
        }
    }

    func performQuery() async {
        for await update in await self.service.installedPluginsUpdates(query: filter) {
            switch update {
            case let .success(plugins):
                self.displayingPlugins = plugins
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }

    func toggle(slug: PluginSlug) async {
        self.updating.insert(slug)
        defer { self.updating.remove(slug) }

        do {
            try await self.service.togglePluginActivation(slug: slug)
        } catch {
            DDLogError("Failed to update plugin: \(error)")
        }
    }

    func uninstall(slug: PluginSlug) async {
        self.updating.insert(slug)
        defer { self.updating.remove(slug) }

        do {
            try await self.service.uninstalledPlugin(slug: slug)
        } catch {
            DDLogError("Failed to uninstall plugin: \(error)")
        }

    }
}
