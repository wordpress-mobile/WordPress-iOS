import Foundation

typealias QuickStartChecklistConfigurableView = UIView & QuickStartChecklistConfigurable

// A protocol to ease the transition from QuickStartChecklistView to NewQuickStartChecklistView.
// This protocol can be deleted once we've fully migrated to NewQuickStartChecklistView.
//
protocol QuickStartChecklistConfigurable {
    var tours: [QuickStartTour] { get }
    var blog: Blog? { get }
    var onTap: (() -> Void)? { get set }

    func configure(collection: QuickStartToursCollection, blog: Blog)
}
