import Foundation


protocol RelatedPostsViewControllerDelegate: class {
    func loadedRelatedPosts()
}


class RelatedPostsViewController: UIViewController {

    @IBOutlet var relatedSitestackView: UIStackView!
    @IBOutlet var relatedWPComStackView: UIStackView!
    @IBOutlet var siteLabel: UILabel!
    @IBOutlet var wpcomLabel: UILabel!

    var delegate: RelatedPostsViewControllerDelegate?

    var post: ReaderPost? {
        didSet {
            fetchRelatedPostsIfNeeded()
        }
    }


    open class func controllerWithPost(_ post: ReaderPost) -> RelatedPostsViewController {
        let controller = RelatedPostsViewController()
        controller.post = post
        return controller
    }


    // Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        configureView()
    }


    // Configuration


    func setupView() {
        applyStyles()

    }


    func applyStyles() {

    }


    func configureView() {
        configureSitePosts()
        configureWPComPosts()

        delegate?.loadedRelatedPosts()
    }


    // Content

    func configureSitePosts() {
        let posts = filteredSitePosts()

        relatedSitestackView.isHidden = posts.count == 0

        let frame = CGRect(x: 0, y: 0, width: 320, height: 100)
        for post in posts {
            let card = ReaderCard(frame: frame)
            card.hidesActionbar = true
            card.headerButtonIsEnabled = false
            card.cardContentMargins = .zero
            card.hidesFollowButton = true
            card.readerPost = post

            relatedSitestackView.addArrangedSubview(card)
        }
    }


    func filteredSitePosts()-> [ReaderPost] {
        guard let post = post else {
            return [ReaderPost]()
        }

        let posts = post.relatedPosts.filter { (relatedPost) -> Bool in
            return relatedPost.siteID.intValue == post.siteID.intValue
        }

        return posts
    }


    func configureWPComPosts() {
        let posts = filteredWPComPosts()

        relatedWPComStackView.isHidden = posts.count == 0

        let frame = CGRect(x: 0, y: 0, width: 320, height: 100)
        for post in posts {
            let card = ReaderCard(frame: frame)
            card.hidesActionbar = true
            card.headerButtonIsEnabled = false
            card.cardContentMargins = .zero
            card.readerPost = post

            relatedWPComStackView.addArrangedSubview(card)
        }
    }


    func filteredWPComPosts() -> [ReaderPost] {
        guard let post = post else {
            return [ReaderPost]()
        }

        let posts = post.relatedPosts.filter { (relatedPost) -> Bool in
            return relatedPost.siteID.intValue != post.siteID.intValue
        }

        return posts
    }



    // Fetching


    func fetchRelatedPostsIfNeeded() {
        guard let post = post else {
            return
        }

        if post.relatedPosts.count > 0 {
            configureView()
            return
        }

        let context = ContextManager.sharedInstance().newDerivedContext()
        let service = ReaderPostService(managedObjectContext: context)
        service.fetchRelatedPosts(for: post, success: { [weak self] in
            self?.configureView()
        }, failure: { (error) in
            // Fail silently.
            DDLogSwift.logInfo("\(error)")
        })

    }

}
