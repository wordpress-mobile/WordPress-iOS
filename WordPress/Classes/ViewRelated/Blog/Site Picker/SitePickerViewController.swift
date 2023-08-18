import UIKit
import WordPressFlux
import WordPressShared
import SwiftUI
import SVProgressHUD

final class SitePickerViewController: UIViewController {

    var blog: Blog {
        didSet {
            blogDetailHeaderView.blog = blog
        }
    }

    var siteIconPresenter: SiteIconPickerPresenter?
    var siteIconPickerPresenter: SiteIconPickerPresenter?
    var onBlogSwitched: ((Blog) -> Void)?
    var onBlogListDismiss: (() -> Void)?

    let meScenePresenter: ScenePresenter
    let blogService: BlogService
    let mediaService: MediaService

    private(set) lazy var blogDetailHeaderView: BlogDetailHeaderView = {
        let headerView = BlogDetailHeaderView(items: [], delegate: self)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    init(blog: Blog,
         meScenePresenter: ScenePresenter,
         blogService: BlogService? = nil,
         mediaService: MediaService? = nil) {
        self.blog = blog
        self.meScenePresenter = meScenePresenter
        self.blogService = blogService ?? BlogService(coreDataStack: ContextManager.shared)
        self.mediaService = mediaService ?? MediaService(managedObjectContext: ContextManager.shared.mainContext)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderView()
        startObservingQuickStart()
        startObservingTitleChanges()
    }

    private func setupHeaderView() {
        blogDetailHeaderView.blog = blog
        view.addSubview(blogDetailHeaderView)
        view.pinSubviewToAllEdges(blogDetailHeaderView)
    }

    private func startObservingTitleChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBlogUpdated), name: .WPBlogUpdated, object: nil)
    }

    @objc private func handleBlogUpdated() {
        DispatchQueue.main.async {
            self.updateTitles()
        }
    }
}

// MARK: - BlogDetailHeaderViewDelegate

extension SitePickerViewController: BlogDetailHeaderViewDelegate {

    func siteIconReceivedDroppedImage(_ image: UIImage?) {
        if !siteIconShouldAllowDroppedImages() {
            // Gracefully ignore the drop for users that can not upload files or
            // blogs that do not have capabilities since those will not support the REST API icon update
            blogDetailHeaderView.updatingIcon = false
            return
        }

        presentCropViewControllerForDroppedSiteIcon(image)
    }

    func siteIconShouldAllowDroppedImages() -> Bool {
        guard blog.isAdmin, blog.isUploadingFilesAllowed() else {
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
            controller?.dismiss(animated: true) {
                self?.onBlogListDismiss?()
            }
        }

        let navigationController = UINavigationController(rootViewController: blogListController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)

        WPAnalytics.track(.mySiteSiteSwitcherTapped)
    }

    func visitSiteTapped() {
        showViewSite()
    }
}

// MARK: - Helpers

extension SitePickerViewController {

    private func switchToBlog(_ blog: Blog) {
        guard self.blog != blog else {
            return
        }

        self.blog = blog
        blogDetailHeaderView.blog = blog

        QuickStartTourGuide.shared.endCurrentTour()
        toggleSpotlightOnHeaderView()

        onBlogSwitched?(blog)
    }

    private func showSiteTitleSettings() {
        let hint = blog.isAdmin ? SiteTitleStrings.siteTitleHint : SiteTitleStrings.notAnAdminHint

        let controller = SettingsTextViewController(text: blog.settings?.name ?? "",
                                                    placeholder: SiteTitleStrings.placeholderText,
                                                    hint: hint)
        controller.title = SiteTitleStrings.settingsViewControllerTitle
        controller.displaysNavigationButtons = true

        controller.onValueChanged = { [weak self] value in
            guard let self = self else {
                return
            }
            self.saveSiteTitleSettings(value, for: self.blog)
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

        QuickStartTourGuide.shared.complete(tour: QuickStartSiteTitleTour(blog: blog),
                                            silentlyForBlog: blog)

        blogService.updateSettings(for: blog, success: { [weak self] in

            let notice = Notice(title: title,
                                message: SiteTitleStrings.titleChangeSuccessfulMessage,
                                feedbackType: .success)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            self?.blogDetailHeaderView.setTitleLoading(false)
            NotificationCenter.default.post(name: NSNotification.Name.WPBlogUpdated, object: nil)
        }, failure: { [weak self] error in
            self?.blog.settings?.name = existingBlogTitle
            self?.blogDetailHeaderView.setTitleLoading(false)
            let notice = Notice(title: SiteTitleStrings.settingsSaveErrorTitle,
                                message: SiteTitleStrings.settingsSaveErrorMessage,
                                feedbackType: .error)
            ActionDispatcher.global.dispatch(NoticeAction.post(notice))

            DDLogError("Error while trying to update blog settings: \(error.localizedDescription)")
        })
    }

    /// Updates site title and navigation bar title
    private func updateTitles() {
        blogDetailHeaderView.refreshSiteTitle()

        guard let parent = parent as? MySiteViewController else {
            return
        }
        parent.updateNavigationTitle(for: blog)
    }

    private func showViewSite() {
        WPAppAnalytics.track(.openedViewSite, withProperties: [WPAppAnalyticsKeyTapSource: "link"], with: blog)

        guard let urlString = blog.homeURL as String?,
              let url = URL(string: urlString) else {
                  return
        }

        let webViewController = WebViewControllerFactory.controller(
            url: url,
            blog: blog,
            source: Constants.viewSiteSource,
            withDeviceModes: true,
            onClose: self.startAlertTimer
        )

        let navigationController = LightNavigationController(rootViewController: webViewController)

        if traitCollection.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .fullScreen
        }

        present(navigationController, animated: true) {
            self.toggleSpotlightOnHeaderView()
        }

        let tourGuide = QuickStartTourGuide.shared
        if tourGuide.isCurrentElement(.viewSite) {
            tourGuide.visited(.viewSite)
        } else {
            // Just mark as completed if we've viewed the site and aren't
            //  currently working on the View Site tour.
            tourGuide.completeViewSiteTour(forBlog: blog)
        }
    }
}

// MARK: - Constants and Strings

extension SitePickerViewController {

    private enum Constants {
        static let viewSiteSource = "my_site_view_site"
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
