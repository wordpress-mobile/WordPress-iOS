import Foundation
import UIKit
import WordPressFlux
import WordPressShared
import SwiftUI
import SVProgressHUD

extension MySiteViewController {

    func configureHeaderView() -> NewBlogDetailHeaderView {
        return NewBlogDetailHeaderView(items: [])
    }

}

extension MySiteViewController: BlogDetailHeaderViewDelegate {

    func siteIconTapped() {
        guard siteIconShouldAllowDroppedImages() else {
            // Gracefully ignore the tap for users that can not upload files or
            // blogs that do not have capabilities since those will not support the REST API icon update
            return
        }

        WPAnalytics.track(.siteSettingsSiteIconTapped)

        NoticesDispatch.lock()

        if !FeatureFlag.siteIconCreator.enabled {
            showUpdateSiteIconAlert()
        }

        if #available(iOS 14.0, *) {
            showSiteIconSelectionAlert()
        } else {
            showUpdateSiteIconAlert()
        }
    }

    func siteIconReceivedDroppedImage(_ image: UIImage?) {
        // TODO
    }

    func siteIconShouldAllowDroppedImages() -> Bool {
        guard let blog = blog, blog.isAdmin, blog.isUploadingFilesAllowed() else {
            return false
        }

        return true
    }

    func siteTitleTapped() {
        showSiteTitleSettings()
    }

    func siteSwitcherTapped() {
        guard let blogListController = BlogListViewController(meScenePresenter: meScenePresenter) else {
            return
        }

        blogListController.blogSelected = { [weak self] controller, selectedBlog in
            guard let blog = selectedBlog else {
                return
            }
            self?.switchToBlog(blog)
            controller?.dismiss(animated: true)
        }

        let navigationController = UINavigationController(rootViewController: blogListController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)

        WPAnalytics.track(.mySiteSiteSwitcherTapped)
    }

    func visitSiteTapped() {
        // TODO
    }
}

// MARK: - Site Icon Management

extension MySiteViewController {

    private func showSiteIconSelectionAlert() {
        let alert = UIAlertController(title: SiteIconAlertStrings.title,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        alert.popoverPresentationController?.sourceView = blogDetailHeaderView.blavatarImageView.superview
        alert.popoverPresentationController?.sourceRect = blogDetailHeaderView.blavatarImageView.frame
        alert.popoverPresentationController?.permittedArrowDirections = .any

        alert.addDefaultActionWithTitle(SiteIconAlertStrings.Actions.chooseImage) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.updateSiteIcon()
        }

        alert.addDefaultActionWithTitle(SiteIconAlertStrings.Actions.createWithEmoji) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.showEmojiPicker()
        }

