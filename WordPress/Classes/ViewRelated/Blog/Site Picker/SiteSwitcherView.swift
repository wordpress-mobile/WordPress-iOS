import SwiftUI
import DesignSystem

struct SiteSwitcherView: View {
    @State private var isEditing: Bool = false
    private let selectionCallback: ((NSNumber) -> Void)
    private let addSiteCallback: (() -> Void)
    private let eventTracker: EventTracker
    @State private var searchText = ""
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    init(selectionCallback: @escaping ((NSNumber) -> Void),
         addSiteCallback: @escaping (() -> Void),
         eventTracker: EventTracker = DefaultEventTracker()
    ) {
        self.selectionCallback = selectionCallback
        self.addSiteCallback = addSiteCallback
        self.eventTracker = eventTracker
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                blogListVStack
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always)
            )
        } else {
            NavigationView {
                blogListVStack
                    .navigationBarTitleDisplayMode(.inline)
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

    private var blogListVStack: some View {
        VStack(spacing: 0) {
            blogListView
            if !isSearching {
                addSiteButtonVStack
            }
        }
    }

    private var blogListView: some View {
        BlogListView(
            isEditing: $isEditing,
            isSearching: $isSearching,
            searchText: $searchText,
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
        .navigationTitle(Strings.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cancelButton: some View {
        Button(action: {
            dismiss()
        }, label: {
            Text(Strings.navigationDismissButtonTitle)
                .style(.bodyLarge(.regular))
                .foregroundStyle(
                    Color.DS.Foreground.primary
                )
        })
    }

    private var editButton: some View {
        Button(action: {
            isEditing.toggle()
            eventTracker.track(.siteSwitcherToggledPinTapped, properties: ["state": isEditing ? "edit" : "done"])
        }, label: {
            Text(isEditing ? Strings.navigationDoneButtonTitle: Strings.navigationEditButtonTitle)
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
            DSButton(title: Strings.addSiteButtonTitle, style: .init(emphasis: .primary, size: .large)) {
                addSiteCallback()
            }
            .accessibilityIdentifier("add-site-button")
            .padding(.horizontal, .DS.Padding.medium)
        }
        .background(Color.DS.Background.primary)
    }
}

private extension SiteSwitcherView {
    enum Strings {
        static let navigationTitle = NSLocalizedString(
            "site_switcher_title",
            value: "Choose a site",
            comment: "Title for site switcher screen."
        )

        static let navigationDismissButtonTitle = NSLocalizedString(
            "site_switcher_dismiss_button_title",
            value: "Cancel",
            comment: "Dismiss button title above the search."
        )

        static let navigationEditButtonTitle = NSLocalizedString(
            "site_switcher_edit_button_title",
            value: "Edit",
            comment: "Edit button title above the search."
        )

        static let navigationDoneButtonTitle = NSLocalizedString(
            "site_switcher_done_button_title",
            value: "Done",
            comment: "Done button title above the search."
        )

        static let addSiteButtonTitle = NSLocalizedString(
            "site_switcher_cta_title",
            value: "Add a site",
            comment: "CTA title for the site switcher screen."
        )
    }
}
