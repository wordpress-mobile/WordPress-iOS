import UIKit
import CoreData
import Combine
import WordPressKit

extension PostSettingsViewController {
    static func make(for post: AbstractPost) -> PostSettingsViewController {
        switch post {
        case let post as Post:
            return PostSettingsViewController(post: post)
        case let page as Page:
            return PageSettingsViewController(post: page)
        default:
            fatalError("Unsupported entity: \(post)")
        }
    }

    static func showStandaloneEditor(for post: AbstractPost, from presentingViewController: UIViewController) {
        let revision = RemoteFeatureFlag.syncPublishing.enabled() ? post._createRevision() : post.latest()
        let viewController = PostSettingsViewController.make(for: revision)
        viewController.isStandalone = true
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.navigationBar.isTranslucent = true // Reset to default
        presentingViewController.present(navigation, animated: true)
    }

    @objc var isDraftOrPending: Bool {
        apost.original().isStatus(in: [.draft, .pending])
    }

    @objc func setupStandaloneEditor() {
        guard isStandalone else { return }

        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _setupStandaloneEditor()
        }

        configureDefaultNavigationBarAppearance()

        wpAssert(navigationController?.presentationController != nil)
        navigationController?.presentationController?.delegate = self

        refreshNavigationBarButtons()
        navigationItem.rightBarButtonItem?.isEnabled = false

        var cancellables: [AnyCancellable] = []

        let originalPostID = (apost.original ?? apost).objectID

        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification, object: apost.managedObjectContext)
            .sink { [weak self] notification in
                self?.didChangeObjects(notification, originalPostID: originalPostID)
            }.store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.deleteRevision()
            }.store(in: &cancellables)

        apost.objectWillChange.sink { [weak self] in
            self?.didUpdateSettings()
        }.store(in: &cancellables)

        objc_setAssociatedObject(self, &PostSettingsViewController.cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// - warning: deprecated (kahu-offline-mode)
    @objc private func _setupStandaloneEditor() {
        configureDefaultNavigationBarAppearance()

        refreshNavigationBarButtons()
        navigationItem.rightBarButtonItem?.isEnabled = false

        var cancellables: [AnyCancellable] = []
        apost.objectWillChange.sink { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
        }.store(in: &cancellables)
        objc_setAssociatedObject(self, &PostSettingsViewController.cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func didUpdateSettings() {
        navigationItem.rightBarButtonItem?.isEnabled = !changes.isEmpty
    }

    private func refreshNavigationBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(buttonCancelTapped))

        let buttonSave = UIBarButtonItem(barButtonSystemItem: isStandalone ? .save : .done, target: self, action: #selector(buttonSaveTapped))
        buttonSave.accessibilityLabel = "save"
        navigationItem.rightBarButtonItem = buttonSave
    }

    @objc private func buttonCancelTapped() {
        if RemoteFeatureFlag.syncPublishing.enabled() {
            deleteRevision()
        }
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func buttonSaveTapped() {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _buttonSaveTapped()
        }

        navigationItem.rightBarButtonItem = .activityIndicator
        setEnabled(false)

        Task { @MainActor in
            do {
                let coordinator = PostCoordinator.shared
                if coordinator.isSyncAllowed(for: apost) {
                    coordinator.setNeedsSync(for: apost)
                } else {
                    try await coordinator._save(apost)
                }
                presentingViewController?.dismiss(animated: true)
            } catch {
                setEnabled(true)
                refreshNavigationBarButtons()
            }
        }
    }

    /// - warning: deprecated (kahu-offline-mode)
    private func _buttonSaveTapped() {
        navigationItem.rightBarButtonItem = .activityIndicator
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

    private func didChangeObjects(_ notification: Foundation.Notification, originalPostID: NSManagedObjectID) {
        guard let userInfo = notification.userInfo else { return }

        let deletedObjects = ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? [])
        if deletedObjects.contains(where: { $0.objectID == originalPostID }) {
            presentingViewController?.dismiss(animated: true)
        }
    }

    private var changes: RemotePostUpdateParameters {
        guard let original = apost.original else {
            return RemotePostUpdateParameters()
        }
        return RemotePostUpdateParameters.changes(from: original, to: apost)
    }

    private func deleteRevision() {
        apost.original?.deleteRevision()
        apost.managedObjectContext.map(ContextManager.shared.saveContextAndWait)
    }

    private func setEnabled(_ isEnabled: Bool) {
        navigationItem.leftBarButtonItem?.isEnabled = isEnabled
        isModalInPresentation = !isEnabled
        tableView.tintAdjustmentMode = isEnabled ? .automatic : .dimmed
        tableView.isUserInteractionEnabled = isEnabled
    }

    private static var cancellablesKey: UInt8 = 0
}

extension PostSettingsViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        deleteRevision()
    }
}

private enum Strings {
    static let errorMessage = NSLocalizedString("postSettings.updateFailedMessage", value: "Failed to update the post settings", comment: "Error message on post/page settings screen")
}
