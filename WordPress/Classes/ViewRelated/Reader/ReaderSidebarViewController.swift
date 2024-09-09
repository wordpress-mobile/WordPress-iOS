import UIKit
import SwiftUI
import Combine
import WordPressUI

final class ReaderSidebarViewController: UIHostingController<ReaderSidebarView> {
    let viewModel: ReaderSidebarViewModel

    private var cancellables: [AnyCancellable] = []
    private var viewContext: NSManagedObjectContext { ContextManager.shared.mainContext }

    init(viewModel: ReaderSidebarViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReaderSidebarView(viewModel: viewModel))

        viewModel.navigate = { [weak self] in self?.navigate(to: $0) }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showInitialSelection() {
        cancellables = []

        viewModel.$selection.sink { [weak self] in
            self?.configure(for: $0)
        }.store(in: &cancellables)
    }

    private func configure(for selection: ReaderSidebarItem?) {
        guard let selection else {
            return
        }
        switch selection {
        case .main(let screen):
            showSecondary(makeViewController(for: screen))
        case .allSubscriptions:
            showSecondary(makeAllSubscriptionsViewController(), isLargeTitle: true)
        case .subscription(let objectID):
            do {
                let topic = try viewContext.existingObject(with: objectID)
                showSecondary(ReaderStreamViewController.controllerWithTopic(topic))
            } catch {
                wpAssertionFailure("site missing", userInfo: ["error": "\(error)"])
            }
        case .tag(let objectID):
            do {
                let topic = try viewContext.existingObject(with: objectID)
                showSecondary(ReaderStreamViewController.controllerWithTopic(topic))
            } catch {
                wpAssertionFailure("tag missing", userInfo: ["error": "\(error)"])
            }
        }
    }

    private func makeViewController(for screen: ReaderStaticScreen) -> UIViewController {
        switch screen {
        case .recent, .discover, .likes:
            if let topic = screen.topicType.flatMap(viewModel.getTopic) {
                if screen == .discover {
                    return ReaderCardsStreamViewController.controller(topic: topic)
                } else {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                }
            } else {
                return makeErrorViewController() // This should never happen
            }
        case .saved:
            return ReaderStreamViewController.controllerForContentType(.saved)
        case .search:
            return ReaderSearchViewController.controller(withSearchText: "")
        }
    }

    private func makeAllSubscriptionsViewController() -> UIViewController {
        let view = ReaderSubscriptionsView() { [weak self] selection in
            guard let self else { return }
            let navigationVC = self.splitViewController?.viewController(for: .secondary) as? UINavigationController
            wpAssert(navigationVC != nil)
            let streamVC = ReaderStreamViewController.controllerWithTopic(selection)
            navigationVC?.pushViewController(streamVC, animated: true)
        }.environment(\.managedObjectContext, viewContext)
        return UIHostingController(rootView: view)
    }

    private func navigate(to item: ReaderSidebarNavigation) {
        switch item {
        case .discoverTags:
            let tags = viewContext.allObjects(
                ofType: ReaderTagTopic.self,
                matching: ReaderSidebarTagsSection.predicate,
                sortedBy: [NSSortDescriptor(SortDescriptor<ReaderTagTopic>(\.title, order: .forward))]
            )
            let interestsVC = ReaderSelectInterestsViewController(topics: tags)
            interestsVC.didSaveInterests = { [weak self] _ in
                self?.dismiss(animated: true)
            }
            let navigationVC = UINavigationController(rootViewController: interestsVC)
            navigationVC.modalPresentationStyle = .formSheet
            present(navigationVC, animated: true, completion: nil)
        }
    }

    private func makeErrorViewController() -> UIViewController {
        UIHostingController(rootView: EmptyStateView(SharedStrings.Error.generic, systemImage: "exclamationmark.circle"))
    }

    private func showSecondary(_ viewController: UIViewController, isLargeTitle: Bool = false) {
        let navigationVC = UINavigationController(rootViewController: viewController)
        if isLargeTitle {
            navigationVC.navigationBar.prefersLargeTitles = true
        }
        splitViewController?.setViewController(navigationVC, for: .secondary)
    }
}

struct ReaderSidebarView: View {
    @ObservedObject var viewModel: ReaderSidebarViewModel

