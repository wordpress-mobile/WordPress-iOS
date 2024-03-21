import SwiftUI

struct SiteSwitcherView: View {
    @State private var isEditing: Bool = false
    @State private var pinnedDomains: Set<String>
    private let selectionCallback: ((String) -> Void)

    init(pinnedDomains: Set<String>, selectionCallback: @escaping ((String) -> Void)) {
        self.pinnedDomains = pinnedDomains
        self.selectionCallback = selectionCallback
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                BlogListView(
                    sites: SiteSwitcherReducer.allBlogs().compactMap {
                        .init(title: $0.title!, domain: $0.url!, imageURL: $0.hasIcon ? URL(string: $0.icon!) : nil)
                    },
                    pinnedDomains: $pinnedDomains,
                    isEditing: $isEditing,
                    selectionCallback: selectionCallback
                )
                .toolbar {
                    editButton
                }
                .navigationTitle("Switch Site")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private var editButton: some View {
        Button(action: {
            isEditing.toggle()
        }, label: {
            Text(isEditing ? "Done": "Edit")
                .style(.bodyLarge(.regular))
                .foregroundStyle(
                    Color.DS.Foreground.primary
                )
        })
    }
}
