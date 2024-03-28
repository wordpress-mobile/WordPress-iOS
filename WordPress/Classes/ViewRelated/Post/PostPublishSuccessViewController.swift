import UIKit
import WordPressShared
import Gridicons
import WordPressUI

final class PostPublishSuccessViewController: UIViewController {

    @objc private(set) var post: Post?
    @objc var revealPost = false
    private var hasAnimated = false
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var postStatusLabel: UILabel!
    @IBOutlet var siteIconView: UIImageView!
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var siteUrlLabel: UILabel!
    @IBOutlet var shareButton: FancyButton!
    @IBOutlet var viewButton: FancyButton!
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var postInfoView: UIView!
    @IBOutlet var actionsStackView: UIStackView!
    @IBOutlet var shadeView: UIView!
    @IBOutlet var shareButtonWidth: NSLayoutConstraint!
    @IBOutlet var viewButtonWidth: NSLayoutConstraint!

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels()
        setupNavBar()
    }

    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        doneButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.barButtonItemTitle], for: .normal)
        doneButton.accessibilityIdentifier = "doneButton"
        navBar.topItem?.rightBarButtonItem = doneButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = .basicBackground

        view.alpha = WPAlphaZero

        shareButton.setTitle(NSLocalizedString("Share", comment: "Button label to share a post"), for: .normal)
        shareButton.accessibilityIdentifier = "sharePostButton"
        shareButton.setImage(.gridicon(.shareiOS, size: CGSize(width: 18, height: 18)), for: .normal)
        shareButton.tintColor = .white

        shareButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        viewButton.setTitle(NSLocalizedString("View Post", comment: "Button label for viewing a post"), for: .normal)
        viewButton.accessibilityIdentifier = "viewPostButton"

        configureForPost()

        if revealPost {
            WPAnalytics.track(.postEpilogueDisplayed)

            view.alpha = WPAlphaFull
            animatePostPost()
        }
    }

    private func setupLabels() {
        titleLabel.textColor = .label
        postStatusLabel.textColor = .secondaryLabel
        siteNameLabel.textColor = .label
        siteUrlLabel.textColor = .label
    }

    @objc func animatePostPost() {
        guard !hasAnimated else {
            return
        }
        hasAnimated = true

        shadeView.isHidden = false
        shadeView.backgroundColor = UIColor.black
        shadeView.alpha = WPAlphaFull * 0.5
        postInfoView.alpha = WPAlphaZero
        viewButton.alpha = WPAlphaZero
        shareButton.alpha = WPAlphaZero

        let animationScaleBegin: CGFloat = -0.75
        shareButtonWidth.constant = shareButton.frame.size.width * animationScaleBegin
        viewButtonWidth.constant = shareButton.frame.size.width * animationScaleBegin
        view.layoutIfNeeded()

        guard let transitionCoordinator = transitionCoordinator else {
            return
        }

        transitionCoordinator.animate(alongsideTransition: { (context) in
            let animationDuration = context.transitionDuration

            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.shadeView.alpha = WPAlphaZero
                })

            UIView.animate(withDuration: animationDuration * 0.66, delay: 0, options: .curveEaseOut, animations: {
                self.postInfoView.alpha = WPAlphaFull
                })

            UIView.animate(withDuration: 0.2, delay: animationDuration * 0.5, options: .curveEaseOut, animations: {
                self.shareButton.alpha = WPAlphaFull
                self.shareButtonWidth.constant = 0
                self.actionsStackView.layoutIfNeeded()
                })
            UIView.animate(withDuration: 0.2, delay: animationDuration * 0.7, options: .curveEaseOut, animations: {
                self.viewButton.alpha = WPAlphaFull
                self.viewButtonWidth.constant = 0
                self.actionsStackView.layoutIfNeeded()
                })
        }) { (context) in }
    }

    private func configureForPost() {
        guard let post = self.post,
            let blogSettings = post.blog.settings else {
                return
        }

        titleLabel.text = post.titleForDisplay().strippingHTML()
        titleLabel.accessibilityIdentifier = "postTitle"

        if let status = post.status, status == .pending {
            postStatusLabel.text = AbstractPost.title(forStatus: status.rawValue)
            postStatusLabel.accessibilityIdentifier = "pendingPostStatusLabel"
            shareButton.isHidden = true
        } else if post.isScheduled() {
            let format = NSLocalizedString("Scheduled for %@ on", comment: "Precedes the name of the blog a post was just scheduled on. Variable is the date post was scheduled for.")
            postStatusLabel.text = String(format: format, post.dateStringForDisplay())
            postStatusLabel.accessibilityIdentifier = "scheduledPostStatusLabel"
            shareButton.isHidden = true
        } else {
            postStatusLabel.text = NSLocalizedString("Published just now on", comment: "Precedes the name of the blog just posted on")
            postStatusLabel.accessibilityIdentifier = "publishedPostStatusLabel"
            shareButton.isHidden = false
        }
        siteNameLabel.text = blogSettings.name
        siteUrlLabel.text = post.blog.displayURL as String?
        siteUrlLabel.accessibilityIdentifier = "siteUrl"
        siteIconView.downloadSiteIcon(for: post.blog)
        let isPrivate = !post.blog.visible
        if isPrivate {
            shareButton.isHidden = true
        }

    }

    @objc func setup(post: Post) {
        self.post = post

        revealPost = true
    }

    @IBAction func shareTapped() {
        guard let post = post else { return }

        WPAnalytics.track(.postEpilogueShare)
        let sharingController = PostSharingController()
        sharingController.sharePost(post, fromView: shareButton, inViewController: self)
    }

    @IBAction func viewTapped() {
        guard let post = post else { return }

        WPAnalytics.track(.postEpilogueView)

        let controller = PreviewWebKitViewController(post: post, source: "edit_post_preview")
        controller.trackOpenEvent()
        let navWrapper = LightNavigationController(rootViewController: controller)
        if traitCollection.userInterfaceIdiom == .pad {
            navWrapper.modalPresentationStyle = .fullScreen
        }
        present(navWrapper, animated: true)
    }

    @IBAction func doneTapped() {
        presentingViewController?.dismiss(animated: true)
    }
}
