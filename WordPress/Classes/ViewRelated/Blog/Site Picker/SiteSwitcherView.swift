import SwiftUI
import DesignSystem

struct SiteSwitcherView: View {
    @State private var isEditing: Bool = false
    private let selectionCallback: ((String) -> Void)
    private let addSiteCallback: (() -> Void)

    init(selectionCallback: @escaping ((String) -> Void),
        addSiteCallback: @escaping (() -> Void)) {
        self.selectionCallback = selectionCallback
        self.addSiteCallback = addSiteCallback
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack {
                    blogListView
                    addSiteButtonVStack
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private var blogListView: some View {
        BlogListView(
            sites: SiteSwitcherReducer.allBlogs().compactMap {
                .init(title: $0.title!, domain: $0.url!, imageURL: $0.hasIcon ? URL(string: $0.icon!) : nil)
            },
            isEditing: $isEditing,
            selectionCallback: selectionCallback
        )
        .toolbar {
            editButton
        }
        .navigationTitle("Switch Site")
        .navigationBarTitleDisplayMode(.inline)
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

    private var addSiteButtonVStack: some View {
        VStack(spacing: Length.Padding.medium) {
            Divider()
                .background(Color.DS.Foreground.secondary)
            DSButton(title: "Add a site", style: .init(emphasis: .primary, size: .large)) {
                addSiteCallback()
            }
            .padding(.horizontal, Length.Padding.medium)
        }
        .background(Color.DS.Background.primary)
    }
}
