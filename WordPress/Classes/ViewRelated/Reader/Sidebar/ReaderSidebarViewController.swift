import UIKit
import SwiftUI
import Combine
import WordPressUI

final class ReaderSidebarViewController: UIHostingController<AnyView> {
    let viewModel: ReaderSidebarViewModel

    private var viewContext: NSManagedObjectContext { ContextManager.shared.mainContext }
    var didAppear = false

    var onViewDidLoad: (() -> Void)?

    init(viewModel: ReaderSidebarViewModel) {
        self.viewModel = viewModel
        // - warning: The `managedObjectContext` has to be set here in order for
        // `ReaderSidebarView` to eb able to access it
        let view = ReaderSidebarView(viewModel: viewModel)
            .environment(\.managedObjectContext, ContextManager.shared.mainContext)
        super.init(rootView: AnyView(view))

        // TODO: (reader) fix on ipad
        title = Strings.reader
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        onViewDidLoad?()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.onAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didAppear = true
    }
}

private struct ReaderSidebarView: View {
    @ObservedObject var viewModel: ReaderSidebarViewModel

    @AppStorage("reader_sidebar_organization_expanded") var isSectionOrganizationExpanded = true
    @AppStorage("reader_sidebar_favorites_expanded") var isSectionFavoritesExpanded = true
    @AppStorage("reader_sidebar_subscriptions_expanded") var isSectionSubscriptionsExpanded = true
    @AppStorage("reader_sidebar_lists_expanded") var isSectionListsExpanded = true
    @AppStorage("reader_sidebar_tags_expanded") var isSectionTagsExpanded = true

    @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)])
    private var teams: FetchedResults<ReaderTeamTopic>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES AND showInMenu = YES")
    )
    private var favorites: FetchedResults<ReaderSiteTopic>

    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.editMode) var editMode

    var isEditing: Bool { editMode?.wrappedValue.isEditing == true }

    var body: some View {
        list
            .toolbar {
                EditButton()
            }
            .tint(preferredTintColor)
            .accessibilityIdentifier("reader_sidebar")
    }

    @ViewBuilder
    private var list: some View {
        let list = List(selection: $viewModel.selection) {
            if viewModel.isCompact {
                content.listRowSeparator(.hidden)
            } else {
                content
            }
        }
        if viewModel.isCompact {
            list.listStyle(.plain).onAppear {
                viewModel.selection = nil // Remove the higlight
            }
        } else {
            list.listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var content: some View {
        Section {
            let screens = ReaderStaticScreen.allCases
            ForEach(ReaderStaticScreen.allCases) {
                makePrimaryNavigationItem($0.localizedTitle, systemImage: $0.systemImage)
                    .tag(ReaderSidebarItem.main($0))
                    .listRowSeparator((viewModel.isCompact && $0 != screens.last) ? .visible : .hidden, edges: .bottom)
                    .accessibilityIdentifier($0.accessibilityIdentifier)
                    .withDisabledSelection(isEditing)
            }
        }
        if !favorites.isEmpty || isEditing {
            makeSection(Strings.favorites, isExpanded: $isSectionFavoritesExpanded) {
                ForEach(favorites, id: \.self) {
                    ReaderSidebarSubscriptionCell(site: $0)
                }
            }
        }
        if !teams.isEmpty {
            makeSection(Strings.organization, isExpanded: $isSectionOrganizationExpanded) {
                ReaderSidebarOrganizationSection(viewModel: viewModel, teams: teams)
            }
        }
        makeSection(Strings.subscriptions, isExpanded: $isSectionSubscriptionsExpanded) {
            Label(Strings.subscriptions, systemImage: "checkmark.rectangle.stack")
                .tag(ReaderSidebarItem.allSubscriptions)
                .listItemTint(AppColor.brand)
                .withDisabledSelection(isEditing)

            ReaderSidebarSubscriptionsSection(viewModel: viewModel)
                .environment(\.siteIconBackgroundColor, Color(viewModel.isCompact ? .secondarySystemBackground : .systemBackground))
        }
        makeSection(Strings.lists, isExpanded: $isSectionListsExpanded) {
            ReaderSidebarListsSection(viewModel: viewModel)
        }
        makeSection(Strings.tags, isExpanded: $isSectionTagsExpanded) {
            ReaderSidebarTagsSection(viewModel: viewModel)
        }
    }

    private func makePrimaryNavigationItem(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
            if viewModel.isCompact {
                Spacer()
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14).weight(.medium))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .accessibilityElement()
        .accessibilityLabel(title)
    }

    private var preferredTintColor: Color {
        if #available(iOS 18, *) {
            return AppColor.tint
        } else {
            // This is a workaround for an iOS issue where it will not apply the
            // correrect colors in dark mode when the sidebar is displayed in a
            // supplementary column. If use use black as a tint color, it
            // displays white text on white background
            return Color(UIColor(light: UIAppColor.tint, dark: .secondaryLabel))
        }
    }

    private func makeSection<Content: View>(_ title: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        ReaderSidebarSection(title: title, isExpanded: isExpanded, isCompact: viewModel.isCompact, content: content)
    }
}

private struct ReaderSidebarSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    var isCompact: Bool
    @ViewBuilder var content: () -> Content

    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        if isCompact {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : (layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right"))
                        .font(.system(size: 14).weight(.semibold))
                        .foregroundStyle(AppColor.brand)
                        .frame(width: 14)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 6, trailing: 16))

            if isExpanded {
                content()
            }
        } else if #available(iOS 17, *) {
            Section(title, isExpanded: $isExpanded) {
                content()
            }
        } else {
            Section(title) {
                content()
            }
        }
    }
}

private extension View {
    @ViewBuilder func withDisabledSelection(_ isDisabled: Bool) -> some View {
        if #available(iOS 17, *) {
            self.opacity(isDisabled ? 0.33 : 1)
                .selectionDisabled(isDisabled)
        } else {
            self
        }
    }
}

private struct Strings {
    static let reader = SharedStrings.Reader.title
    static let subscriptions = NSLocalizedString("reader.sidebar.section.subscriptions.title", value: "Subscriptions", comment: "Reader sidebar section title")
    static let favorites = NSLocalizedString("reader.sidebar.section.favorites.title", value: "Favorites", comment: "Reader sidebar section title")
    static let lists = NSLocalizedString("reader.sidebar.section.lists.title", value: "Lists", comment: "Reader sidebar section title")
    static let tags = NSLocalizedString("reader.sidebar.section.tags.title", value: "Tags", comment: "Reader sidebar section title")
    static let organization = NSLocalizedString("reader.sidebar.section.organization.title", value: "Organization", comment: "Reader sidebar section title")
}
