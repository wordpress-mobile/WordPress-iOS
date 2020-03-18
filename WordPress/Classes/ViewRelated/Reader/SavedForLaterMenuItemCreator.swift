import Gridicons

/// Encapsulates creating of a ReaderMenuItem for Bookmarks / Saved for Later
final class SavedForLaterMenuItemCreator {
    func menuItem() -> ReaderMenuItem {
        let title = NSLocalizedString("Saved Posts", comment: "Title of the reader's Saved Posts menu item.")
        var item = ReaderMenuItem(title: title,
                                  type: .savedPosts)
        item.icon = .gridicon(.bookmark)
        item.order = ReaderDefaultMenuItemOrder.savedForLater.rawValue

        return item
    }
}
