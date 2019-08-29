import UIKit

class PostingActivityViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var dayDataView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var legendView: UIView!

    var yearData = [[PostingStreakEvent]]()

    private var selectedDay: PostingActivityDay?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Posting Activity", comment: "Title for stats Posting Activity view.")
        addLegend()
        applyStyles()

        collectionView.register(PostingActivityCollectionViewCell.self, forCellWithReuseIdentifier: PostingActivityCollectionViewCell.reuseIdentifier)

        // Hide the day data view until a day is selected.
        dayDataView.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

}

// MARK: - UICollectionViewDataSource

extension PostingActivityViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return yearData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostingActivityCollectionViewCell.reuseIdentifier, for: indexPath) as! PostingActivityCollectionViewCell
        cell.configure(withData: yearData[indexPath.row], postingActivityDayDelegate: self)

        return cell
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension PostingActivityViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Style.cellSizeForFrameWidth(collectionView.frame.size.width)
    }

}

// MARK: - PostingActivityDayDelegate

extension PostingActivityViewController: PostingActivityDayDelegate {

    func daySelected(_ day: PostingActivityDay) {
        selectedDay?.unselect()
        selectedDay = day

        guard let dayData = day.dayData else {
            return
        }

        dayDataView.isHidden = false
        dateLabel.text = formattedDate(dayData.date)
        postCountLabel.text = formattedPostCount(dayData.postCount)
    }

}

// MARK: - Private Extension

private extension PostingActivityViewController {

    func addLegend() {
        let legend = PostingActivityLegend.loadFromNib()
        legend.backgroundColor = .listForeground
        legendView.addSubview(legend)
    }

    func applyStyles() {
        view.backgroundColor = .listForeground
        collectionView.backgroundColor = .listForeground
        Style.configureLabelAsPostingDate(dateLabel)
        Style.configureLabelAsPostingCount(postCountLabel)
        Style.configureViewAsSeparator(separatorLine)
    }

    func formattedDate(_ date: Date) -> String {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()

        return dateFormatter.string(from: date)
    }

    func formattedPostCount(_ count: Int) -> String {
        let postCountText = (count == 1 ? PostCountLabels.singular : PostCountLabels.plural)
        return String(format: postCountText, count)
    }

    struct PostCountLabels {
        static let singular = NSLocalizedString("%d Post", comment: "Number of posts displayed in Posting Activity when a day is selected. %d will contain the actual number (singular).")
        static let plural = NSLocalizedString("%d Posts", comment: "Number of posts displayed in Posting Activity when a day is selected. %d will contain the actual number (plural).")
    }
}
