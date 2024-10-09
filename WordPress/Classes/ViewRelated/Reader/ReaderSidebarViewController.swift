import UIKit
import SwiftUI
import Combine
import WordPressUI

final class ReaderSidebarViewController: UIHostingController<AnyView> {
    let viewModel: ReaderSidebarViewModel

    private var viewContext: NSManagedObjectContext { ContextManager.shared.mainContext }
    var didAppear = false

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
    @AppStorage("reader_sidebar_subscriptions_expanded") var isSectionSubscriptionsExpanded = true
    @AppStorage("reader_sidebar_lists_expanded") var isSectionListsExpanded = true
    @AppStorage("reader_sidebar_tags_expanded") var isSectionTagsExpanded = true

    @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)])
    private var teams: FetchedResults<ReaderTeamTopic>

    @State private var searchText = ""

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
            // On iPhone, .sidebar style is rendered differently, so it
            // requires a bit more work to get the look we want.
            if viewModel.isCompactStyleEnabled {
                content.listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            } else {
                content
            }
        }
        .listStyle(.sidebar)

        if viewModel.isCompactStyleEnabled {
            list
                .listRowBackground(Color(.systemBackground))
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Strings.searchPlaceholder)
        } else {
            list
        }
    }

    @ViewBuilder
    private var content: some View {
        Section {
            let screens = allStaticScreens
            ForEach(screens) {
                makePrimaryNavigationItem($0.localizedTitle, systemImage: $0.systemImage)
                    .tag(ReaderSidebarItem.main($0))
                    .lineLimit(1)
                    .listRowSeparator((viewModel.isCompactStyleEnabled && $0 != screens.last) ? .visible : .hidden, edges: .bottom)
                    .accessibilityIdentifier($0.accessibilityIdentifier)
            }
        }
        if !teams.isEmpty {
            makeSection(Strings.organization, isExpanded: $isSectionOrganizationExpanded) {
                ReaderSidebarOrganizationSection(viewModel: viewModel, teams: teams)
            }
        }
        makeSection(Strings.subscriptions, isExpanded: $isSectionSubscriptionsExpanded) {
            ReaderSidebarSubscriptionsSection(viewModel: viewModel)
        }
        makeSection(Strings.lists, isExpanded: $isSectionListsExpanded) {
            ReaderSidebarListsSection(viewModel: viewModel)
        }
        makeSection(Strings.tags, isExpanded: $isSectionTagsExpanded) {
            ReaderSidebarTagsSection(viewModel: viewModel)
        }
    }

    private var allStaticScreens: [ReaderStaticScreen] {
        var screens = ReaderStaticScreen.allCases
        if viewModel.isCompactStyleEnabled, let index = screens.firstIndex(of: .search) {
            screens.remove(at: index)
        }
        return screens
    }

    private func makePrimaryNavigationItem(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            if viewModel.isCompactStyleEnabled {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14).weight(.medium))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
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

    @ViewBuilder
    private func makeSection<Content: View>(_ title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 17, *) {
            Section(title, isExpanded: isExpanded) {
                content()
            }
        } else {
            Section(title) {
                content()
            }
        }
    }
}

private struct Strings {
    static let reader = NSLocalizedString("reader.sidebar.navigationTitle", value: "Reader", comment: "Reader sidebar title")
    static let subscriptions = NSLocalizedString("reader.sidebar.section.subscriptions.title", value: "Subscriptions", comment: "Reader sidebar section title")
    static let lists = NSLocalizedString("reader.sidebar.section.lists.title", value: "Lists", comment: "Reader sidebar section title")
    static let tags = NSLocalizedString("reader.sidebar.section.tags.title", value: "Tags", comment: "Reader sidebar section title")
    static let organization = NSLocalizedString("reader.sidebar.section.organization.title", value: "Organization", comment: "Reader sidebar section title")
    static let searchPlaceholder = NSLocalizedString("reader.sidebar.searchPlaceholder", value: "Blogs, Posts, and More", comment: "Reader sidebar search placeholder")
}
