import UIKit
import CoreData
import Combine

extension PostSettingsViewController {
    static func showStandaloneEditor(for post: AbstractPost, from presentingViewController: UIViewController) {
        let viewController: PostSettingsViewController
        if let post = post as? Post {
            viewController = PostSettingsViewController(post: post.latest())
        } else {
            viewController = PageSettingsViewController(post: post)
        }
        viewController.isStandalone = true
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.navigationBar.isTranslucent = true // Reset to default
        presentingViewController.present(navigation, animated: true)
    }

    @objc func setupStandaloneEditor() {
        guard isStandalone else { return }

        configureDefaultNavigationBarAppearance()

        refreshNavigationBarButtons()
        navigationItem.rightBarButtonItem?.isEnabled = false

        var cancellables: [AnyCancellable] = []
        apost.objectWillChange.sink { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
        }.store(in: &cancellables)
        objc_setAssociatedObject(self, &PostSettingsViewController.cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func refreshNavigationBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(buttonCancelTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(buttonDoneTapped))
    }

    @objc private func buttonCancelTapped() {
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func buttonDoneTapped() {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        setEnabled(false)

        PostCoordinator.shared.save(apost) { [weak self] result in
            switch result {
            case .success:
                self?.isStandaloneEditorDismissingAfterSave = true
                self?.presentingViewController?.dismiss(animated: true)
            case .failure:
                self?.setEnabled(true)
                SVProgressHUD.showError(withStatus: Strings.errorMessage)
                self?.refreshNavigationBarButtons()
            }
        }
    }

    private func setEnabled(_ isEnabled: Bool) {
        tableView.tintAdjustmentMode = isEnabled ? .automatic : .dimmed
        tableView.isUserInteractionEnabled = isEnabled
    }

    private static var cancellablesKey: UInt8 = 0
}

private enum Strings {
    static let errorMessage = NSLocalizedString("postSettings.updateFailedMessage", value: "Failed to update the post settings", comment: "Error message on post/page settings screen")
}
