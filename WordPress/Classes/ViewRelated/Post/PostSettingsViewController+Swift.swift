import UIKit
import CoreData
import Combine
import WordPressKit
import WordPressShared
import SwiftUI

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
        let revision = post.createRevision()
        let viewController = PostSettingsViewController.make(for: revision)
        viewController.isStandalone = true
        let navigation = UINavigationController(rootViewController: viewController)
        presentingViewController.present(navigation, animated: true)
    }

    @objc var isDraftOrPending: Bool {
        apost.original().isStatus(in: [.draft, .pending])
    }

    @objc func onViewDidLoad() {
        if isStandalone {
            setupStandaloneEditor()
        }
        if let postID = apost.postID, postID.intValue > 0 {
            tableView.tableFooterView = EntityMetadataTableFooterView.make(id: postID)
        }
    }

    private func setupStandaloneEditor() {
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
        wpAssert(self.isStandalone, "should only be shown for a standalone editor")
        deleteRevision()
        presentingViewController?.dismiss(animated: true)
    }

    @objc private func buttonSaveTapped() {
        navigationItem.rightBarButtonItem = .activityIndicator
        setEnabled(false)

        Task { @MainActor in
            do {
                let coordinator = PostCoordinator.shared
                if coordinator.isSyncAllowed(for: apost) {
                    coordinator.setNeedsSync(for: apost)
                } else {
                    try await coordinator.save(apost)
                }
                presentingViewController?.dismiss(animated: true)
            } catch {
                setEnabled(true)
                refreshNavigationBarButtons()
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

// MARK: - PostSettingsViewController (Visibility)

extension PostSettingsViewController {
    @objc func showPostVisibilitySelector() {
        let view = PostVisibilityPicker(selection: .init(post: apost)) { [weak self] selection in
            guard let self else { return }

            WPAnalytics.track(.editorPostVisibilityChanged, properties: ["via": "settings"])

            switch selection.type {
            case .public, .protected:
                if self.apost.original().status == .scheduled {
                    // Keep it scheduled
                } else {
                    self.apost.status = .publish
                }
            case .private:
                if self.apost.original().status == .scheduled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                        self.showWarningPostWillBePublishedAlert()
                    }
                }
                self.apost.status = .publishPrivate
            }
            self.apost.password = selection.password.isEmpty ? nil : selection.password
            self.navigationController?.popViewController(animated: true)
            self.reloadData()
        }
        let viewController = UIHostingController(rootView: view)
        viewController.title = PostVisibilityPicker.title
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func showWarningPostWillBePublishedAlert() {
        let alert = UIAlertController(title: nil, message: Strings.warningPostWillBePublishedAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PostSettingsViewController (Publish Date)

extension PostSettingsViewController {
    @objc func showPublishDatePicker() {
        var viewModel = PublishSettingsViewModel(post: self.apost)
        let viewController = PublishDatePickerViewController.make(viewModel: viewModel) { date in
            WPAnalytics.track(.editorPostScheduledChanged, properties: ["via": "settings"])
            viewModel.setDate(date)
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - PostSettingsViewController (Page Attributes)

extension PostSettingsViewController {
    @objc func showParentPageController() {
        guard let page = (self.apost as? Page) else {
            wpAssertionFailure("post has to be a page")
            return
        }
        Task {
            await showParentPageController(for: page)
        }
    }

    @MainActor
    private func showParentPageController(for page: Page) async {
        let request = NSFetchRequest<Page>(entityName: Page.entityName())
        let filter = PostListFilter.publishedFilter()
        request.predicate = filter.predicate(for: apost.blog, author: .everyone)
        request.sortDescriptors = filter.sortDescriptors
        do {
            let context = ContextManager.shared.mainContext
            var pages = try await PostRepository().buildPageTree(request: request)
                .map { pageID, hierarchyIndex in
                    let page = try context.existingObject(with: pageID)
                    page.hierarchyIndex = hierarchyIndex
                    return page
                }
            if let index = pages.firstIndex(of: page) {
                pages = pages.remove(from: index)
            }
            let viewController = ParentPageSettingsViewController.make(with: pages, selectedPage: page)
            viewController.isModalInPresentation = true
            navigationController?.pushViewController(viewController, animated: true)
        } catch {
            wpAssertionFailure("Failed to fetch pages", userInfo: ["error": "\(error)"]) // This should never happen
        }
    }

    @objc func getParentPageTitle() -> String? {
        guard let page = (self.apost as? Page) else {
            wpAssertionFailure("post has to be a page")
            return nil
        }
        guard let pageID = page.parentID else {
            return nil
        }
        let request = NSFetchRequest<Page>(entityName: Page.entityName())
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "postID == %@", pageID)
        guard let parent = try? (page.managedObjectContext?.fetch(request))?.first else {
            return nil
        }
        return parent.titleForDisplay()
    }
}

// MARK: - PostSettingsViewController (Featued Image)

extension PostSettingsViewController {
    @objc func configureFeaturedImageCell(cell: UITableViewCell, viewModel: PostSettingsFeaturedImageViewModel) {
        var configuration = UIHostingConfiguration {
            PostSettingsFeaturedImageCell(post: apost, viewModel: viewModel) { [weak self] in
                self?.showFeaturedImageSelector(cell: cell)
            }
            .environment(\.presentingViewController, self)
        }
        if apost.featuredImage != nil {
            configuration = configuration.margins(.all, 0)
        }
        cell.contentConfiguration = configuration
        cell.selectionStyle = .none
        cell.accessibilityIdentifier = "post_settings_featured_image_cell"
    }

    private func showFeaturedImageSelector(cell: UITableViewCell) {
        guard let featuredImage = apost.featuredImage else { return }
        let lightboxVC = LightboxViewController(media: featuredImage)
        lightboxVC.configureZoomTransition(sourceView: cell.contentView)
        present(lightboxVC, animated: true)
    }
}

private enum Strings {
    static let warningPostWillBePublishedAlertMessage = NSLocalizedString("postSettings.warningPostWillBePublishedAlertMessage", value: "By changing the visibility to 'Private', the post will be published immediately", comment: "An alert message explaning that by changing the visibility to private, the post will be published immediately to your site")
}
