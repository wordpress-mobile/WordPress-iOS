import Foundation


public class ReaderGapMarkerCell: UITableViewCell
{
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var activityView: UIActivityIndicatorView!

    public override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        innerContentView.backgroundColor = WPStyleGuide.greyLighten30()
        label.backgroundColor = WPStyleGuide.greyLighten30()

        label.text = NSLocalizedString("Show more Posts", comment: "A short label.  A call to action to load more posts.")
        WPStyleGuide.applyGapMarkerFontStyle(label)
    }

    public func animateActivityView(animate:Bool) {
        label.hidden = animate;
        if animate {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
    }
}