import UIKit

class ReaderSelectInterestsViewController: UIViewController {
    private struct Constants {
        static let reuseIdentifier = ReaderInterestsCollectionViewCell.classNameWithoutNamespaces()
        static let interestsLabelMargin: CGFloat = 10

        static let cellCornerRadius: CGFloat = 8
        static let cellSpacing: CGFloat = 6
        static let cellHeight: CGFloat = 40
    }

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var nextButton: FancyButton!

    // MARK: - Mock Data Source
    private let fakeDataSource = InterestsDataSource(fileName: "interests.json")

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        applyStyles()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let layout = collectionView.collectionViewLayout as! ReaderInterestsCollectionViewFlowLayout
        layout.invalidateLayout()
    }

    // MARK: - Private Methods
    private func configureCollectionView() {
        let nib = UINib(nibName: String(describing: ReaderInterestsCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: Constants.reuseIdentifier)

        guard let layout = collectionView.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.itemSpacing = Constants.cellSpacing
        layout.cellHeight = Constants.cellHeight
    }

    private func applyStyles() {
        let styleGuide = ReaderInterestsStyleGuide.self
        styleGuide.applyTitleLabelStyles(label: titleLabel)
        styleGuide.applySubtitleLabelStyles(label: subTitleLabel)
        styleGuide.applyNextButtonStyle(button: nextButton)

        buttonContainerView.backgroundColor = ReaderInterestsStyleGuide.buttonContainerViewBackgroundColor
    }
}

// MARK: - UICollectionViewDataSource
extension ReaderSelectInterestsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fakeDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ReaderInterestsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier, for: indexPath) as! ReaderInterestsCollectionViewCell
        let interest: ReaderInterest = fakeDataSource.interest(for: indexPath.row)

        ReaderInterestsStyleGuide.applyCellLabelStyle(label: cell.label,
                                                      isSelected: interest.isSelected)

        cell.layer.cornerRadius = Constants.cellCornerRadius

        cell.label.text = interest.title

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ReaderSelectInterestsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let interest: ReaderInterest = fakeDataSource.interest(for: indexPath.row)
        interest.isSelected = !interest.isSelected

        UIView.animate(withDuration: 0.2) {
            collectionView.performBatchUpdates({
                collectionView.reloadItems(at: [indexPath])
            })
        }
    }
}

// MARK: - UICollectionViewFlowLayout
extension ReaderSelectInterestsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interest: ReaderInterest = fakeDataSource.interest(for: indexPath.row)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: ReaderInterestsStyleGuide.cellLabelTitleFont
        ]

        let title: NSString = interest.title as NSString

        var size = title.size(withAttributes: attributes)
        size.width += (Constants.interestsLabelMargin * 2)

        return size
    }

}
