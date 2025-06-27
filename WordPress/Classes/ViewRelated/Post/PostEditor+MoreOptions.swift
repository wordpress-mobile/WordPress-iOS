import Foundation
import SVProgressHUD
import WordPressFlux
import WordPressUI
import SwiftUI

extension PostEditor {

    @MainActor
    func displayPostSettings() {
        // Use the new SwiftUI-based Post Settings
        let originalFeaturedImageID = post.featuredImage?.mediaID
        let viewModel = PostSettingsViewModel(post: post)
        viewModel.onEditorPostSaved = { [weak self] in
            self?.editorContentWasUpdated()

            // Check if featured image changed and notify Gutenberg
            if let self,
               let gutenbergVC = self as? GutenbergViewController,
               originalFeaturedImageID != self.post.featuredImage?.mediaID {
                let newMediaID = self.post.featuredImage?.mediaID ?? GutenbergFeaturedImageHelper.mediaIdNoFeaturedImageSet as NSNumber
                gutenbergVC.gutenbergDidRequestFeaturedImageId(newMediaID)
            }

            self?.navigationController?.dismiss(animated: true)
        }
        let postSettingsVC = PostSettingsViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: postSettingsVC)
        self.navigationController?.present(navigation, animated: true)
    }

    private func savePostBeforePreview(completion: @escaping ((String?, Error?) -> Void)) {
        guard !post.changes.isEmpty || post.original().isNewDraft else {
            completion(nil, nil)
            return
        }

        Task { @MainActor in
            let coordinator = PostCoordinator.shared
            do {
                if post.isStatus(in: [.draft, .pending]) {
                    SVProgressHUD.setDefaultMaskType(.clear)
                    SVProgressHUD.show(withStatus: Strings.savingDraft)

                    let original = post.original()
                    try await coordinator.save(original)
                    self.post = original
                    self.createRevisionOfPost()

                    completion(nil, nil)
                } else {
                    SVProgressHUD.setDefaultMaskType(.clear)
                    SVProgressHUD.show(withStatus: Strings.creatingAutosave)
                    let autosave = try await PostRepository().autosave(post)
                    completion(autosave.previewURL.absoluteString, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
    }

    private func displayPreviewNotAvailable(title: String, subtitle: String? = nil) {
        let noResultsController = NoResultsViewController.controllerWith(title: title, subtitle: subtitle)
        noResultsController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(noResultsController, animated: true)
    }

    func displayPreview() {
        guard !isUploadingMedia else {
            displayMediaIsUploadingAlert()
            return
        }

        emitPostSaveEvent()

        savePostBeforePreview() { [weak self] previewURLString, error in
            guard let self else {
                return
            }

            SVProgressHUD.dismiss()

            if error != nil {
                let title = NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" )
                self.displayPreviewNotAvailable(title: title)
                return
            }

            let previewController: PreviewWebKitViewController
            if let previewURLString, let previewURL = URL(string: previewURLString) {
                previewController = PreviewWebKitViewController(post: self.post, previewURL: previewURL, source: "edit_post_more_preview")
            } else {
                if self.post.permaLink == nil {
                    DDLogError("displayPreview: Post permalink is unexpectedly nil")
                    self.displayPreviewNotAvailable(title: NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" ))
                    return
                }
                previewController = PreviewWebKitViewController(post: self.post, source: "edit_post_more_preview")
            }
            previewController.trackOpenEvent()
            let navWrapper = UINavigationController(rootViewController: previewController)
            if self.navigationController?.traitCollection.userInterfaceIdiom == .pad {
                navWrapper.modalPresentationStyle = .fullScreen
            }
            self.navigationController?.present(navWrapper, animated: true)
        }
    }

    func displayRevisionsList() {
        let viewController = RevisionsTableViewController(post: post)
        viewController.onRevisionSelected = { [weak self] revision in
            guard let self else { return }

            self.navigationController?.popViewController(animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                self.post.postTitle = revision.postTitle
                self.post.content = revision.postContent
                self.post.mt_excerpt = revision.postExcerpt

                // It's important to clear the pending uploads associated with the
                // post. The assumption is that if the revision on the remote,
                // its associated media has to be also uploaded.
                MediaCoordinator.shared.cancelUploadOfAllMedia(for: self.post)
                self.post.media = []

                self.post = self.post // Reload the ui

                let notice = Notice(title: Strings.revisionLoaded, feedbackType: .success)
                ActionDispatcher.dispatch(NoticeAction.post(notice))
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private enum Strings {
    static let savingDraft = NSLocalizedString("postEditor.savingDraftForPreview", value: "Saving draft...", comment: "Saving draft to generate a preview (status message")
    static let creatingAutosave = NSLocalizedString("postEditor.creatingAutosaveForPreview", value: "Creating autosave...", comment: "Creating autosave to generate a preview (status message")
    static let revisionLoaded = NSLocalizedString("postEditor.revisionLoaded", value: "Revision loaded", comment: "Title for a snackbar")
}
