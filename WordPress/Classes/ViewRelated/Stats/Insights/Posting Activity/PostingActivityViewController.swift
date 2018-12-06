import UIKit

class PostingActivityViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "PostingActivityViewController"

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var dayDataView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var legendView: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Posting Activity", comment: "Title for stats Posting Activity view.")
        addLegend()
        applyStyles()

        collectionView.register(PostingActivityCollectionViewCell.defaultNib,
                                forCellWithReuseIdentifier: PostingActivityCollectionViewCell.defaultReuseID)

        // Hide the day data view until a day is selected.
        dayDataView.isHidden = true
    }

}

// MARK: - UICollectionViewDelegate

extension PostingActivityViewController: UICollectionViewDelegate {

}

// MARK: - UICollectionViewDataSource

extension PostingActivityViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostingActivityCollectionViewCell.defaultReuseID, for: indexPath) as! PostingActivityCollectionViewCell

        return cell
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension PostingActivityViewController: UICollectionViewDelegateFlowLayout {

}

// MARK: - Private Extension

private extension PostingActivityViewController {

    func addLegend() {
        let legend = PostingActivityLegend.loadFromNib()
        legendView.addSubview(legend)
    }

    func applyStyles() {
        Style.configureLabelAsPostingDate(dateLabel)
        Style.configureLabelAsPostingCount(postCountLabel)
        Style.configureViewAsSeperator(separatorLine)
    }
}
