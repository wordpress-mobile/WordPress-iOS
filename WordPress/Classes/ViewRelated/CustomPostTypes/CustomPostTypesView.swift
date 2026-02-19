import Foundation
import SwiftUI
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal
import WordPressShared
import WordPressUI

struct CustomPostTypesView: View {
    static var title: String {
        Strings.title
    }

    let blog: Blog
    let service: CustomPostTypeService

    @State private var types: [PostTypeDetailsWithEditContext] = []
    @State private var isLoading: Bool = true
    @State private var error: Error?
    @State private var isEditing = false

    @SiteStorage private var pinnedTypes: [PinnedPostType]

    init(blog: Blog, service: CustomPostTypeService) {
        self.blog = blog
        self.service = service
        _pinnedTypes = .pinnedPostTypes(for: service.blog)
    }

    var body: some View {
        List {
            ForEach(types, id: \.slug) { details in
                if isEditing {
                    editingRow(for: details)
                } else {
                    navigationRow(for: details)
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
            do {
                types = try await service.customTypes()
            } catch {
                DDLogError("Failed to load cached post types: \(error)")
            }

            isLoading = types.isEmpty
            defer { isLoading = false }

            do {
                try await service.refresh()
                types = try await service.customTypes()
            } catch {
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

    private func navigationRow(for details: PostTypeDetailsWithEditContext) -> some View {
        let isPinned = pinnedTypes.contains { $0.slug == details.slug }
        return NavigationLink {
            if let wpService = service.wpService {
                CustomPostTabView(client: service.client, service: wpService, endpoint: details.toPostEndpointType(), details: details, blog: blog)
            } else {
                let _ = wpAssertionFailure("Expected wpService to be available")
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
}

private enum Strings {
    static let title = NSLocalizedString(
        "customPostTypes.title",
        value: "More",
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
