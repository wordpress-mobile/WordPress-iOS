import UIKit
import SwiftUI
import Combine
import WordPressUI

final class ReaderSidebarViewController: UIHostingController<AnyView> {
    let viewModel: ReaderSidebarViewModel

    private var cancellables: [AnyCancellable] = []
    private var viewContext: NSManagedObjectContext { ContextManager.shared.mainContext }
    private var didAppear = false

    init(viewModel: ReaderSidebarViewModel) {
        self.viewModel = viewModel
        // - warning: The `managedObjectContext` has to be set here in order for
        // `ReaderSidebarView` to eb able to access it
        let view = ReaderSidebarView(viewModel: viewModel)
            .environment(\.managedObjectContext, ContextManager.shared.mainContext)
        super.init(rootView: AnyView(view))

        viewModel.navigate = { [weak self] in self?.navigate(to: $0) }
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

    func showInitialSelection() {
        cancellables = []

        // -warning: List occasionally sets the selection to `nil` when switching items.
        viewModel.$selection.compactMap { $0 }
            .removeDuplicates { [weak self] in
                guard $0 == $1 else { return false }
                self?.popSecondaryViewControllerToRoot()
                return true
            }
            .sink { [weak self] in self?.configure(for: $0) }
            .store(in: &cancellables)
    }

    private func configure(for selection: ReaderSidebarItem) {
        switch selection {
        case .main(let screen):
            showSecondary(makeViewController(for: screen))
        case .allSubscriptions:
            showSecondary(makeAllSubscriptionsViewController(), isLargeTitle: true)
        case .subscription(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .list(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .tag(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .organization(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        }

        if didAppear, let splitVC = splitViewController, splitVC.splitBehavior == .overlay {
            DispatchQueue.main.async {
                splitVC.hide(.supplementary)
            }
        }
    }

    private func popSecondaryViewControllerToRoot() {
        let secondaryVC = splitViewController?.viewController(for: .secondary)
        (secondaryVC as? UINavigationController)?.popToRootViewController(animated: true)
    }

    private func makeViewController<T: ReaderAbstractTopic>(withTopicID objectID: TaggedManagedObjectID<T>) -> UIViewController {
        do {
            let topic = try viewContext.existingObject(with: objectID)
            return ReaderStreamViewController.controllerWithTopic(topic)
        } catch {
            wpAssertionFailure("tag missing", userInfo: ["error": "\(error)"])
            return makeErrorViewController()
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
        case .addTag:
            let addTagVC = UIHostingController(rootView: ReaderTagsAddTagView())
            addTagVC.modalPresentationStyle = .formSheet
            addTagVC.preferredContentSize = CGSize(width: 420, height: 124)
            present(addTagVC, animated: true, completion: nil)
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

    func navigate(to path: ReaderNavigationPath) {
        switch path {
        case .recent:
            viewModel.selection = .main(.recent)
        case .discover:
            viewModel.selection = .main(.discover)
        case .likes:
            viewModel.selection = .main(.likes)
        case .search:
            viewModel.selection = .main(.search)
        case .subscriptions:
            viewModel.selection = .allSubscriptions
        case let .post(postID, siteID, isFeed):
            viewModel.selection = nil
            showSecondary(ReaderDetailViewController.controllerWithPostID(NSNumber(value: postID), siteID: NSNumber(value: siteID), isFeed: isFeed))
        case let .postURL(url):
            viewModel.selection = nil
            showSecondary(ReaderDetailViewController.controllerWithPostURL(url))
        case let .topic(topic):
            viewModel.selection = nil
            showSecondary(ReaderStreamViewController.controllerWithTopic(topic))
        case let .tag(slug):
            viewModel.selection = nil
            showSecondary(ReaderStreamViewController.controllerWithTagSlug(slug))
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

private struct ReaderSidebarView: View {
    @ObservedObject var viewModel: ReaderSidebarViewModel

    @AppStorage("reader_sidebar_organization_expanded") var isSectionOrganizationExpanded = true
    @AppStorage("reader_sidebar_subscriptions_expanded") var isSectionSubscriptionsExpanded = true
    @AppStorage("reader_sidebar_lists_expanded") var isSectionListsExpanded = true
    @AppStorage("reader_sidebar_tags_expanded") var isSectionTagsExpanded = true

    @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)])
    private var teams: FetchedResults<ReaderTeamTopic>

    var body: some View {
        List(selection: $viewModel.selection) {
            Section {
                ForEach(ReaderStaticScreen.allCases) {
                    Label($0.localizedTitle, systemImage: $0.systemImage)
                        .tag(ReaderSidebarItem.main($0))
                        .lineLimit(1)
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
        .listStyle(.sidebar)
        .navigationTitle(Strings.reader)
        .toolbar {
            EditButton()
        }
        .tint(preferredTintColor)
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
    static let subscriptions = NSLocalizedString("reader.sidebar.section.subscriptions.tTitle", value: "Subscriptions", comment: "Reader sidebar section title")
    static let lists = NSLocalizedString("reader.sidebar.section.lists.title", value: "Lists", comment: "Reader sidebar section title")
    static let tags = NSLocalizedString("reader.sidebar.section.tags.title", value: "Tags", comment: "Reader sidebar section title")
    static let organization = NSLocalizedString("reader.sidebar.section.organization.title", value: "Organization", comment: "Reader sidebar section title")
}
