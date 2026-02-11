import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressUI
import WordPressData

struct CustomPostTabView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    let blog: Blog

    @State private var selectedTab: CustomPostTab = .published
    @State private var searchText = ""
    @State private var publishedViewModel: CustomPostListViewModel
    @State private var draftsViewModel: CustomPostListViewModel
    @State private var scheduledViewModel: CustomPostListViewModel
    @State private var trashViewModel: CustomPostListViewModel
    @State private var selectedPost: AnyPostWithEditContext?
    @State private var isShowingFeedback = false

    private var activeViewModel: CustomPostListViewModel {
        switch selectedTab {
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
        service: WpSelfHostedService,
        endpoint: PostEndpointType,
        details: PostTypeDetailsWithEditContext,
        blog: Blog
    ) {
        self.client = client
        self.service = service
        self.endpoint = endpoint
        self.details = details
        self.blog = blog

        _publishedViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            endpoint: endpoint,
            filter: CustomPostListFilter(status: .publish)
        ))
        _draftsViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            endpoint: endpoint,
            filter: CustomPostListFilter(status: .draft)
        ))
        _scheduledViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            endpoint: endpoint,
            filter: CustomPostListFilter(status: .future)
        ))
        _trashViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            endpoint: endpoint,
            filter: CustomPostListFilter(status: .trash)
        ))
    }

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                CustomPostListView(
                    viewModel: activeViewModel,
                    details: details,
                    onSelectPost: { selectedPost = $0 },
                    header: { tabBar }
                )
            } else {
                CustomPostSearchResultView(
                    client: client,
                    service: service,
                    endpoint: endpoint,
                    details: details,
                    searchText: $searchText,
                    onSelectPost: { selectedPost = $0 }
                )
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(details.name)
        .toolbar {
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
        .fullScreenCover(item: $selectedPost) { post in
            CustomPostEditor(client: client, post: post, details: details, blog: blog)
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
    case published = 0
    case drafts
    case scheduled
    case trash

    var id: Self { self }

    var localizedTitle: String {
        switch self {
        case .published: return Strings.published
        case .drafts: return Strings.drafts
        case .scheduled: return Strings.scheduled
        case .trash: return Strings.trash
        }
    }

    var status: PostStatus {
        switch self {
        case .published: return .publish
        case .drafts: return .draft
        case .scheduled: return .future
        case .trash: return .trash
        }
    }
}

private struct AdaptiveTabBarRepresentable: UIViewRepresentable {
    let items: [CustomPostTab]
    @Binding var selectedTab: CustomPostTab

    func makeUIView(context: Context) -> AdaptiveTabBar {
        let tabBar = AdaptiveTabBar()
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

private enum Strings {
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
