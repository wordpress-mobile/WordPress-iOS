import Foundation
import UIKit
import SwiftUI

struct SitePickerView: View {
    @StateObject var viewModel: BlogListViewModel
    let onSiteSelected: (Blog) -> Void

    var body: some View {
        BlogListView(viewModel: viewModel, onSiteSelected: onSiteSelected)
            .searchable(text: $viewModel.searchText)
    }
}

// MARK: - SitePickerView (UIKit)

final class SitePickerHostingController: UIViewController {
    private let configuration: BlogListConfiguration
    private let onSiteSelected: (Blog) -> Void

    var shouldDismissOnSelection = true

    init(configuration: BlogListConfiguration = .defaultConfig, onSiteSelected: @escaping (Blog) -> Void) {
        self.configuration = configuration
        self.onSiteSelected = onSiteSelected
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = BlogListViewModel(configuration: configuration)
        let sitePickerView = SitePickerView(viewModel: viewModel) { [weak self] in
            guard let self else { return }
            if self.shouldDismissOnSelection {
                self.presentingViewController?.dismiss(animated: true)
            }
            self.onSiteSelected($0)
        }

        let viewController = UIHostingController(rootView: sitePickerView)
        viewController.title = title

        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.cancel, style: .plain, target: self, action: #selector(buttonCancelTapped))

        let navigationController = UINavigationController(rootViewController: viewController)
        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(navigationController.view)
        navigationController.didMove(toParent: self)
    }

    @objc private func buttonCancelTapped() {
        presentingViewController?.dismiss(animated: true)
    }
}
