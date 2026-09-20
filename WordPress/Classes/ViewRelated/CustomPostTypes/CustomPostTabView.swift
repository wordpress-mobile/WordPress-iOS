import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressUI
import WordPressData
import DesignSystem

struct CustomPostTabView: View {
    let client: WordPressClient
    let service: WpService
    let details: PostTypeDetailsWithEditContext
    let blog: Blog
    weak var presentingViewController: UIViewController?

    @State private var selectedTab: CustomPostTab = .all
    @State private var searchText = ""
    @State private var allViewModel: CustomPostListViewModel
    @State private var publishedViewModel: CustomPostListViewModel
    @State private var draftsViewModel: CustomPostListViewModel
    @State private var scheduledViewModel: CustomPostListViewModel
    @State private var trashViewModel: CustomPostListViewModel
    @State private var editorPresentation: EditorPresentation?
    @State private var isShowingFeedback = false
    @State private var mediaCache: FeaturedMediaURLCache
    @State private var metricsStore: CustomPostMetricsStore?

    @SiteStorage private var authorFilter: CustomPostAuthorFilter
    @State private var density = CustomPostListDensity.stored

    /// The redesign is gated to posts: pages keep their hierarchy, which the
    /// cards do not draw. Decided once, because the sort order the view models
    /// are built with has to match the grouping the cards draw.
    private let isRedesignEnabled: Bool

    private var activeViewModel: CustomPostListViewModel {
        switch selectedTab {
        case .all:
            allViewModel
        case .published:
            publishedViewModel
        case .drafts:
            draftsViewModel
        case .scheduled:
            scheduledViewModel
        case .trash:
            trashViewModel
        }
    }

