import SwiftUI
import DesignSystem

final class SiteSwitcherViewController: UIHostingController<SiteSwitcherView> {
    private let viewModel: BlogListViewModel

    init(configuration: BlogListConfiguration = .defaultConfig,
         addSiteAction: @escaping ((AddSiteMenuViewModel.Selection) -> Void),
         onSiteSelected: @escaping ((Blog) -> Void)) {
        self.viewModel = BlogListViewModel(configuration: configuration)
        super.init(rootView: SiteSwitcherView(
            viewModel: viewModel,
            addSiteAction: addSiteAction,
            onSiteSelected: onSiteSelected
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, style: .plain, target: self, action: #selector(buttonCloseTapped))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "my-sites-cancel-button"

        if #available(iOS 17, *) {
            AppTips.SitePickerTip().invalidate(reason: .actionPerformed)
        }
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

struct SiteSwitcherView: View {
    @ObservedObject var viewModel: BlogListViewModel

    let addSiteAction: ((AddSiteMenuViewModel.Selection) -> Void)
    let onSiteSelected: ((Blog) -> Void)

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
    let addSiteAction: ((AddSiteMenuViewModel.Selection) -> Void)

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
        let viewModel = AddSiteMenuViewModel(onSelection: addSiteAction)
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
