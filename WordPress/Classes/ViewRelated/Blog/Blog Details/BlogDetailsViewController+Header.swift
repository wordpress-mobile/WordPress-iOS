import Gridicons
import WordPressFlux

extension BlogDetailsViewController {
    @objc func configureHeaderView() -> BlogDetailHeader {
        let actionItems: [ActionRow.Item] = [
            .init(image: .gridicon(.statsAlt), title: NSLocalizedString("Stats", comment: "Noun. Abbv. of Statistics. Links to a blog's Stats screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showStats(from: .button)
            },
            .init(image: .gridicon(.pages), title: NSLocalizedString("Pages", comment: "Noun. Title. Links to the blog's Pages screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPageList(from: .button)
            },
            .init(image: .gridicon(.posts), title: NSLocalizedString("Posts", comment: "Noun. Title. Links to the blog's Posts screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPostList(from: .button)
            },
            .init(image: .gridicon(.image), title: NSLocalizedString("Media", comment: "Noun. Title. Links to the blog's Media library.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showMediaLibrary(from: .button)
            }
        ]

        guard Feature.enabled(.newNavBarAppearance) else {
            return BlogDetailHeaderView(items: actionItems)
        }

        return NewBlogDetailHeaderView(items: actionItems)
    }

    @objc
    func showSiteTitleSettings() {
        let hint = blog.isAdmin ? SiteTitleStrings.siteTitleHint : SiteTitleStrings.notAnAdminHint

        let controller = SettingsTextViewController(text: blog.settings?.name ?? "",
                                                    placeholder: SiteTitleStrings.placeholderText,
                                                    hint: hint)
        controller.title = SiteTitleStrings.settingsViewControllerTitle
        controller.displaysNavigationButtons = true
        controller.onValueChanged = { [weak self] value in
            self?.saveSiteTitleSettings(value)
        }
        controller.onDismiss = { [weak self] in
            self?.startAlertTimer()
        }
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }

    private func saveSiteTitleSettings(_ title: String) {
        // We'll only save for admin users, and if the title has actually changed
        guard title != blog.settings?.name,
            let context = blog.managedObjectContext else {
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

        let service = BlogService(managedObjectContext: context)
        service.updateSettings(for: blog, success: { [weak self] in
            NotificationCenter.default.post(name: NSNotification.Name.WPBlogUpdated, object: nil)

            let notice = Notice(title: title,
                                message: SiteTitleStrings.titleChangeSuccessfulMessage,
                                feedbackType: .success)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            self?.headerView.refreshSiteTitle()
        }, failure: { [weak self] error in
            self?.blog.settings?.name = existingBlogTitle

            let notice = Notice(title: SiteTitleStrings.settingsSaveErrorTitle,
                                message: SiteTitleStrings.settingsSaveErrorMessage,
                                feedbackType: .error)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            DDLogError("Error while trying to update blog settings: \(error.localizedDescription)")
        })
    }

    enum SiteTitleStrings {
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
