import Foundation


public class ReaderGapMarkerCell: UITableViewCell
{
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var button:UIButton!
    @IBOutlet private weak var activityView: UIActivityIndicatorView!

    public override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        // Background styles
        selectedBackgroundView = UIView(frame: innerContentView.frame)
        selectedBackgroundView?.backgroundColor = WPStyleGuide.greyLighten30()
        innerContentView.backgroundColor = WPStyleGuide.greyLighten30()

        // Button style
        // Disable button interactions so the full cell handles the tap.
        button.userInteractionEnabled = false
        let text = NSLocalizedString("Load More Posts", comment: "A short label.  A call to action to load more posts.")
        button.setTitle(text, forState: .Normal)
        WPStyleGuide.applyGapMarkerButtonStyle(button)
        button.sizeToFit()
    }

    public func animateActivityView(animate:Bool) {
        button.hidden = animate;
        if animate {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
    }

    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        button.highlighted = highlighted
    }
}