import UIKit
import WordPressShared.WPStyleGuide
import Gridicons

/// UI of the New Card
final class NewsCard: UIViewController {
    @IBOutlet weak var dismiss: UIButton!
    @IBOutlet weak var illustration: UIImageView!
    @IBOutlet weak var newsTitle: UILabel!
    @IBOutlet weak var newsSubtitle: UILabel!
    @IBOutlet weak var newsAction: UILabel!
    @IBOutlet weak var borderedView: UIView!

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
        applyStyles()
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

    private func applyStyles() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(newsTitle)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(newsSubtitle)

        dismiss.setImage(Gridicon.iconOfType(.crossCircle, withSize: CGSize(width: 40, height: 40)), for: .normal)
        dismiss.setTitle(nil, for: .normal)
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