    init(
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        blog: Blog,
        presentingViewController: UIViewController? = nil
    ) {
        self.client = client
        self.service = service
        self.details = details
        self.blog = blog
        self.presentingViewController = presentingViewController

        isRedesignEnabled = FeatureFlag.postsListRedesign.enabled && details.slug == "post"
        // The cards group rows by publish date, so the list has to sort on it
        // too or the headers would run backwards on the tabs sorted by
        // modified date. Matches Android, which sorts every tab by date.
        let orderby: WpApiParamPostsOrderBy? = isRedesignEnabled ? .date : nil

        _allViewModel = State(
            initialValue: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: CustomPostListFilter(tab: .all, orderby: orderby),
                blog: blog,
                showsHierarchyIfApplicable: true,
                presentingViewController: presentingViewController
            )
        )
        _publishedViewModel = State(
            initialValue: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: CustomPostListFilter(tab: .published, orderby: orderby),
                blog: blog,
                showsHierarchyIfApplicable: true,
                presentingViewController: presentingViewController
            )
        )
        _draftsViewModel = State(
            initialValue: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: CustomPostListFilter(tab: .drafts, orderby: orderby),
                blog: blog,
                presentingViewController: presentingViewController
            )
        )
        _scheduledViewModel = State(
            initialValue: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: CustomPostListFilter(tab: .scheduled, orderby: orderby),
                blog: blog,
                presentingViewController: presentingViewController
            )
        )
        _trashViewModel = State(
            initialValue: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: CustomPostListFilter(tab: .trash, orderby: orderby),
                blog: blog,
                presentingViewController: presentingViewController
            )
        )

        _authorFilter = .authorFilter(for: TaggedManagedObjectID(blog))
        _mediaCache = State(initialValue: FeaturedMediaURLCache(client: client))
        if isRedesignEnabled {
            let store = CustomPostMetricsStore(
                commentFetcher: CustomPostCommentCountFetcher(client: client),
                viewFetcher: StatsViewCountFetcher(blog: blog)
            )
            store.isEnabled = !CustomPostListDensity.stored.isCondensed
            _metricsStore = State(initialValue: store)
        }
        self.applyAuthorFilter()
    }

    private func cardConfiguration(for tab: CustomPostTab?) -> CustomPostCardConfiguration? {
        guard isRedesignEnabled else { return nil }
        return CustomPostCardConfiguration(
            density: density,
            // Date buckets are computed against "now", so a list of future-dated
            // posts would land under "This week" wholesale. Search mixes statuses.
            showsDateGroups: tab != nil && tab != .scheduled,
            mediaCache: mediaCache,
            // Drafts have neither a view history nor comments.
            metricsStore: tab == .published ? metricsStore : nil
        )
    }

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                CustomPostListView(
                    viewModel: activeViewModel,
                    details: details,
                    client: client,
                    mediaHost: MediaHost(blog),
                    cardConfiguration: cardConfiguration(for: selectedTab),
                    onSelectPost: { editorPresentation = .editPost($0) },
                    onDuplicate: { duplicatePost($0) },
                    header: { listHeader }
                )
            } else {
                CustomPostSearchResultView(
                    blog: blog,
                    client: client,
                    service: service,
                    details: details,
                    searchText: $searchText,
                    presentingViewController: presentingViewController,
                    onSelectPost: { editorPresentation = .editPost($0) },
                    onDuplicate: { duplicatePost($0) },
                    cardConfiguration: cardConfiguration(for: nil)
                )
            }
        }
        .searchable(text: $searchText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(details.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(Strings.betaBadge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColor.primary)
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .toolbar {
            if isRedesignEnabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // The rows resize and lose or gain their excerpt and hero image; animating
                        // the change lets the list settle rather than snap.
                        withAnimation(.easeInOut(duration: 0.3)) {
                            density = density.toggled
                        }
                    } label: {
                        Image(systemName: density.toggleSystemImage)
                    }
                    .accessibilityLabel(density.toggleAccessibilityLabel)
                }
            }
            if canFilterByAuthor {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthorFilterToolbarButton(
                        filter: $authorFilter,
                        avatarURL: currentUserAvatarURL
                    )
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { isShowingFeedback = true }) {
                        Label(Strings.sendFeedback, systemImage: "envelope")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isShowingFeedback) {
            SubmitFeedbackViewRepresentable()
        }
        .fullScreenCover(item: $editorPresentation) { presentation in
            CustomPostEditor(
                wpService: service,
                client: client,
                post: presentation.post,
                details: details,
                blog: blog,
                initialSettings: presentation.initialSettings,
                initialContent: presentation.initialContent
            )
        }
        .onChange(of: authorFilter, applyAuthorFilter)
        .onChange(of: density) {
            density.store()
            // Condensed rows show no metrics, so none are fetched; switching
            // back has to ask for the rows already on screen.
            metricsStore?.isEnabled = !density.isCondensed
        }
        .task {
            EditorDependencyManager.shared
                .prefetchDependencies(
                    for: blog,
                    postType: .init(
                        postType: details.slug,
                        restBase: details.restBase,
                        restNamespace: details.restNamespace
                    )
                )
        }
        .overlay(alignment: .bottomTrailing) {
            FAB(title: isRedesignEnabled ? Strings.write : nil) {
                editorPresentation = .newPost
            }
            .padding()
        }
    }

    private var canFilterByAuthor: Bool {
        blog.isMultiAuthor && blog.userID != nil
    }

    private var currentUserAvatarURL: URL? {
        guard let userID = blog.userID,
            let author = blog.getAuthorWith(id: userID),
            let urlString = author.avatarURL
        else {
            return nil
        }
        return URL(string: urlString)
    }

    private func authorIds(for filter: CustomPostAuthorFilter) -> [UserId] {
        switch filter {
        case .everyone:
            return []
        case .mine:
            guard let userID = blog.userID else { return [] }
            return [userID.int64Value]
        }
    }

    private func applyAuthorFilter() {
        let authorIds = authorIds(for: authorFilter)
        allViewModel.updateAuthorFilter(authorIds)
        publishedViewModel.updateAuthorFilter(authorIds)
        draftsViewModel.updateAuthorFilter(authorIds)
        scheduledViewModel.updateAuthorFilter(authorIds)
        trashViewModel.updateAuthorFilter(authorIds)
    }

    private func duplicatePost(_ post: AnyPostWithEditContext) {
        let capabilities = PostSettingsCapabilities(from: details)
        var settings = PostSettings.defaults(from: blog)
        if capabilities.supportsCategories, let categories = post.categories {
            settings.categoryIDs = Set(categories.map { Int($0) })
        }
        if capabilities.supportsPostFormats {
            // Assign unconditionally — when the source post has no format,
            // clear the blog default so the duplicate matches the source's
            // "no format" state rather than snapshotting today's blog default.
            settings.postFormat = post.format?.id
        }
        settings.allowComments = post.commentStatus.map { $0 == .open }
        settings.allowPings = post.pingStatus.map { $0 == .open }
        let content = EditorContent(
            title: post.title?.raw ?? "",
            content: post.content.raw ?? ""
        )
        editorPresentation = .duplicatePost(settings: settings, content: content)

        WPAnalytics.track(.postListDuplicateAction, withProperties: ["post_type": details.slug])
    }

    @ViewBuilder
    private var listHeader: some View {
        if isRedesignEnabled {
            // Chips replace the tab bar's appearance, not its tabs.
            CustomPostFilterChips(items: CustomPostTab.allCases, selection: $selectedTab)
        } else {
            tabBar
        }
    }

    private var tabBar: some View {
        AdaptiveTabBarRepresentable(
            items: CustomPostTab.allCases,
            selectedTab: $selectedTab
        )
        .frame(height: AdaptiveTabBar.tabBarHeight)
    }
}

enum CustomPostTab: Int, CaseIterable, AdaptiveTabBarItem {
    case all = 0
    case published
    case drafts
    case scheduled
    case trash

