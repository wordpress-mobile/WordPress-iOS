import UIKit
import SwiftUI

/// The sidebar dispalyed on the iPad.
final class SidebarViewController: UIHostingController<SidebarView> {
    init() {
        super.init(rootView: SidebarView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SidebarView: View {
    var body: some View {
        List {
            Section {
                Text("Siderbar")
            }
        }
        .listStyle(.sidebar)
    }
}
