import UIKit
import SwiftUI
import WordPressUI

final class ReaderFollowingViewController: UIViewController {
    private let mainContext = ContextManager.shared.mainContext

    override func viewDidLoad() {
        super.viewDidLoad()

        title = SharedStrings.Reader.following
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        let followingView = ReaderFollowingView()
            .environment(\.managedObjectContext, mainContext)
        let hostVC = UIHostingController(rootView: followingView)

        addChild(hostVC)
        view.addSubview(hostVC.view)
        hostVC.view.pinEdges()
        hostVC.didMove(toParent: self)
    }
}

private struct ReaderFollowingView: View {
    @StateObject var viewModel = ReaderFollowingViewModel()
    @State var selectedTab: ReaderFollowingTab = .subscriptions

    var body: some View {
        List {
            filters

            switch selectedTab {
            case .subscriptions:
                ReaderFollowingSubscriptionsView { _ in
                    // TODO: (reader) push
                }
            case .lists:
                EmptyView()
            case .tags:
                EmptyView()
            }
        }
        .listStyle(.plain)
        .task {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var filters: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ReaderFollowingTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        MenuItem(tab.title, isSelected: tab == selectedTab)
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

private enum ReaderFollowingTab: CaseIterable {
    case subscriptions, lists, tags

    var title: String {
        switch self {
        case .subscriptions: NSLocalizedString("reader.following.subscriptions", value: "Subscriptions", comment: "Tabs on Reader Following screen")
        case .lists: NSLocalizedString("reader.following.lists", value: "Lists", comment: "Tabs on Reader Following screen")
        case .tags: NSLocalizedString("reader.following.tags", value: "Tags", comment: "Tabs on Reader Following screen")
        }
    }
}
