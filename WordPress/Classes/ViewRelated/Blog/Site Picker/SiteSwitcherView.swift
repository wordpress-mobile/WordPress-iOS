import SwiftUI
import DesignSystem

final class SiteSwitcherViewController: UIViewController {
    private let addSiteAction: ((AddSiteAlertViewModel.Selection) -> Void)
    private let onSiteSelected: ((Blog) -> Void)

    init(addSiteAction: @escaping ((AddSiteAlertViewModel.Selection) -> Void),
         onSiteSelected: @escaping ((Blog) -> Void)) {
        self.addSiteAction = addSiteAction
        self.onSiteSelected = onSiteSelected

        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = UIHostingController(rootView: SiteSwitcherView(addSiteAction: addSiteAction, onSiteSelected: onSiteSelected))

        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, style: .plain, target: self, action: #selector(buttonCloseTapped))
        viewController.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "my-sites-cancel-button"

        let navigationController = UINavigationController(rootViewController: viewController)

        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(navigationController.view)
        navigationController.didMove(toParent: self)
    }

    @objc private func buttonCloseTapped() {
        presentingViewController?.dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        WPAnalytics.track(.siteSwitcherDisplayed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        WPAnalytics.track(.siteSwitcherDismissed)
    }
}

private struct SiteSwitcherView: View {
    let addSiteAction: ((AddSiteAlertViewModel.Selection) -> Void)
    let onSiteSelected: ((Blog) -> Void)

    @StateObject private var viewModel = BlogListViewModel()

    var body: some View {
        BlogListView(viewModel: viewModel, onSiteSelected: onSiteSelected)
            .safeAreaInset(edge: .bottom) {
                SiteSwitcherToolbarView(addSiteAction: addSiteAction)
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(Strings.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SiteSwitcherToolbarView: View {
    let addSiteAction: ((AddSiteAlertViewModel.Selection) -> Void)

    /// - warning: It has to be defined in a view "below" the .searchable
    @Environment(\.isSearching) var isSearching

    var body: some View {
        if !isSearching {
            HStack {
                Spacer()
                button
                    .padding(.trailing, 20)
                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
                    .accessibilityIdentifier("add-site-button")
            }
        }
    }

    @ViewBuilder
    private var button: some View {
        let viewModel = AddSiteAlertViewModel(onSelection: addSiteAction)
        switch viewModel.actions.count {
        case 0:
            EmptyView()
        case 1:
            FAB(action: viewModel.actions[0].handler)
        default:
            Menu {
                // Menu reverses actions by default
                ForEach(viewModel.actions.reversed()) { action in
                    Button(action.title, action: action.handler)
                }
            } label: {
                FAB()
            }
        }
    }
}

private enum Strings {
    static let navigationTitle = NSLocalizedString(
        "sitePicker.title",
        value: "My Sites",
        comment: "Title for site switcher screen"
    )
}
