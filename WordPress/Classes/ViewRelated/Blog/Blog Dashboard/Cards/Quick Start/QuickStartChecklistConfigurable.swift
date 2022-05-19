import Foundation

typealias QuickStartChecklistConfigurableView = UIView & QuickStartChecklistConfigurable

protocol QuickStartChecklistConfigurable {
    var tours: [QuickStartTour] { get }
    var blog: Blog? { get }
    var onTap: (() -> Void)? { get set }

    func configure(collection: QuickStartToursCollection, blog: Blog)
}
