import Foundation
import WordPressShared.WPStyleGuide

public class ReaderGapMarkerCell: UITableViewCell
{
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var tearBackgroundView: UIView!
    @IBOutlet private weak var tearMaskView: UIView!
    @IBOutlet private weak var activityViewBackgroundView: UIView!
    @IBOutlet private weak var activityView: UIActivityIndicatorView!
    @IBOutlet private weak var button:UIButton!

    public override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        // Background styles
        selectedBackgroundView = UIView(frame: innerContentView.frame)
        selectedBackgroundView?.backgroundColor = WPStyleGuide.greyLighten30()
        innerContentView.backgroundColor = WPStyleGuide.greyLighten30()
        tearMaskView.backgroundColor = WPStyleGuide.greyLighten30()

        // Draw the tear
        drawTearBackground()

        activityViewBackgroundView.backgroundColor = WPStyleGuide.greyDarken10()
        activityViewBackgroundView.layer.cornerRadius = 4.0
        activityViewBackgroundView.layer.masksToBounds = true

        // Button style
        let text = NSLocalizedString("Load more posts", comment: "A short label.  A call to action to load more posts.")
        button.setTitle(text, forState: .Normal)
        WPStyleGuide.applyGapMarkerButtonStyle(button)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.sizeToFit()

        // Disable button interactions so the full cell handles the tap.
        button.userInteractionEnabled = false
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
        if (highlighted) {
            // Redraw the backgrounds when highlighted
            drawTearBackground()
            tearMaskView.backgroundColor = WPStyleGuide.greyLighten30()
        }
    }

    func drawTearBackground() {
        let tearImage = UIImage(named: "background-reader-tear")
        tearBackgroundView.backgroundColor = UIColor(patternImage: tearImage!)
    }
}
