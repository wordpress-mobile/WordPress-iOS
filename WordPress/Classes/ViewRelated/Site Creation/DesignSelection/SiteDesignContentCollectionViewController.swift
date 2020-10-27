import UIKit

private let reuseIdentifier = "Cell"

class SiteDesignContentCollectionViewController: UICollectionViewController, CollapsableHeaderDataSource {
    let mainTitle = NSLocalizedString("Choose a design", comment: "Title for the screen to pick a design and homepage for a site.")
    let prompt = NSLocalizedString("Pick your fvorite homepage layout. You can customize or change it later", comment: "Prompt for the screen to pick a design and homepage for a site.")
    let defaultActionTitle: String? = nil
    let primaryActionTitle = NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design")
    let secondaryActionTitle = NSLocalizedString("Preview", comment: "Title for the button to preview the selected site homepage design")

    var scrollView: UIScrollView {
        return collectionView
    }

    init() {
        super.init(nibName: "\(SiteDesignContentCollectionViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func estimatedContentSize() -> CGSize {
        return .zero
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        // This is placeholder content to help test the content area.
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.darkGray.cgColor
        cell.backgroundColor = .lightGray
        cell.layer.cornerRadius = 3

        return cell
    }

    // MARK: UICollectionViewFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 230)
    }
}

// MARK: - CollapsableHeaderDelegate
extension SiteDesignContentCollectionViewController: CollapsableHeaderDelegate {
    func primaryActionSelected() {
        /* TODO - connect to choose */
    }
}
