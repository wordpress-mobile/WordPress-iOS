import Foundation
import WordPressKit

enum SidebarSelection: Hashable {
    case empty // No sites
    case blog(TaggedManagedObjectID<Blog>)
    case notifications
    case reader
}

enum SidebarNavigationStep {
    case domains
    case help
    case profile
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
    @Published var account: WPAccount?

    var navigate: (SidebarNavigationStep) -> Void = { _ in }

    init(contextManager: CoreDataStackSwift = ContextManager.shared) {
        let blog = Blog.lastUsedOrFirst(in: contextManager.mainContext)
        if let blog {
            selection = .blog(TaggedManagedObjectID(blog))
        } else {
            selection = .empty
        }

        // TODO: (wpsidebar) can it change during the root presenter lifetime?
        self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
    }
}
