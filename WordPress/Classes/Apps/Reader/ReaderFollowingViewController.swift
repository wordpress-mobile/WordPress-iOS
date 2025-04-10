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

struct ReaderFollowingView: View {
    var body: some View {
        List {
            filters
            Text("Here")
            Text("There")
        }
        .listStyle(.plain)
    }

    private var filters: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MenuItem("Subscriptions", isSelected: true)
                MenuItem("Lists", isSelected: false)
                MenuItem("Tags")
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

private struct FilterTabBarHostingView: UIViewRepresentable {
    func makeUIView(context: Context) -> FilterTabBar {
        let view = FilterTabBar()
        WPStyleGuide.configureFilterTabBar(view)
        view.isAutomaticTabSizingStyleEnabled = true
        view.items = ReaderFollowingTab.allCases
        view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 40))
        return view
    }

    func updateUIView(_ uiView: FilterTabBar, context: Context) {
        // Do nothing
    }
}

private enum ReaderFollowingTab: FilterTabBarItem, CaseIterable {
    case subscriptions, lists, tags

    var title: String {
        switch self {
        case .subscriptions:
            return "Subscriptions"
        case .lists:
            return "Lists"
        case .tags:
            return "Tags"
        }
    }

    var accessibilityIdentifier: String { title }
}