        alert.addDestructiveActionWithTitle(SiteIconAlertStrings.Actions.removeSiteIcon) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.removeSiteIcon()
        }

        alert.addCancelActionWithTitle(SiteIconAlertStrings.Actions.cancel) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.startAlertTimer()
        }

        present(alert, animated: true)
    }

    private func showUpdateSiteIconAlert() {
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        alert.popoverPresentationController?.sourceView = blogDetailHeaderView.blavatarImageView.superview
        alert.popoverPresentationController?.sourceRect = blogDetailHeaderView.blavatarImageView.frame
        alert.popoverPresentationController?.permittedArrowDirections = .any

        alert.addDefaultActionWithTitle(SiteIconAlertStrings.Actions.changeSiteIcon) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.updateSiteIcon()
        }

        if let hasIcon = blog?.hasIcon, hasIcon {
            alert.addDestructiveActionWithTitle(SiteIconAlertStrings.Actions.removeSiteIcon) { [weak self] _ in
                NoticesDispatch.unlock()
                self?.removeSiteIcon()
            }
        }

        alert.addCancelActionWithTitle(SiteIconAlertStrings.Actions.cancel) { [weak self] _ in
            NoticesDispatch.unlock()
            self?.startAlertTimer()
        }

        present(alert, animated: true)
    }

    private func updateSiteIcon() {
        guard let blog = blog else {
            return
        }

        siteIconPickerPresenter = SiteIconPickerPresenter(blog: blog)
        siteIconPickerPresenter?.onCompletion = { [ weak self] media, error in
            if error != nil {
                self?.showErrorForSiteIconUpdate()
            } else if let media = media {
                self?.updateBlogIconWithMedia(media)
            } else {
                // If no media and no error the picker was canceled
                self?.dismiss(animated: true)
            }

            self?.siteIconPickerPresenter = nil
            self?.startAlertTimer()
        }

        siteIconPickerPresenter?.onIconSelection = { [weak self] in
            self?.blogDetailHeaderView.updatingIcon = true
            self?.dismiss(animated: true)
        }

        siteIconPickerPresenter?.presentPickerFrom(self)
    }

    private func showEmojiPicker() {
        guard #available(iOS 14.0, *) else {
            return
        }

        var pickerView = SiteIconPickerView()

        pickerView.onCompletion = { [weak self] image in
            self?.dismiss(animated: true, completion: nil)
            self?.blogDetailHeaderView.updatingIcon = true
            self?.uploadDroppedSiteIcon(image, completion: {})
        }

        pickerView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }

        let controller = UIHostingController(rootView: pickerView)
        present(controller, animated: true)
    }

    private func removeSiteIcon() {
        blogDetailHeaderView.updatingIcon = true
        blog?.settings?.iconMediaID = NSNumber(value: 0)
        updateBlogSettingsAndRefreshIcon()
        WPAnalytics.track(.siteSettingsSiteIconRemoved)
    }

    private func showErrorForSiteIconUpdate() {
        SVProgressHUD.showDismissibleError(withStatus: SiteIconAlertStrings.Errors.iconUpdateFailed)
        blogDetailHeaderView.updatingIcon = false
    }

    private func updateBlogIconWithMedia(_ media: Media) {
        guard let blog = blog else {
            return
        }
        QuickStartTourGuide.shared.completeSiteIconTour(forBlog: blog)
        blog.settings?.iconMediaID = media.mediaID
        updateBlogSettingsAndRefreshIcon()
    }

    private func updateBlogSettingsAndRefreshIcon() {
        guard let blog = blog else {
            return
        }

        blogService.updateSettings(for: blog, success: { [weak self] in

            self?.blogService.syncBlog(blog, success: {
                self?.blogDetailHeaderView.updatingIcon = false
                self?.blogDetailHeaderView.refreshIconImage()
            }, failure: { _ in })

        }, failure: { [weak self] error in
            self?.showErrorForSiteIconUpdate()
        })
    }

    private func uploadDroppedSiteIcon(_ image: UIImage, completion: @escaping (() -> Void)) {
        guard let blog = blog else {
            return
        }

        var creationProgress: Progress?
        mediaService.createMedia(
            with: image,
            blog: blog,
            post: nil,
            progress: &creationProgress,
            thumbnailCallback: nil,
            completion: {  [weak self] media, error in
                guard let media = media, error == nil else {
                    return
                }

                var uploadProgress: Progress?
                self?.mediaService.uploadMedia(
                    media,
                    automatedRetry: false,
                    progress: &uploadProgress,
                    success: {
                        self?.updateBlogIconWithMedia(media)
                        completion()
                    }, failure: { error in
                        self?.showErrorForSiteIconUpdate()
                        completion()
                    })
            })
    }
}

extension MySiteViewController {

    private func switchToBlog(_ blog: Blog) {
        self.blog = blog
        blogDetailHeaderView.blog = blog

        blogDetailsViewController?.showInitialDetailsForBlog()
        blogDetailsViewController?.tableView.reloadData()
        blogDetailsViewController?.preloadMetadata()
    }

