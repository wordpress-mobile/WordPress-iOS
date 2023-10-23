import UIKit

enum ReaderTopicCollectionViewState {
    case collapsed
    case expanded
}

protocol ReaderTopicCollectionViewCoordinatorDelegate: AnyObject {
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didSelectTopic topic: String)
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didChangeState: ReaderTopicCollectionViewState)
}


/// The topics coordinator manages the layout and configuration of a topics chip group collection view.
/// When created it will link to a collectionView and perform all the necessary configuration to
/// display the group with expanding/collapsing support.
///
class ReaderTopicCollectionViewCoordinator: NSObject {
    private struct Constants {
        static let reuseIdentifier = ReaderInterestsCollectionViewCell.classNameWithoutNamespaces()
        static let overflowReuseIdentifier = "OverflowItem"
    }

    private struct Strings {
        static let collapseButtonTitle: String = NSLocalizedString("Hide", comment: "Title of a button used to collapse a group")

        static let expandButtonAccessbilityHint: String = NSLocalizedString("Tap to see all the tags for this post", comment: "VoiceOver Hint to inform the user what action the expand button performs")

        static let collapseButtonAccessbilityHint: String = NSLocalizedString("Tap to collapse the post tags", comment: "Accessibility hint to inform the user what action the hide button performs")

         static let accessbilityHint: String = NSLocalizedString("Tap to view posts for this tag", comment: "Accessibility hint to inform the user what action the post tag chip performs")
    }

    private lazy var metrics: ReaderInterestsStyleGuide.Metrics = {
        return RemoteFeatureFlag.readerImprovements.enabled() ? .latest : .legacy
    }()

    weak var delegate: ReaderTopicCollectionViewCoordinatorDelegate?

    weak var collectionView: UICollectionView?

    var topics: [String] {
        didSet {
            reloadData()
        }
    }

    init(collectionView: UICollectionView, topics: [String]) {
        self.collectionView = collectionView
        self.topics = topics

        super.init()

        configure(collectionView)
    }

    func invalidate() {
        guard let layout = collectionView?.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.isExpanded = false
        layout.invalidateLayout()
    }

    func reloadData() {
        collectionView?.reloadData()
        collectionView?.invalidateIntrinsicContentSize()
    }

    func changeState(_ state: ReaderTopicCollectionViewState) {
        guard let layout = collectionView?.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.isExpanded = state == .expanded
    }

    private func configure(_ collectionView: UICollectionView) {
        collectionView.isAccessibilityElement = false
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.contentInset = .zero

        let nib = UINib(nibName: String(describing: ReaderInterestsCollectionViewCell.self), bundle: nil)

        // Register the main cell
        collectionView.register(nib, forCellWithReuseIdentifier: Constants.reuseIdentifier)

        // Register the overflow item type
        collectionView.register(nib, forSupplementaryViewOfKind: ReaderInterestsCollectionViewFlowLayout.overflowItemKind, withReuseIdentifier: Constants.overflowReuseIdentifier)

        // Configure Layout
        guard let layout = collectionView.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.delegate = self
        layout.maxNumberOfDisplayedLines = 1
        layout.itemSpacing = metrics.cellSpacing
        layout.cellHeight = metrics.cellHeight
        layout.allowsCentering = false
    }

    private func sizeForCell(title: String, of collectionView: UICollectionView) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: ReaderInterestsStyleGuide.compactCellLabelTitleFont
        ]

        let title: NSString = title as NSString

        var size = title.size(withAttributes: attributes)

        // Prevent 1 token from being too long
        let maxWidth = collectionView.bounds.width * metrics.maxCellWidthMultiplier
        let width = min(size.width, maxWidth)
        size.width = width + (metrics.interestsLabelMargin * 2)

        return size
    }

    private func configure(cell: ReaderInterestsCollectionViewCell, with title: String) {
        ReaderInterestsStyleGuide.applyCompactCellLabelStyle(label: cell.label)

        if metrics.borderWidth > 0 {
            cell.layer.borderColor = metrics.borderColor.cgColor
            cell.layer.borderWidth = metrics.borderWidth
        }

        cell.layer.cornerRadius = metrics.cellCornerRadius
        cell.label.text = title
        cell.label.accessibilityHint = Strings.accessbilityHint
        cell.label.accessibilityTraits = .button
    }

    private func string(for remainingItems: Int?) -> String {
        guard let items = remainingItems else {
            return Strings.collapseButtonTitle
        }

        return "\(items)+"
    }
}

extension ReaderTopicCollectionViewCoordinator: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topics.count
    }
}

extension ReaderTopicCollectionViewCoordinator: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                          for: indexPath) as? ReaderInterestsCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        configure(cell: cell, with: topics[indexPath.row])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let overflowKind = ReaderInterestsCollectionViewFlowLayout.overflowItemKind

        guard
            kind == overflowKind,
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: overflowKind, withReuseIdentifier: Constants.overflowReuseIdentifier, for: indexPath) as? ReaderInterestsCollectionViewCell,
            let layout = collectionView.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout
        else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.overflowReuseIdentifier) with kind: \(overflowKind)")
        }

        let remainingItems = layout.remainingItems
        let title = string(for: remainingItems)

        configure(cell: cell, with: title)

        if layout.isExpanded || RemoteFeatureFlag.readerImprovements.enabled() {
            cell.label.backgroundColor = .clear
        }

        cell.label.accessibilityHint = layout.isExpanded ? Strings.collapseButtonAccessbilityHint : Strings.expandButtonAccessbilityHint

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleExpanded))
        cell.addGestureRecognizer(tapGestureRecognizer)

        return cell
    }

    @objc func toggleExpanded(_ sender: ReaderInterestsCollectionViewCell) {
        guard let layout = collectionView?.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.isExpanded = !layout.isExpanded
        layout.invalidateLayout()

        WPAnalytics.trackReader(.readerChipsMoreToggled)

        delegate?.coordinator(self, didChangeState: layout.isExpanded ? .expanded: .collapsed)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForCell(title: topics[indexPath.row], of: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // We create a remote service because we need to convert the topic to a slug an this contains the
        // code to do that
        let service = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi())
        guard let topic = service.slug(forTopicName: topics[indexPath.row]) else {
            return
        }

        delegate?.coordinator(self, didSelectTopic: topic)
    }
}

extension ReaderTopicCollectionViewCoordinator: ReaderInterestsCollectionViewFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: ReaderInterestsCollectionViewFlowLayout, sizeForOverflowItem at: IndexPath, remainingItems: Int?) -> CGSize {

        let title = string(for: remainingItems)
        return sizeForCell(title: title, of: collectionView)
    }
}
