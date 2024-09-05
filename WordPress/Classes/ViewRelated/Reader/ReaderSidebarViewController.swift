import UIKit
import SwiftUI
import Combine

final class ReaderSidebarViewController: UIHostingController<ReaderSidebarView> {
    let viewModel: ReaderSidebarViewModel

    private var cancellables: [AnyCancellable] = []
    private var viewContext: NSManagedObjectContext { ContextManager.shared.mainContext }

    init(viewModel: ReaderSidebarViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReaderSidebarView(viewModel: viewModel))
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
            showSecondary(ReaderFollowedSitesViewController.controller())
        case .subscription(let objectID):
            do {
                let site = try viewContext.existingObject(with: objectID)
                showSecondary(ReaderStreamViewController.controllerWithTopic(site))
            } catch {
                wpAssertionFailure("site missing", userInfo: ["error": "\(error)"])
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
                // TODO: (wpsidebar) add error handling (hardcode links to topics?)
                return UIViewController()
            }
        case .saved:
            return ReaderStreamViewController.controllerForContentType(.saved)
        case .search:
            return ReaderSearchViewController.controller(withSearchText: "")
        }
    }

    private func showSecondary(_ viewController: UIViewController) {
        let navigationVC = UINavigationController(rootViewController: viewController)
        splitViewController?.setViewController(navigationVC, for: .secondary)
    }
}

struct ReaderSidebarView: View {
    @ObservedObject var viewModel: ReaderSidebarViewModel

    @AppStorage("reader_sidebar_subscriptions_expanded") var isSectionSubscriptionsExpanded = true

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
        }
        .listStyle(.sidebar)
        .navigationTitle(Strings.reader)
        .toolbar {
            EditButton()
        }
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

// TODO: (wpsidebar) Add button to add subscription (how should it work?)
private struct ReaderSidebarSubscriptionsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    @State private var isShowingAll = false

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
                Button(role: .destructive) {
                    unfollow(site)
                } label: {
                    Text(Strings.unfollow)
                }
            }
        }
        .onDelete(perform: delete)
    }

    func delete(at offsets: IndexSet) {
        let sites = offsets.map { subscriptions[$0] }
        for site in sites {
            unfollow(site)
        }
    }

    private func unfollow(_ site: ReaderSiteTopic) {
        NotificationCenter.default.post(name: .ReaderTopicUnfollowed, object: nil, userInfo: [ReaderNotificationKeys.topic: site])

        let service = ReaderTopicService(coreDataStack: ContextManager.shared)
        service.toggleFollowing(forSite: site, success: { _ in
            // Do nothing
        }, failure: { _, error in
            DDLogError("Could not unfollow site: \(String(describing: error))")
            Notice(title: ReaderFollowedSitesViewController.Strings.failedToUnfollow, message: error?.localizedDescription, feedbackType: .error).post()
        })
    }
}

private struct Strings {
    static let reader = NSLocalizedString("reader.sidebar.navigationTitle", value: "Reader", comment: "Reader sidebar title")
    static let allSubscriptions = NSLocalizedString("reader.sidebar.allSubscriptions", value: "All Subscriptions", comment: "Reader sidebar button title")
    static let addSubscription = NSLocalizedString("reader.sidebar.addSubscription", value: "Add Subscription", comment: "Reader sidebar button title")
    static let subscriptions = NSLocalizedString("reader.sidebar.sectionSubscriptionsTitle", value: "Subscriptions", comment: "Reader sidebar section title")
    static let unfollow = NSLocalizedString("reader.sidebar.unfollow", value: "Unfollow", comment: "Reader sidebar button title")
}
