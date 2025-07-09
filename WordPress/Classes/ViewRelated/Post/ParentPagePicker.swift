import SwiftUI
import CoreData
import WordPressData
import WordPressShared
import WordPressUI

@MainActor
struct ParentPagePicker: View {
    private let blog: Blog
    private let currentPage: Page
    private let onSelection: (Page?) -> Void

    @State private var isLoading = true
    @State private var pages: [Page]?
    @State private var error: Error?

    init(blog: Blog, currentPage: Page, onSelection: @escaping (Page?) -> Void) {
        self.blog = blog
        self.currentPage = currentPage
        self.onSelection = onSelection
    }

    var body: some View {
        Group {
            if let pages {
                ParentPageSettingsViewControllerWrapper(
                    pages: pages,
                    selectedPage: currentPage,
                    onSelection: onSelection
                )
                .ignoresSafeArea()
            } else {
                ProgressView()
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPages()
        }
    }

    private func loadPages() async {
        do {
            let request = NSFetchRequest<Page>(entityName: Page.entityName())
            let filter = PostListFilter.publishedFilter()
            request.predicate = filter.predicate(for: blog, author: .everyone)
            request.sortDescriptors = filter.sortDescriptors

            let context = ContextManager.shared.mainContext
            var pages = try await PostRepository().buildPageTree(request: request)
                .map { pageID, hierarchyIndex in
                    let page = try context.existingObject(with: pageID)
                    page.hierarchyIndex = hierarchyIndex
                    return page
                }

            // Remove the current page from the list (can't be its own parent)
            if let index = pages.firstIndex(of: currentPage) {
                pages = pages.remove(from: index)
            }

            self.pages = pages
        } catch {
            wpAssertionFailure("Failed to fetch pages", userInfo: ["error": "\(error)"]) // This should never happen
        }
    }
}

// MARK: - UIViewControllerRepresentable Wrapper

private struct ParentPageSettingsViewControllerWrapper: UIViewControllerRepresentable {
    let pages: [Page]
    let selectedPage: Page
    let onSelection: (Page?) -> Void

    func makeUIViewController(context: Context) -> ParentPageSettingsViewController {
        guard let viewController = ParentPageSettingsViewController.make(
            with: pages,
            selectedPage: selectedPage
        ) as? ParentPageSettingsViewController else {
            fatalError("Expected ParentPageSettingsViewController")
        }
        viewController.onSelectionChanged = { selectedParentPage in
            onSelection(selectedParentPage)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: ParentPageSettingsViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let title = NSLocalizedString(
        "parentPagePicker.title",
        value: "Parent Page",
        comment: "Title for the parent page picker screen"
    )
}
