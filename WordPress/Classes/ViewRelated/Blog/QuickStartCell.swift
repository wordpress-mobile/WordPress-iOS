import UIKit

@objc class QuickStartCell: UITableViewCell {

    private lazy var tourStateView: QuickStartTourStateView = {
        let view = QuickStartTourStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @objc func configure(blog: Blog, viewController: BlogDetailsViewController) {
        contentView.addSubview(tourStateView)
        contentView.pinSubviewToAllEdges(tourStateView, insets: Metrics.margins(for: blog.quickStartType))

        selectionStyle = .none

        let checklistTappedTracker: QuickStartChecklistTappedTracker = (event: .quickStartTapped, properties: [:])

        tourStateView.configure(blog: blog,
                                sourceController: viewController,
                                checklistTappedTracker: checklistTappedTracker)
    }

    private enum Metrics {
        static func margins(for quickStartType: QuickStartType) -> UIEdgeInsets {
            switch quickStartType {
            case .undefined:
                return .zero
            case .newSite:
                return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            case .existingSite:
                return UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
            }

        }
    }
}
