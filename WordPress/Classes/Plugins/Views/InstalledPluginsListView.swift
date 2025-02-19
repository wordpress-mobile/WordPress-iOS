import SwiftUI
import AsyncImageKit
import WordPressUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

struct InstalledPluginsListView: View {
    @StateObject private var viewModel: InstalledPluginsListViewModel

    @State private var presentAddNewPlugin = false

    init(service: PluginServiceProtocol) {
        _viewModel = StateObject(wrappedValue: .init(service: service))
    }

    var body: some View {
        ZStack {
            if let error = viewModel.error {
                EmptyStateView(error, systemImage: "exclamationmark.triangle.fill")
            } else if viewModel.isRefreshing && viewModel.sections.isEmpty {
                Label { Text(Strings.loading) } icon: { ProgressView() }
            } else {
                List {
                    ForEach(viewModel.sections, id: \.self) { section in
                        Section {
                            ForEach(section.plugins, id: \.self) { plugin in
                                NavigationLink {
                                    if let slug = plugin.possibleWpOrgDirectorySlug {
                                        PluginDetailsView(slug: slug, plugin: plugin, service: viewModel.service)
                                    }
                                } label: {
                                    PluginListItemView(
                                        plugin: plugin,
                                        updateAvailable: viewModel.updateAvailable.index(forKey: plugin.slug) != nil,
                                        service: viewModel.service
                                    )
                                }
                            }
                        } header: {
                            Text(section.filter.title)
                                .textCase(nil)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .listSectionSeparator(.hidden, edges: .all)
                    }
                }
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                .refreshable(action: viewModel.refreshItems)
            }
        }
        .navigationTitle(Strings.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentAddNewPlugin = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(Strings.filterTitle, selection: $viewModel.filter) {
                        Text(Strings.filterOptionAll).tag(PluginFilter.all)
                        Text(Strings.filterOptionActive).tag(PluginFilter.active)
                        Text(Strings.filterOptionInactive).tag(PluginFilter.inactive)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $presentAddNewPlugin) {
            NavigationStack {
                AddNewPluginView(service: viewModel.service)
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .task(id: 1) {
            await viewModel.versionUpdate()
        }
        .task(id: viewModel.filter) {
            await viewModel.performQuery()
        }
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

private struct ListSection: Hashable, Identifiable {
    var plugins: [InstalledPlugin]
    var filter: PluginFilter

    var id: PluginFilter { filter }
}

private enum PluginFilter: Int, Hashable {
    // The order here matches the order of grouped plugins
    case all
    case active
    case inactive

    var query: PluginDataStoreQuery {
        switch self {
        case .all:
            return .all
        case .active:
            return .active
        case .inactive:
            return .inactive
        }
    }

    var title: String {
        switch self {
        case .all:
            return Strings.filterOptionAll
        case .active:
            return Strings.filterOptionActive
        case .inactive:
            return Strings.filterOptionInactive
        }
    }
}

@MainActor
private final class InstalledPluginsListViewModel: ObservableObject {

    let service: PluginServiceProtocol
    private var initialLoad = false

    @Published var isRefreshing: Bool = false
    @Published var filter: PluginFilter = .all
    @Published var sections = [ListSection]()
    @Published var updateAvailable: [PluginSlug: UpdateCheckPluginInfo] = [:]
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
        for await update in await self.service.installedPluginsUpdates(query: filter.query) {
            switch update {
            case let .success(plugins):
                self.sections = plugins
                    .reduce(into: [PluginFilter: [InstalledPlugin]]()) { result, plugin in
                        let filter: PluginFilter = plugin.isActive ? .active : .inactive
                        result[filter, default: []].append(plugin)
                    }
                    .map { filter, plugins in
                        ListSection(plugins: plugins, filter: filter)
                    }
                    .sorted(using: KeyPathComparator(\ListSection.filter.rawValue))
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }

    func versionUpdate() async {
        for await update in await self.service.newVersionUpdates(query: .all) {
            guard let updates = try? update.get() else { continue }
            self.updateAvailable = updates.reduce(into: [:]) {
                $0[$1.plugin] = $1
            }
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