    var id: Self { self }

    var localizedTitle: String {
        switch self {
        case .all: return Strings.all
        case .published: return Strings.published
        case .drafts: return Strings.drafts
        case .scheduled: return Strings.scheduled
        case .trash: return Strings.trash
        }
    }

    var primaryStatus: PostStatus {
        switch self {
        case .all: return .publish
        case .published: return .publish
        case .drafts: return .draft
        case .scheduled: return .future
        case .trash: return .trash
        }
    }

    var statuses: [PostStatus] {
        switch self {
        case .all: return [.any]
        case .published: return [.publish, .private]
        case .drafts: return [.draft, .pending]
        case .scheduled: return [.future]
        case .trash: return [.trash]
        }
    }

    var orderby: WpApiParamPostsOrderBy {
        switch self {
        case .all, .drafts: return .modified
        case .published, .scheduled, .trash: return .date
        }
    }

    var order: WpApiParamOrder {
        switch self {
        case .scheduled: return .asc
        case .all, .published, .drafts, .trash: return .desc
        }
    }
}

private struct AdaptiveTabBarRepresentable: UIViewRepresentable {
    let items: [CustomPostTab]
    @Binding var selectedTab: CustomPostTab

    func makeUIView(context: Context) -> AdaptiveTabBar {
        let tabBar = AdaptiveTabBar()
        tabBar.preferredFont = UIFont.preferredFont(forTextStyle: .subheadline)
        tabBar.items = items
        tabBar.addTarget(context.coordinator, action: #selector(Coordinator.tabChanged(_:)), for: .valueChanged)
        return tabBar
    }

    func updateUIView(_ uiView: AdaptiveTabBar, context: Context) {
        if let index = items.firstIndex(of: selectedTab), uiView.selectedIndex != index {
            uiView.setSelectedIndex(index, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items, selectedTab: $selectedTab)
    }

    class Coordinator: NSObject {
        let items: [CustomPostTab]
        @Binding var selectedTab: CustomPostTab

        init(items: [CustomPostTab], selectedTab: Binding<CustomPostTab>) {
            self.items = items
            _selectedTab = selectedTab
        }

        @objc func tabChanged(_ tabBar: AdaptiveTabBar) {
            if items.indices.contains(tabBar.selectedIndex) {
                selectedTab = items[tabBar.selectedIndex]
            }
        }
    }
}

private struct SubmitFeedbackViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SubmitFeedbackViewController {
        SubmitFeedbackViewController(source: "custom_post_types", feedbackPrefix: "CustomPostTypes")
    }

    func updateUIViewController(_ uiViewController: SubmitFeedbackViewController, context: Context) {}
}

private enum EditorPresentation: Identifiable {
    case newPost
    case editPost(AnyPostWithEditContext)
    case duplicatePost(settings: PostSettings, content: EditorContent)

    var id: String {
        switch self {
        case .newPost: return "new"
        case .editPost(let post): return "post-\(post.id)"
        case .duplicatePost: return "duplicate"
        }
    }

    var post: AnyPostWithEditContext? {
        switch self {
        case .newPost, .duplicatePost: return nil
        case .editPost(let post): return post
        }
    }

    var initialSettings: PostSettings? {
        if case .duplicatePost(let settings, _) = self { return settings }
        return nil
    }

    var initialContent: EditorContent? {
        if case .duplicatePost(_, let content) = self { return content }
        return nil
    }
}

private enum Strings {
    static let all = NSLocalizedString(
        "customPostTab.all",
        value: "All",
        comment: "Tab title for showing all posts regardless of status"
    )
    static let published = NSLocalizedString(
        "customPostTab.published",
        value: "Published",
        comment: "Tab title for published posts"
    )
    static let drafts = NSLocalizedString(
        "customPostTab.drafts",
        value: "Drafts",
        comment: "Tab title for draft posts"
    )
    static let scheduled = NSLocalizedString(
        "customPostTab.scheduled",
        value: "Scheduled",
        comment: "Tab title for scheduled posts"
    )
    static let trash = NSLocalizedString(
        "customPostTab.trash",
        value: "Trash",
        comment: "Tab title for trashed posts"
    )
    static let write = NSLocalizedString(
        "customPostTab.write",
        value: "Write",
        comment: "Title of the floating button that starts a new post in the redesigned posts list"
    )
    static let sendFeedback = NSLocalizedString(
        "customPostTab.sendFeedback",
        value: "Send Feedback",
        comment: "Menu item title for sending feedback on the custom post types screen"
    )
    static let betaBadge = NSLocalizedString(
        "customPostType.navigation.betaBadge",
        value: "BETA",
        comment:
            "Badge label indicating that custom post type support is a beta feature. Displayed next to the navigation title."
    )
}
