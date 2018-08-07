import UIKit

/// UI of the New Card
final class NewsCard: UIViewController, ReaderStreamHeader {
    @IBOutlet weak var dismiss: UIButton!
    @IBOutlet weak var illustration: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var action: UILabel!

    var delegate: ReaderStreamHeaderDelegate? {
        get {
            return decorated?.delegate
        }
        set {
            decorated?.delegate = delegate
        }
    }

    func enableLoggedInFeatures(_ enable: Bool) {
        decorated?.enableLoggedInFeatures(enable)
    }

    func configureHeader(_ topic: ReaderAbstractTopic) {
        decorated?.configureHeader(topic)
    }

    private let manager: NewsManager

    var decorated: ReaderStreamHeader?

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

        loadContent()
    }

    private func loadContent() {
        manager.load { newsItem in
            print("news item")
        }
    }
}
