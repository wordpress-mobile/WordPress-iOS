import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal

struct AddNewPluginView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: AddNewPluginViewModel

    init(service: PluginServiceProtocol) {
        _viewModel = .init(wrappedValue: AddNewPluginViewModel(service: service))
    }

    var body: some View {
        List {
            ForEach(viewModel.listSections, id: \.self) { section in
                Section {
                    ForEach(section.rows, id: \.self, content: rowContent(_:))
                } header: {
                    Text(section.header)
                        .textCase(nil)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .listSectionSeparator(.hidden, edges: .all)
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("Add New Plugin")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchInput)
        .toolbar {
            ToolbarItem {
                Button(SharedStrings.Button.cancel, role: .cancel) {
                    dismiss()
                }
            }
        }
        .task(id: 0) {
            await viewModel.onAppear()
        }
        .task(id: viewModel.mode) {
            await viewModel.performQuery()
        }
    }

    @ViewBuilder
    func pluginSectionContent(plugins: [PluginInformation]) -> some View {
        ForEach(plugins, id: \.slug) { plugin in
            HStack(alignment: .top) {
                PluginIconView(plugin: plugin, service: viewModel.service)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name.makePlainText())
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // TODO: use `shortDescription` instead.
                    Text(plugin.author.makePlainText())
                        .lineLimit(2)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func rowContent(_ row: ListRow) -> some View {
        if case .loading = row {
            Label {
                Text("Loading plugins...")
            } icon: { ProgressView() }
            .font(.callout)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
        } else if case .error = row {
            Text("Failed to load plugins. Tap here to retry")
        } else if case let .plugin(plugin) = row {
            HStack(alignment: .top) {
                PluginIconView(plugin: plugin, service: viewModel.service)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name.makePlainText())
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // TODO: use `shortDescription` instead.
                    Text(plugin.author.makePlainText())
                        .lineLimit(2)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
        } else if case .empty = row {
            Text("No plugins found")
        } else {
            Text("Impossible to reach here")
        }
    }
}

private enum ListSection: Identifiable, Hashable {
    case plugins(category: AddNewPluginViewModel.Category, rows: [ListRow])
    case searchResult(rows: [ListRow])

    var id: AnyHashable {
        switch self {
        case let .plugins(category, _):
            return category
        case .searchResult:
            return "search-result"
        }
    }

    var rows: [ListRow] {
        switch self {
        case let .plugins(_, rows):
            return rows
        case let .searchResult(rows):
            return rows
        }
    }

    var header: String {
        switch self {
        case let .plugins(category, _):
            switch category {
            case .featured:
                return "Featured"
            case .popular:
                return "Popular"
            case .recommended:
                return "Recommended"
            }
        case .searchResult:
            return "Search Results"
        }
    }
}

private enum ListRow: Identifiable, Hashable {
    case loading
    case plugin(PluginInformation)
    case empty
    case error(String)

    var id: AnyHashable {
        switch self {
        case .loading:
            return "loading"
        case .plugin(let plugin):
            return plugin.slug
        case .empty:
            return "empty"
        case .error(let error):
            return error
        }
    }
}

@MainActor
private class AddNewPluginViewModel: ObservableObject {
    enum Mode: Hashable {
        case browser
        case searchResult(input: String)
    }

    enum Category: Hashable, CaseIterable {
        case featured
        case popular
        case recommended

        var wpOrgCategory: WordPressOrgApiPluginDirectoryCategory {
            // TODO: Update the returned values to be the correct onces after updating the wordpress-rs library
            switch self {
            case .featured:
                return .topRated
            case .popular:
                return .popular
            case .recommended:
                return .topRated
            }
        }
    }

    let service: PluginServiceProtocol
    private var initialLoad = false
    private(set) var mode: Mode = .browser

    @Published var loadingStates: [Category: Result<Void, Error>] = [:]

    @Published var searchInput: String = "" {
        didSet {
            let input = searchInput.trim()
            self.mode = input.isEmpty ? Mode.browser : .searchResult(input: input)
        }
    }

    @Published private(set) var listSections: [ListSection] = []

    init(service: PluginServiceProtocol) {
        self.service = service
    }

    func onAppear() async {
        guard !initialLoad else { return }
        initialLoad = true

        await withTaskGroup(of: Void.self) { [service] group in
            for category in Category.allCases {
                self.loadingStates[category] = nil
                group.addTask {
                    do {
                        try await service.fetchPluginsDirectory(category: category.wpOrgCategory)
                        await MainActor.run {
                            self.loadingStates[category] = .success(())
                        }
                    } catch {
                        await MainActor.run {
                            self.loadingStates[category] = .failure(error)
                        }
                    }
                }
            }
        }
    }

    func performQuery() async {
        await performQuery(in: mode)
    }

    func performQuery(in mode: Mode) async {
        switch mode {
        case .browser:
            await presentBrowserMode()
        case let .searchResult(input):
            await presentSearchResult(forInput: input)
        }
    }

    func presentBrowserMode() async {
        let categories = Category.allCases.map { $0.wpOrgCategory }
        for await result in await service.pluginDirectoryUpdates(query: .category(Set(categories))) {
            let sections: [ListSection]
            switch result {
            case let .success(all):
                sections = Category.allCases.map { category in
                    section(for: category, plugins: all.first { $0.category == category.wpOrgCategory })
                }
            case .failure:
                // TODO: Never throw atm, but we should handle it anyways.
                sections = []
                break
            }
            update(to: sections, ifStillIn: .browser)
        }
    }

    func presentSearchResult(forInput input: String) async {
        let expectedMode = Mode.searchResult(input: input)
        do {
            update(to: [.searchResult(rows: [.loading])], ifStillIn: expectedMode)

            let plugins = try await service.searchPluginsDirectory(input: input)

            let sections: [ListSection]
            if plugins.isEmpty {
                sections = [.searchResult(rows: [.empty])]
            } else {
                sections = [.searchResult(rows: plugins.map { .plugin($0) })]
            }
            update(to: sections, ifStillIn: expectedMode)
        } catch {
            update(to: [.searchResult(rows: [.error(error.localizedDescription)])], ifStillIn: expectedMode)
        }
    }

    func update(to sections: [ListSection], ifStillIn mode: Mode) {
        if mode == self.mode {
            self.listSections = sections
        }
    }

    func section(for category: Category, plugins: CategorizedPluginInformation?) -> ListSection {
        if self.loadingStates[category] == nil {
            return .plugins(category: category, rows: [.loading])
        } else if case let .failure(error)? = self.loadingStates[category] {
            return .plugins(category: category, rows: [.error(error.localizedDescription)])
        }

        guard let plugins else { return .plugins(category: category, rows: [.loading]) }

        if plugins.plugins.isEmpty {
            return .plugins(category: category, rows: [.empty])
        } else {
            return .plugins(category: category, rows: plugins.plugins.map { .plugin($0) })
        }
    }
}