    private func showSiteTitleSettings() {
        guard let blog = blog else {
            return
        }

        let hint = blog.isAdmin ? SiteTitleStrings.siteTitleHint : SiteTitleStrings.notAnAdminHint

        let controller = SettingsTextViewController(text: blog.settings?.name ?? "",
                                                    placeholder: SiteTitleStrings.placeholderText,
                                                    hint: hint)
        controller.title = SiteTitleStrings.settingsViewControllerTitle
        controller.displaysNavigationButtons = true

        controller.onValueChanged = { [weak self] value in
            self?.saveSiteTitleSettings(value, for: blog)
        }

        controller.onDismiss = { [weak self] in
            self?.startAlertTimer()
        }

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }

    private func saveSiteTitleSettings(_ title: String, for blog: Blog) {
        // We'll only save for admin users, and if the title has actually changed
        guard title != blog.settings?.name else {
            return
        }

        guard blog.isAdmin else {
            let notice = Notice(title: SiteTitleStrings.notAnAdminHint,
                                message: nil,
                                feedbackType: .warning)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))
            return
        }

        // Save the old value in case we need to roll back
        let existingBlogTitle = blog.settings?.name ?? SiteTitleStrings.defaultSiteTitle
        blog.settings?.name = title
        blogDetailHeaderView.setTitleLoading(true)

        QuickStartTourGuide.shared.complete(tour: QuickStartSiteTitleTour(),
                                                    silentlyForBlog: blog)

        blogService.updateSettings(for: blog, success: { [weak self] in
            NotificationCenter.default.post(name: NSNotification.Name.WPBlogUpdated, object: nil)

            let notice = Notice(title: title,
                                message: SiteTitleStrings.titleChangeSuccessfulMessage,
                                feedbackType: .success)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            self?.blogDetailHeaderView.setTitleLoading(false)
            self?.blogDetailHeaderView.refreshSiteTitle()
        }, failure: { [weak self] error in
            self?.blog?.settings?.name = existingBlogTitle
            self?.blogDetailHeaderView.setTitleLoading(false)
            let notice = Notice(title: SiteTitleStrings.settingsSaveErrorTitle,
                                message: SiteTitleStrings.settingsSaveErrorMessage,
                                feedbackType: .error)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            DDLogError("Error while trying to update blog settings: \(error.localizedDescription)")
        })
    }
}

extension MySiteViewController {

    private enum SiteIconAlertStrings {

        static let title = NSLocalizedString("Update Site Icon", comment: "Title for sheet displayed allowing user to update their site icon")

        enum Actions {
            static let changeSiteIcon = NSLocalizedString("Change Site Icon", comment: "Change site icon button")
            static let chooseImage = NSLocalizedString("Choose Image From My Device", comment: "Button allowing the user to choose an image from their device to use as their site icon")
            static let createWithEmoji = NSLocalizedString("Create With Emoji", comment: "Button allowing the user to create a site icon by choosing an emoji character")
            static let removeSiteIcon = NSLocalizedString("Remove Site Icon", comment: "Remove site icon button")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button")
        }

        enum Errors {
            static let iconUpdateFailed = NSLocalizedString("Icon update failed", comment: "Message to show when site icon update failed")
        }
    }

    private enum SiteTitleStrings {
        static let siteTitleHint = NSLocalizedString("The Site Title is displayed in the title bar of a web browser and is displayed in the header for most themes.", comment: "Description of the purpose of a site's title.")
        static let notAnAdminHint = NSLocalizedString("The Site Title can only be changed by a user with the administrator role.", comment: "Message informing the user that the site title can only be changed by an administrator user.")
        static let placeholderText = NSLocalizedString("A title for the site", comment: "Placeholder text for the title of a site")
        static let defaultSiteTitle = NSLocalizedString("Site Title", comment: "Default title for a site")
        static let settingsViewControllerTitle = NSLocalizedString("Site Title", comment: "Title for screen that show site title editor")
        static let titleChangeSuccessfulMessage = NSLocalizedString("Site title changed successfully", comment: "Confirmation that the user successfully changed the site's title")
        static let settingsSaveErrorTitle = NSLocalizedString("Error updating site title", comment: "Error message informing the user that their site's title could not be changed")
        static let settingsSaveErrorMessage = NSLocalizedString("Please try again later", comment: "Used on an error alert to prompt the user to try again")
    }
}
