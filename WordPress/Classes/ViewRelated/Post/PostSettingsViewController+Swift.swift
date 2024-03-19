import UIKit
import CoreData
import Combine
import WordPressKit

extension PostSettingsViewController {
    static func showStandaloneEditor(for post: AbstractPost, from presentingViewController: UIViewController) {
        let viewController = PostSettingsViewController(post: post.latest())
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

        objc_setAssociatedObject(self, &PostSettingsViewController.postSnapshotKey, RemotePostCreateParameters(post: apost), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        var cancellables: [AnyCancellable] = []
        apost.objectWillChange.sink { [weak self] in
            self?.didUpdateSettings()
        }.store(in: &cancellables)
        objc_setAssociatedObject(self, &PostSettingsViewController.cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if RemoteFeatureFlag.syncPublishing.enabled() {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeObjects), name: NSManagedObjectContext.didChangeObjectsNotification, object: apost.managedObjectContext)
        }
    }

    private func didUpdateSettings() {
        guard let snapshot else { return }
        let changes = RemotePostCreateParameters(post: apost).changes(from: snapshot)
        navigationItem.rightBarButtonItem?.isEnabled = !changes.isEmpty
    }

    private func refreshNavigationBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(buttonCancelTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(buttonSaveTapped))
    }

    @objc private func buttonCancelTapped() {
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func buttonSaveTapped() {
        navigationItem.rightBarButtonItem = .activityIndicator

        setEnabled(false)

        if RemoteFeatureFlag.syncPublishing.enabled() {
            guard let snapshot else {
                return assertionFailure("Snapshot missing")
            }
            Task { @MainActor in
                do {
                    let changes = RemotePostCreateParameters(post: apost).changes(from: snapshot)
                    try await PostCoordinator.shared._update(apost, changes: changes)
                    presentingViewController?.dismiss(animated: true)
                } catch {
                    setEnabled(true)
                    refreshNavigationBarButtons()
                }
            }
        } else {
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
    }

    @objc private func didChangeObjects(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo else { return }

        let deletedPosts = ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? [])
        let original = self.apost.original ?? self.apost
        if deletedPosts.contains(original) {
            presentingViewController?.dismiss(animated: true)
        }
    }

    private var snapshot: RemotePostCreateParameters? {
        objc_getAssociatedObject(self, &PostSettingsViewController.postSnapshotKey) as? RemotePostCreateParameters
    }

    private func setEnabled(_ isEnabled: Bool) {
        tableView.tintAdjustmentMode = isEnabled ? .automatic : .dimmed
        tableView.isUserInteractionEnabled = isEnabled
    }

    private static var cancellablesKey: UInt8 = 0
    private static var postSnapshotKey: UInt8 = 0
}

private enum Strings {
    static let errorMessage = NSLocalizedString("postSettings.updateFailedMessage", value: "Failed to update the post settings", comment: "Error message on post/page settings screen")
}
