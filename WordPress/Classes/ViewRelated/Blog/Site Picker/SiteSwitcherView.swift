import SwiftUI

struct SiteSwitcherView: View {
    @State private var isEditing: Bool = false
    @State private var pinnedDomains: Set<String>

    init(pinnedDomains: Set<String>) {
        self.pinnedDomains = pinnedDomains
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                BlogListView(
                    sites: SiteSwitcherReducer.allBlogs().compactMap {
                        .init(title: $0.title!, domain: $0.url!, imageURL: $0.hasIcon ? URL(string: $0.icon!) : nil)
                    },
                    pinnedDomains: $pinnedDomains,
                    isEditing: $isEditing
                )
                .toolbar {
                    ellipsisButton
                }
                .navigationTitle("Switch Site")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private var ellipsisButton: some View {
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

#Preview {
    SiteSwitcherView(
        pinnedDomains: [
            "claychronicles.com",
            "historyunearthed.wordpress.com"
        ]
    )
}
