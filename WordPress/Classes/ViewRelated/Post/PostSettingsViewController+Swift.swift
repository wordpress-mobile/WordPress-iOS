import UIKit
import CoreData
import Combine
import WordPressKit

extension PostSettingsViewController {
    static func make(for post: AbstractPost) -> PostSettingsViewController {
        if let post = post as? Post {
            return PostSettingsViewController(post: post.latest())
        } else {
            return PageSettingsViewController(post: post)
        }
    }

    static func showStandaloneEditor(for post: AbstractPost, from presentingViewController: UIViewController) {
        let viewController = PostSettingsViewController.make(for: post)
        viewController.isStandalone = true
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.navigationBar.isTranslucent = true // Reset to default
        presentingViewController.present(navigation, animated: true)
    }

    @objc func onViewDidLoad() {
        configureDefaultNavigationBarAppearance()

        refreshNavigationBarButtons()
        navigationItem.rightBarButtonItem?.isEnabled = false

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
        navigationItem.rightBarButtonItem?.isEnabled = !changes.isEmpty
    }

    private func refreshNavigationBarButtons() {
        let buttonCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(buttonCancelTapped))
        buttonCancel.accessibilityLabel = "cancel"
        navigationItem.leftBarButtonItem = buttonCancel

        let buttonSave = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(buttonSaveTapped))
        buttonSave.accessibilityLabel = "save"
        navigationItem.rightBarButtonItem = buttonSave
    }

    @objc private func buttonCancelTapped() {
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func buttonSaveTapped() {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _buttonSaveTapped()
        }

        guard isStandalone else {
            saveChangesToParentContext()
            presentingViewController?.dismiss(animated: true)
            return
        }

        navigationItem.rightBarButtonItem = .activityIndicator
        setEnabled(false)

        Task { @MainActor in
            do {
                let original = (snapshot.original ?? snapshot)
                if original.status == .draft {
                    saveChangesToParentContext()
                    // TODO: Replace with new PostRepository._save
                    PostCoordinator.shared.save(original)
                } else {
                    try await PostCoordinator.shared._update(original, changes: changes)
                }
                presentingViewController?.dismiss(animated: true)
            } catch {
                setEnabled(true)
                refreshNavigationBarButtons()

            }
        }
    }

    /// Returns a diff from the snapshot to the updated version of the post.
    private var changes: RemotePostUpdateParameters {
        RemotePostUpdateParameters.changes(from: snapshot, to: apost)
    }

    private func saveChangesToParentContext() {
        do {
            try self.apost.managedObjectContext?.save()
        } catch {
            // Should never happen
            WordPressAppDelegate.crashLogging?.logError(error)
        }
    }

    /// - note: Deprecated (kahu-offline-mode)
    private func _buttonSaveTapped() {
        saveChangesToParentContext()
        PostCoordinator.shared.save(apost)
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func didChangeObjects(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo else { return }

        let deletedPosts = ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? [])
        let original = self.apost.original ?? self.apost
        if deletedPosts.contains(original) {
            presentingViewController?.dismiss(animated: true)
        }
    }

    private func setEnabled(_ isEnabled: Bool) {
        navigationItem.leftBarButtonItem?.isEnabled = isEnabled
        isModalInPresentation = !isEnabled
        tableView.tintAdjustmentMode = isEnabled ? .automatic : .dimmed
        tableView.isUserInteractionEnabled = isEnabled
    }

    private static var cancellablesKey: UInt8 = 0
}

private enum Strings {
    static let errorMessage = NSLocalizedString("postSettings.updateFailedMessage", value: "Failed to update the post settings", comment: "Error message on post/page settings screen")
}
