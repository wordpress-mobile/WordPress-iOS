/// A view with side-by-side label and button, intended to be displayed as an overlay on top of `ListTableViewCell`.
///
class ListSimpleOverlayView: UIView, NibLoadable {
    // MARK: IBOutlets
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
}
