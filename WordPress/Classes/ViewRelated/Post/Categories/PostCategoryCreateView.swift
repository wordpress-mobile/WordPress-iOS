import SwiftUI

struct PostCategoryCreateView: View {
    let blog: Blog
    let onCategoryCreated: (PostCategory) -> Void

    @State private var title = ""
    @State private var parent: PostCategory?
    @State private var isSaving = false

    @State private var isShowingError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            form
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(SharedStrings.Button.save, action: buttonSaveTapped)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .alert(errorMessage, isPresented: $isShowingError, actions: {
            Button(SharedStrings.Button.ok) {}
        })
        .disabled(isSaving)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var form: some View {
        Section {
            TextField(Strings.titlePlaceholder, text: $title)
        }
        Section {
            NavigationLink {
                PostCategoryPickerHostingView(blog: blog, selection: parent) {
                    self.parent = $0
                }
            } label: {
                HStack {
                    Text(Strings.parentCategory)
                    Spacer()
                    if let parent {
                        Text(parent.categoryName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func buttonSaveTapped() {
        let context = ContextManager.shared
        let service = PostCategoryService(coreDataStack: context)
        let categoryName = title.trimmingCharacters(in: .whitespaces)

        if let category = try? PostCategory.lookup(withBlogID: blog.objectID, parentCategoryID: parent?.categoryID, categoryName: categoryName, in: context.mainContext) {
            didCreate(category)
            return
        }

        isSaving = true
        service.createCategory(withName: categoryName, parentCategoryObjectID: parent?.objectID, forBlogObjectID: blog.objectID) { category in
            didCreate(category)
        } failure: { error in
            errorMessage = error.localizedDescription
            isShowingError = true
            isSaving = false
        }
    }

    private func didCreate(_ category: PostCategory) {
        dismiss()
        onCategoryCreated(category)
    }
}

struct PostCategoryPickerHostingView: UIViewControllerRepresentable {
    let blog: Blog
    var selection: PostCategory?
    var onSelectionChanged: (PostCategory?) -> Void

    func makeUIViewController(context: Context) -> PostCategoriesViewController {
        let viewController = PostCategoriesViewController(blog: blog, currentSelection: selection.map { [$0] }, selectionMode: .parent)
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ viewController: PostCategoriesViewController, context: Context) {
        // Do nothing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionChanged: onSelectionChanged)
    }

    final class Coordinator: NSObject, PostCategoriesViewControllerDelegate {
        var onSelectionChanged: (PostCategory?) -> Void

        init(onSelectionChanged: @escaping (PostCategory?) -> Void) {
            self.onSelectionChanged = onSelectionChanged
        }

        func postCategoriesViewController(_ controller: PostCategoriesViewController, didSelectCategory category: PostCategory) {
            onSelectionChanged(category)
        }

        func postCategoriesViewController(_ controller: PostCategoriesViewController, didUpdateSelectedCategories categories: NSSet) {
            if categories.count == 0 {
                onSelectionChanged(nil)
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("addCategory.navigationTitle", value: "Add Category", comment: "Screen title")
    static let parentCategory = NSLocalizedString("addCategory.parentCategory", value: "Parent Category", comment: "Cell title")
    static let titlePlaceholder = NSLocalizedString("addCategory.titlePlaceholder", value: "Title", comment: "Cell placeholder")
}
