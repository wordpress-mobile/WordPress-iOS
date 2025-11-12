import UIKit
import WordPressData

/// A subclass of PostCategoriesViewController for use in PostSettings.
/// This is a temporary solution until PostCategoriesViewController can be replaced with SwiftUI.
final class PostSettingsCategoriesPickerViewController: PostCategoriesViewController {
    private let _onCategoriesChanged: (Set<Int>) -> Void

    init(blog: Blog, selectedCategoryIDs: Set<Int>, onCategoriesChanged: @escaping (Set<Int>) -> Void) {
        self._onCategoriesChanged = onCategoriesChanged

        // Get currently selected categories
        let selectedCategories = blog.categories?.filter { category in
            selectedCategoryIDs.contains(category.categoryID.intValue)
        } ?? []

        super.init(blog: blog, currentSelection: Array(selectedCategories), selectionMode: .post)

        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PostCategoriesViewControllerDelegate

extension PostSettingsCategoriesPickerViewController: PostCategoriesViewControllerDelegate {
    func postCategoriesViewController(_ controller: PostCategoriesViewController, didUpdateSelectedCategories categories: NSSet) {
        // Convert NSSet of PostCategory objects to Set<Int> of category IDs
        let newSelectedIDs = Set(categories.compactMap { category in
            (category as? PostCategory)?.categoryID.intValue
        })
        _onCategoriesChanged(newSelectedIDs)
    }
}
