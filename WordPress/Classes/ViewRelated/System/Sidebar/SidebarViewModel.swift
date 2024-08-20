import Foundation
import WordPressKit

enum SidebarSelection: Hashable {
    case empty // No sites
    case blog(TaggedManagedObjectID<Blog>)
    case notifications
    case reader
    case domains
    case help
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
    @Published var account: WPAccount?

    var showProfileDetails: () -> Void = {}

    init() {
        // TODO: (wpsidebar) can it change during the root presenter lifetime?
        self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }
}
