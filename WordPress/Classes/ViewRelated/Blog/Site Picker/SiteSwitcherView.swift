import SwiftUI
import DesignSystem

struct SiteSwitcherView: View {
    @State private var searchText = ""
    @State private var isSearching = false

    @Environment(\.dismiss) private var dismiss

    private let onSiteSelected: ((Blog) -> Void)
    private let addSiteAction: (() -> Void)
    private let eventTracker: EventTracker

    init(addSiteAction: @escaping (() -> Void),
         onSiteSelected: @escaping ((Blog) -> Void),
         eventTracker: EventTracker = DefaultEventTracker()
    ) {
        self.addSiteAction = addSiteAction
        self.onSiteSelected = onSiteSelected
        self.eventTracker = eventTracker
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                blogListView
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always)
            )
        } else {
            NavigationView {
                blogListView
                    .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always)
                    )
                    .onChange(of: searchText) { newValue in
                        isSearching = !newValue.isEmpty
                    }
            }
        }
    }

    private var blogListView: some View {
        BlogListView(
            isSearching: $isSearching,
            searchText: $searchText,
            onSiteSelected: onSiteSelected
        )
        .safeAreaInset(edge: .bottom) {
            if !isSearching {
                HStack {
                    Spacer()
                    FAB(action: addSiteAction)
                        .padding(.trailing, 20)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.close) {
                    dismiss()
                }.tint(Color.DS.Foreground.primary)
            }
        }
        .navigationTitle(Strings.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum Strings {
    static let navigationTitle = NSLocalizedString(
        "sitePicker.title",
        value: "My Sites",
        comment: "Title for site switcher screen"
    )
}
