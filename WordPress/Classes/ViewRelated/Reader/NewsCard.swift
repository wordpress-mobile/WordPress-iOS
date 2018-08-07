import UIKit

/// UI of the New Card
final class NewsCard: UIViewController {
    @IBOutlet weak var dismiss: UIButton!
    @IBOutlet weak var illustration: UIImageView!
    @IBOutlet weak var newsTitle: UILabel!
    @IBOutlet weak var newsSubtitle: UILabel!
    @IBOutlet weak var newsAction: UILabel!

    private let manager: NewsManager

    init(manager: NewsManager) {
        self.manager = manager
        super.init(nibName: "NewsCard", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        initIllustration()
        loadContent()
    }

    private func initIllustration() {
        illustration.image = UIImage(named: "wp-illustration-notifications")
    }

    private func loadContent() {
        manager.load { [weak self] newsItem in
            switch newsItem {
            case .error(let error):
                self?.errorLoading(error)
            case .success(let item):
                self?.populate(item)
            }
        }
    }

    private func errorLoading(_ error: Error) {
        print("=== error loading ====")
    }

    private func populate(_ item: NewsItem) {
        newsTitle.text = item.title
        newsSubtitle.text = item.content
        newsAction.text = "More"
    }
}
