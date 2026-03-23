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

    @SiteStorage private var authorFilter: CustomPostAuthorFilter

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

        _allViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(tab: .all),
            blog: blog,
            showsHierarchyIfApplicable: true,
            presentingViewController: presentingViewController
        ))
        _publishedViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(tab: .published),
            blog: blog,
            showsHierarchyIfApplicable: true,
            presentingViewController: presentingViewController
        ))
        _draftsViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(tab: .drafts),
            blog: blog,
            presentingViewController: presentingViewController
        ))
        _scheduledViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(tab: .scheduled),
            blog: blog,
            presentingViewController: presentingViewController
        ))
        _trashViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(tab: .trash),
            blog: blog,
            presentingViewController: presentingViewController
        ))

        _authorFilter = .authorFilter(for: TaggedManagedObjectID(blog))
        self.applyAuthorFilter()
    }

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                CustomPostListView(
                    viewModel: activeViewModel,
                    details: details,
                    client: client,
                    mediaHost: MediaHost(blog),
                    onSelectPost: { editorPresentation = .editPost($0) },
                    onDuplicate: { duplicatePost($0) },
                    header: { tabBar }
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
                    onDuplicate: { duplicatePost($0) }
                )
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(details.name)
        .toolbar {
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
                initialParams: presentation.initialParams
            )
        }
        .onChange(of: authorFilter, applyAuthorFilter)
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
            FAB {
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
              let urlString = author.avatarURL else {
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
        var params = PostCreateParams.defaultParams(from: blog)
        params.title = post.title?.raw
        params.content = post.content.raw
        if capabilities.supportsCategories, let categories = post.categories {
            params.categories = categories
        }
        if capabilities.supportsPostFormats {
            params.format = post.format
        }
        editorPresentation = .duplicatePost(params)

        WPAnalytics.track(.postListDuplicateAction, withProperties: ["post_type": details.slug])
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
    case duplicatePost(PostCreateParams)

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

    var initialParams: PostCreateParams? {
        switch self {
        case .duplicatePost(let params): return params
        default: return nil
        }
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
    static let sendFeedback = NSLocalizedString(
        "customPostTab.sendFeedback",
        value: "Send Feedback",
        comment: "Menu item title for sending feedback on the custom post types screen"
    )
}
