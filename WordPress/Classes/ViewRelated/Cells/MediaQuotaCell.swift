import Foundation
import UIKit
import WordPressShared
import WordPressUI

// MARK: - View Model

@objc public class MediaQuotaCell: WPTableViewCell {

    @objc public static let height: Float = 66.0

    @objc public static let defaultReuseIdentifier = "MediaQuotaCell"

    @objc public static let nib: UINib = {
        let nib = UINib(nibName: "MediaQuotaCell", bundle: Bundle(for: MediaQuotaCell.self))
        return nib
    }()

    // MARK: - Public interface
    @objc public var value: String? {
        get {
            return valueLabel.text
        }
        set {
            valueLabel.text = newValue
        }
    }

    @objc public var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    @objc public var percentage: NSNumber? {
        get {
            return NSNumber(value: progressView.progress)
        }
        set {
            if let nonNilValue = newValue {
                progressView.progress = nonNilValue.floatValue
            } else {
                progressView.progress = 0
            }
        }
    }

    // MARK: - Private properties

    @objc public func customizeAppearance() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label
        valueLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        valueLabel.textColor = .secondaryLabel
        progressView.progressTintColor = UIAppColor.primary
        progressView.trackTintColor = .separator
    }

    // MARK: - UIKit bindings
    public override func awakeFromNib() {
        super.awakeFromNib()
        customizeAppearance()
    }

    @objc @IBOutlet var titleLabel: UILabel!
    @objc @IBOutlet var valueLabel: UILabel!
    @objc @IBOutlet var progressView: UIProgressView!
}
