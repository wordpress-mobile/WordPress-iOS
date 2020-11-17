import Foundation

/// This is a temporary protocol to make the migration from `BlogDetailHeaderView` to `NewBlogDetailHeaderView` easier.
/// The idea behind this protocol is to make it possible to feature flag the transition.
/// We will remove this protocol once the migration is complete.
///
@objc
protocol BlogDetailHeader: NSObjectProtocol {

    @objc
    var asView: UIView { get }

    @objc
    var blog: Blog? { get set }

    @objc
    weak var delegate: BlogDetailHeaderViewDelegate? { get set }

    @objc
    var updatingIcon: Bool { get set }

    @objc
    var blavatarImageView: UIImageView { get }

    @objc
    func refreshIconImage()

    @objc
    func refreshSiteTitle()

    @objc
    func toggleSpotlightOnSiteTitle()

    @objc
    func toggleSpotlightOnSiteIcon()
}
