import UIKit
import WordPressFlux
import WordPressShared
import SwiftUI
import SVProgressHUD
import DesignSystem

final class HomeSiteHeaderViewController: UIViewController {

    var blog: Blog {
        didSet {
            blogDetailHeaderView.blog = blog
        }
    }

    var siteIconPickerPresenter: SiteIconPickerPresenter?
    var onBlogSwitched: ((Blog) -> Void)?
    var onBlogListDismiss: (() -> Void)?

    let blogService: BlogService
    let mediaService: MediaService

    private(set) lazy var blogDetailHeaderView: BlogDetailHeaderView = {
        let headerView = BlogDetailHeaderView(delegate: self, isSidebarModeEnabled: isSidebarModeEnabled)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    private var sitePickerTipObserver: TipObserver?
    private let isSidebarModeEnabled: Bool

    init(blog: Blog,
         blogService: BlogService? = nil,
         mediaService: MediaService? = nil,
         isSidebarModeEnabled: Bool) {
        self.blog = blog
        self.blogService = blogService ?? BlogService(coreDataStack: ContextManager.shared)
        self.mediaService = mediaService ?? MediaService(managedObjectContext: ContextManager.shared.mainContext)
        self.isSidebarModeEnabled = isSidebarModeEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupHeaderView()
        startObservingTitleChanges()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if #available(iOS 17, *) {
            if sitePickerTipObserver == nil,
               traitCollection.horizontalSizeClass == .compact,
               let blogs = blog.account?.blogs,
               !blogs.isEmpty {
                sitePickerTipObserver = registerTipPopover(
                    AppTips.SitePickerTip(),
                    sourceItem: blogDetailHeaderView.titleView.siteSwitcherButton,
                    arrowDirection: [.up]
                )
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sitePickerTipObserver = nil
    }

    private func setupHeaderView() {
        blogDetailHeaderView.blog = blog
        view.addSubview(blogDetailHeaderView)

        if isSidebarModeEnabled {
            NSLayoutConstraint.activate([
                blogDetailHeaderView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
                blogDetailHeaderView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
                blogDetailHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
                blogDetailHeaderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            view.pinSubviewToAllEdges(blogDetailHeaderView)
        }
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

extension HomeSiteHeaderViewController: BlogDetailHeaderViewDelegate {

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

    func siteSwitcherTapped(sourceView: UIView) {
        let viewController = SiteSwitcherViewController(
            addSiteAction: { [weak self] in
                self?.addSiteTapped(siteType: $0)
            },
            onSiteSelected: { [weak self] site in
                self?.switchToBlog(site)
                RecentSitesService().touch(blog: site)
                self?.dismiss(animated: true) { [weak self] in
                    self?.onBlogListDismiss?()
                }
            }
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        if isSidebarModeEnabled {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.sourceView = sourceView
        }
        present(navigationController, animated: true)
        WPAnalytics.track(.mySiteSiteSwitcherTapped)
    }

    func visitSiteTapped() {
        showViewSite()
    }
}

// MARK: - Helpers

extension HomeSiteHeaderViewController {

    private func switchToBlog(_ blog: Blog) {
        guard self.blog != blog else {
            return
        }

        self.blog = blog
        blogDetailHeaderView.blog = blog

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
            guard let self else {
                return
            }
            self.saveSiteTitleSettings(value, for: self.blog)
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
        WPAppAnalytics.track(.openedViewSite, properties: [WPAppAnalyticsKeyTapSource: "link"], blog: blog)

        guard let urlString = blog.homeURL as String?,
              let url = URL(string: urlString) else {
                  return
        }

        let webViewController = WebViewControllerFactory.controller(
            url: url,
            blog: blog,
            source: Constants.viewSiteSource,
            withDeviceModes: true,
            onClose: nil
        )

        let navigationController = UINavigationController(rootViewController: webViewController)

        if traitCollection.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .fullScreen
        }

        present(navigationController, animated: true)
    }
}

// MARK: - Constants and Strings

extension HomeSiteHeaderViewController {

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
