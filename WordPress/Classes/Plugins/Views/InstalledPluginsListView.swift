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
            } else if viewModel.isRefreshing && viewModel.plugins.isEmpty {
                Label { Text(Strings.loading) } icon: { ProgressView() }
            } else {
                List {
                    Section {
                        ForEach(viewModel.plugins, id: \.self) { plugin in
                            PluginListItemView(
                                plugin: plugin,
                                service: viewModel.service
                            )
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                }
                .listStyle(.plain)
                .refreshable(action: viewModel.refreshItems)
            }
        }
        .navigationTitle(Strings.title)
        .task(id: 0) {
            await viewModel.onAppear()
        }
        .task(id: 1) {
            await viewModel.performQuery()
        }
    }

    private enum Strings {
        static let title: String = NSLocalizedString("site.plugins.title", value: "Plugins", comment: "Installed plugins list title")
        static let loading: String = NSLocalizedString("site.plugins.loading", value: "Loading installed plugins…", comment: "Message displayed when fetching installed plugins from the site")
        static let noPluginInstalled: String = NSLocalizedString("site.plugins.noInstalledPlugins", value: "You haven't installed any plugins yet", comment: "No installed plugins message")
    }
}

@MainActor
final class InstalledPluginsListViewModel: ObservableObject {
    let service: PluginServiceProtocol
    private var initialLoad = false

    @Published var isRefreshing: Bool = false
    @Published var plugins: [InstalledPlugin] = []
    @Published var error: String? = nil

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
        for await update in await self.service.installedPluginsUpdates() {
            switch update {
            case let .success(plugins):
                self.plugins = plugins
            case let .failure(error):
                self.error = (error as? WpApiError)?.errorMessage ?? error.localizedDescription
            }
        }
    }
}
