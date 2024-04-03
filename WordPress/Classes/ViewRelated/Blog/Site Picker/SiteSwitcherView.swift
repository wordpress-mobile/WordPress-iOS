import SwiftUI
import DesignSystem

struct SiteSwitcherView: View {
    @State private var isEditing: Bool = false
    private let selectionCallback: ((String) -> Void)
    private let addSiteCallback: (() -> Void)
    @State private var searchText = ""
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    var sites: [BlogListView.Site] {
        if searchText.isEmpty {
            return SiteSwitcherReducer.allBlogs().compactMap {
                .init(title: $0.title!, domain: $0.url!, imageURL: $0.hasIcon ? URL(string: $0.icon!) : nil)
            }
        } else {
            return SiteSwitcherReducer.allBlogs()
                .filter {
                    $0.url!.lowercased().contains(searchText.lowercased()) || $0.title!.lowercased().contains(searchText.lowercased())
                }
                .compactMap {
                    .init(title: $0.title!, domain: $0.url!, imageURL: $0.hasIcon ? URL(string: $0.icon!) : nil)
                }
        }
    }

    init(selectionCallback: @escaping ((String) -> Void),
        addSiteCallback: @escaping (() -> Void)) {
        self.selectionCallback = selectionCallback
        self.addSiteCallback = addSiteCallback
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                VStack {
                    blogListView
                    if !isSearching {
                        addSiteButtonVStack
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(
                    displayMode: .always
                )
            )
        } else {
            NavigationView {
                VStack {
                    blogListView
                    if !isSearching {
                        addSiteButtonVStack
                    }
                }
            }
            .searchable(text: $searchText)
        }
    }

    private var blogListView: some View {
        BlogListView(
            sites: sites,
            currentDomain: SiteSwitcherReducer.selectedBlog()?.url,
            isEditing: $isEditing,
            isSearching: $isSearching,
            selectionCallback: selectionCallback
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                cancelButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                editButton
            }
        }
        .navigationTitle("Switch Site")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cancelButton: some View {
        Button(action: {
            dismiss()
        }, label: {
            Text("Cancel")
                .style(.bodyLarge(.regular))
                .foregroundStyle(
                    Color.DS.Foreground.primary
                )
        })
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
        VStack(spacing: .DS.Padding.medium) {
            Divider()
                .background(Color.DS.Foreground.secondary)
            DSButton(title: "Add a site", style: .init(emphasis: .primary, size: .large)) {
                addSiteCallback()
            }
            .padding(.horizontal, .DS.Padding.medium)
        }
        .background(Color.DS.Background.primary)
    }
}
