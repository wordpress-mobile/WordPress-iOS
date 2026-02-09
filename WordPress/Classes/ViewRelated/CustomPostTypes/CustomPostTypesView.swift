import Foundation
import SwiftUI
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressUI

struct CustomPostTypesView: View {
    static var title: String {
        Strings.title
    }

    let client: WordPressClient
    let blog: Blog

    // The following state should only be initiated once.
    @State private var service: WpSelfHostedService?
    @State private var collection: PostTypeCollectionWithEditContext?

    @State private var types: [(PostEndpointType, PostTypeDetailsWithEditContext)] = []
    @State private var isLoading: Bool = true
    @State private var error: Error?
    @State private var isEditing = false

    @SiteStorage private var pinnedTypes: [PinnedPostType]

    init(client: WordPressClient, blog: Blog) {
        self.client = client
        self.blog = blog
        _pinnedTypes = .pinnedPostTypes(for: blog)
    }

    var body: some View {
        List {
            ForEach(types, id: \.1.slug) { (type, details) in
                if isEditing {
                    editingRow(for: details)
                } else {
                    navigationRow(for: type, details: details)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(Strings.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? SharedStrings.Button.done : SharedStrings.Button.edit)
                }
                .disabled(types.isEmpty)
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let error {
                EmptyStateView.failure(error: error)
            } else if types.isEmpty {
                EmptyStateView(Strings.emptyState, systemImage: "doc.text")
            }
        }
        .task {
            await setUp()
        }
        .task(id: collection.flatMap(ObjectIdentifier.init)) {
            guard let collection else { return }

            await refresh()

            isLoading = self.types.isEmpty
            defer { isLoading = false }

            do {
                _ = try await collection.fetch()
                await refresh()
            } catch {
                DDLogError("Failed to query stored post types: \(error)")
                if types.isEmpty {
                    self.error = error
                } else {
                    Notice(error: error).post()
                }
            }
        }
    }

    private func editingRow(for details: PostTypeDetailsWithEditContext) -> some View {
        let isPinned = pinnedTypes.contains { $0.slug == details.slug }
        return HStack {
            Image(dashicon: details.icon)
                .frame(width: 36)
            Text(details.name)
            Spacer()
            Button {
                togglePin(for: details)
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
            }
            .foregroundStyle(isPinned ? Color.accentColor : .secondary)
            .accessibilityLabel(isPinned ? Strings.unpinButton : Strings.pinButton)
        }
    }

    private func navigationRow(for type: PostEndpointType, details: PostTypeDetailsWithEditContext) -> some View {
        let isPinned = pinnedTypes.contains { $0.slug == details.slug }
        return NavigationLink {
            if let service {
                CustomPostTabView(client: client, service: service, endpoint: type, details: details, blog: blog)
            }
        } label: {
            HStack {
                Image(dashicon: details.icon)
                    .frame(width: 36)
                Text(details.name)
                if isPinned {
                    Spacer()
                    Image(systemName: "pin.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func togglePin(for details: PostTypeDetailsWithEditContext) {
        if let index = pinnedTypes.firstIndex(where: { $0.slug == details.slug }) {
            pinnedTypes.remove(at: index)
        } else {
            pinnedTypes.append(PinnedPostType(slug: details.slug, name: details.name, icon: details.icon))
        }
    }

    private func setUp() async {
        if service == nil {
            do {
                service = try await client.service
            } catch {
                self.isLoading = false
                self.error = error
            }
        }

        if let service, collection == nil {
            collection = service.postTypes().createPostTypeCollectionWithEditContext()
        }
    }

    private func refresh() async {
        guard let collection else { return }

        do {
            self.types = try await collection.loadData()
                .compactMap {
                    let details = $0.data
                    let endpoint = details.toPostEndpointType()
                    if case .custom = endpoint, details.slug != "attachment" {
                        return (endpoint, details)
                    }
                    return nil
                }
                .sorted {
                    $0.1.slug < $1.1.slug
                }
        } catch {
            DDLogError("Failed to fetch post types: \(error)")
            self.error = error
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "customPostTypes.title",
        value: "More Content",
        comment: "Title for the Custom Post Types screen"
    )

    static let emptyState = NSLocalizedString(
        "customPostTypes.emptyState.message",
        value: "No Custom Post Types",
        comment: "Empty state message when there are no custom post types to display"
    )

    static let pinButton = NSLocalizedString(
        "customPostTypes.pin.accessibilityLabel",
        value: "Pin",
        comment: "Accessibility label for the button to pin a custom post type"
    )

    static let unpinButton = NSLocalizedString(
        "customPostTypes.unpin.accessibilityLabel",
        value: "Unpin",
        comment: "Accessibility label for the button to unpin a custom post type"
    )
}