    @AppStorage("reader_sidebar_subscriptions_expanded") var isSectionSubscriptionsExpanded = true
    @AppStorage("reader_sidebar_tags_expanded") var isSectionTagsExpanded = true

    var body: some View {
        List(selection: $viewModel.selection) {
            Section {
                ForEach(ReaderStaticScreen.allCases) {
                    Label($0.localizedTitle, systemImage: $0.systemImage)
                        .tag(ReaderSidebarItem.main($0))
                        .lineLimit(1)
                }
            }
            makeSection(Strings.subscriptions, isExpanded: $isSectionSubscriptionsExpanded) {
                ReaderSidebarSubscriptionsSection(viewModel: viewModel)
            }
            makeSection(Strings.tags, isExpanded: $isSectionTagsExpanded) {
                ReaderSidebarTagsSection(viewModel: viewModel)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(Strings.reader)
        .toolbar {
            EditButton()
        }
        .tint(Color(UIAppColor.brand))
        .environment(\.managedObjectContext, ContextManager.shared.mainContext)
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

private struct ReaderSidebarSubscriptionsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    var body: some View {
        Label(Strings.allSubscriptions, systemImage: "checkmark.rectangle.stack")
            .tag(ReaderSidebarItem.allSubscriptions)

        ForEach(subscriptions, id: \.self) { site in
            Label {
                Text(site.title)
            } icon: {
                SiteIconView(viewModel: SiteIconViewModel(readerSiteTopic: site, size: .small))
                    .frame(width: 28, height: 28)
            }
            .lineLimit(1)
            .tag(ReaderSidebarItem.subscription(TaggedManagedObjectID(site)))
            .swipeActions(edge: .trailing) {
                Button(SharedStrings.Reader.unfollow, role: .destructive) {
                    ReaderSubscriptionHelper().unfollow(site)
                }.tint(.red)
            }
        }
        .onDelete(perform: delete)
    }

    func delete(at offsets: IndexSet) {
        let sites = offsets.map { subscriptions[$0] }
        for site in sites {
            ReaderSubscriptionHelper().unfollow(site)
        }
    }
}

private struct ReaderSidebarTagsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: ReaderSidebarTagsSection.predicate
    )
    private var tags: FetchedResults<ReaderTagTopic>

    static let predicate = NSPredicate(format: "following == YES AND showInMenu == YES AND type == 'tag'")

    var body: some View {
        ForEach(tags, id: \.self) { tag in
            Label {
                Text(tag.title)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            }
            .tag(ReaderSidebarItem.tag(TaggedManagedObjectID(tag)))
            .swipeActions(edge: .trailing) {
                Button(SharedStrings.Reader.unfollow, role: .destructive) {
                    // TODO: (wpsidebar) implement
                }.tint(.red)
            }
        }
        .onDelete(perform: delete)

        Button {
            // TODO: (wpsidebar) implement
        } label: {
            Label(Strings.addTag, systemImage: "plus.circle")
        }

        Button {
            viewModel.navigate(.discoverTags)
        } label: {
            Label(Strings.discoverTags, systemImage: "sparkle.magnifyingglass")
        }
    }

    func delete(at offsets: IndexSet) {
        // TODO: (wpsidebar) implement
    }
}

private struct Strings {
    static let reader = NSLocalizedString("reader.sidebar.navigationTitle", value: "Reader", comment: "Reader sidebar title")
    static let allSubscriptions = NSLocalizedString("reader.sidebar.allSubscriptions", value: "All Subscriptions", comment: "Reader sidebar button title")
    static let addSubscription = NSLocalizedString("reader.sidebar.addSubscription", value: "Add Subscription", comment: "Reader sidebar button title")
    static let subscriptions = NSLocalizedString("reader.sidebar.section.subscriptions.tTitle", value: "Subscriptions", comment: "Reader sidebar section title")
    static let tags = NSLocalizedString("reader.sidebar.section.tags.title", value: "Tags", comment: "Reader sidebar section title")
    static let addTag = NSLocalizedString("reader.sidebar.section.tags.addTag", value: "Add tag", comment: "Reader sidebar button")
    static let discoverTags = NSLocalizedString("reader.sidebar.section.tags.discoverTags", value: "Discover More Tags", comment: "Reader sidebar button")
}
