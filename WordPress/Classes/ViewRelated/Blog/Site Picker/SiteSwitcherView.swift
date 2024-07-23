import SwiftUI
import DesignSystem

final class SiteSwitcherViewController: UIViewController {
    private let addSiteAction: (() -> Void)
    private let onSiteSelected: ((Blog) -> Void)

    init(addSiteAction: @escaping (() -> Void),
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
        viewController.configureDefaultNavigationBarAppearance() // Importanat

        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, style: .plain, target: self, action: #selector(buttonCloseTapped))

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.isTranslucent = true // Reset to default

        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(navigationController.view)
        navigationController.didMove(toParent: self)
    }

    @objc private func buttonCloseTapped() {
        presentingViewController?.dismiss(animated: true)
    }
}

private struct SiteSwitcherView: View {
    @State private var searchText = ""
    @State private var isSearching = false

    let addSiteAction: (() -> Void)
    let onSiteSelected: ((Blog) -> Void)
    var eventTracker: EventTracker = DefaultEventTracker()

    var body: some View {
        if #available(iOS 17.0, *) {
            blogListView
                .searchable(
                    text: $searchText,
                    isPresented: $isSearching,
                    placement: .navigationBarDrawer(displayMode: .always)
                )
        } else {
            blogListView
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always)
                )
                .onChange(of: searchText) { newValue in
                    isSearching = !newValue.isEmpty
                }
        }
    }

    private var blogListView: some View {
        BlogListView(
            isSearching: $isSearching,
            searchText: $searchText,
            onSiteSelected: onSiteSelected
        )
        .safeAreaInset(edge: .bottom) {
            if !isSearching {
                HStack {
                    Spacer()
                    FAB(action: addSiteAction)
                        .padding(.trailing, 20)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
                }
            }
        }
        .navigationTitle(Strings.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum Strings {
    static let navigationTitle = NSLocalizedString(
        "sitePicker.title",
        value: "My Sites",
        comment: "Title for site switcher screen"
    )
}
