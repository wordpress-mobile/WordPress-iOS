import SwiftUI
import DesignSystem
import WordPressUI

final class SiteSwitcherViewController: UIHostingController<SiteSwitcherView>, UIPopoverPresentationControllerDelegate {
    private let viewModel: BlogListViewModel

    init(configuration: BlogListConfiguration = .defaultConfig,
         addSiteAction: @escaping ((AddSiteMenuViewModel.Selection) -> Void),
         onSiteSelected: @escaping ((Blog) -> Void)) {
        self.viewModel = BlogListViewModel(configuration: configuration)
        self.viewModel.onAddSiteTapped = addSiteAction
        super.init(rootView: SiteSwitcherView(viewModel: viewModel, onSiteSelected: onSiteSelected))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popoverPresentationController?.delegate = self

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

    // MARK: UIPopoverPresentationControllerDelegate

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = AddSiteMenuViewModel(onSelection: { [weak self] selection in
            guard let self else { return }
            self.presentingViewController?.dismiss(animated: true) {
                self.viewModel.onAddSiteTapped(selection)
            }
        }).makeBarButtonItem()

        preferredContentSize = SiteSwitcherViewController.preferredContentSize(for: viewModel)
        viewModel.isPresentedInPopover = true
    }

    // There is no good way to determine the exact size of the underling SwiftUI List,
    // and this is the best approximation to ensure it doesn't look too off when
    // you have only a few sites.
    static func preferredContentSize(for viewModel: BlogListViewModel) -> CGSize {
        CGSize(width: 375, height: {
            if viewModel.allSites.count <= 5 {
                return 350
            } else if viewModel.allSites.count <= 10 {
                return 520
            } else {
                return 750
            }
        }())
    }
}

struct SiteSwitcherView: View {
    @ObservedObject var viewModel: BlogListViewModel

    let onSiteSelected: ((Blog) -> Void)

    var body: some View {
        BlogListView(viewModel: viewModel, onSiteSelected: onSiteSelected)
            .safeAreaInset(edge: .bottom) {
                if !viewModel.isPresentedInPopover {
                    SiteSwitcherToolbarView(viewModel: viewModel)
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(Strings.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SiteSwitcherToolbarView: View {
    @ObservedObject var viewModel: BlogListViewModel

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
        let viewModel = AddSiteMenuViewModel(onSelection: viewModel.onAddSiteTapped)
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
