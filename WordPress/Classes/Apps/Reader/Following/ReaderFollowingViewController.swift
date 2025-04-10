import UIKit
import SwiftUI
import WordPressUI

final class ReaderFollowingViewController: UIHostingController<AnyView>, UIPopoverPresentationControllerDelegate {
    private let mainContext = ContextManager.shared.mainContext
    private let viewModel = ReaderFollowingViewModel()

    init() {
        let view = AnyView(ReaderFollowingView(viewModel: viewModel)
            .environment(\.managedObjectContext, mainContext))
        super.init(rootView: view)

        viewModel._navigate = { [weak self] in
            self?.navigate(to: $0)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = SharedStrings.Reader.following
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "reader-menu-plus"), style: .plain, target: self, action: #selector(buttonAddTapped))
    }

    private func navigate(to route: ReaderFollowingNavigation) {
        switch route {
        case .topic(let topic):
            let streamVC = ReaderStreamViewController.controllerWithTopic(topic)
            navigationController?.pushViewController(streamVC, animated: true)
        case .discoverTags:
            ReaderSelectInterestsViewController.show(from: self)
        }
    }

    @objc private func buttonAddTapped(_ item: UIBarButtonItem) {
        switch viewModel.selectedTab {
        case .subscriptions:
            let hostVC = UIHostingController(rootView: ReaderSubscriptionAddView())
            hostVC.modalPresentationStyle = .popover
            hostVC.popoverPresentationController?.delegate = self
            hostVC.popoverPresentationController?.sourceItem = item
            // TODO: (reader) remove hardcoded size
            hostVC.preferredContentSize = CGSize(width: 320, height: 140)
            present(hostVC, animated: true)
        case .lists:
            let alert = UIAlertController(title: "This feature is not supported in the prototype", message: nil, preferredStyle: .alert)
            alert.addCancelActionWithTitle(SharedStrings.Button.ok)
            present(alert, animated: true)
        case .tags:
            let addTagVC = UIHostingController(rootView: ReaderTagsAddTagView())
            addTagVC.modalPresentationStyle = .popover
            addTagVC.popoverPresentationController?.delegate = self
            addTagVC.popoverPresentationController?.sourceItem = item
            // TODO: (reader) remove hardcoded size
            addTagVC.preferredContentSize = CGSize(width: 320, height: 140)
            present(addTagVC, animated: true, completion: nil)
        }
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

private struct ReaderFollowingView: View {
    @ObservedObject var viewModel: ReaderFollowingViewModel

    var body: some View {
        List {
            filters

            switch viewModel.selectedTab {
            case .subscriptions:
                ReaderFollowingSubscriptionsView(viewModel: viewModel)
            case .lists:
                ReaderFollowingListsView(viewModel: viewModel)
            case .tags:
                ReaderFollowingTagsView(viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .task { await viewModel.refresh() }
        .refreshable { await viewModel.refresh() }
        // TODO: (reader) add searching
//        .searchable(text: $viewModel.searchText)
    }

    private var filters: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ReaderFollowingTab.allCases, id: \.self) { tab in
                    Button {
                        viewModel.selectedTab = tab
                    } label: {
                        MenuItem(tab.title, isSelected: tab == viewModel.selectedTab)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .font(.subheadline)
            Divider()
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden, edges: .all)
    }
}

// TODO: (reader) create a proper reusable component; this one is just for a prototype
private struct MenuItem: View {
    let title: String
    let isSelected: Bool

    init(_ title: String, isSelected: Bool = false) {
        self.title = title
        self.isSelected = isSelected
    }

    var body: some View {
        VStack {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(isSelected ? Color.black : Color(uiColor: .separator))
                .opacity(isSelected ? 1 : 0)
        }
    }
}
