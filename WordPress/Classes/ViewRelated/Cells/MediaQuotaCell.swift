import Foundation
import UIKit
import WordPressShared

// MARK: - View Model

@objc class MediaQuotaCell: WPTableViewCell {

    @objc static let height: Float = 66.0

    @objc static let defaultReuseIdentifier = "MediaQuotaCell"

    @objc static let nib: UINib = {
        let nib = UINib(nibName: "MediaQuotaCell", bundle: Bundle(for: MediaQuotaCell.self))
        return nib
    }()

    // MARK: - Public interface
    @objc var value: String? {
        get {
            return valueLabel.text
        }
        set {
            valueLabel.text = newValue
        }
    }

    @objc var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    @objc var percentage: NSNumber? {
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

    @objc func customizeAppearance() {
        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = .neutral(.shade70)
        valueLabel.font = WPStyleGuide.tableviewSubtitleFont()
        valueLabel.textColor = .neutral(.shade30)
        progressView.progressTintColor = .primary
        progressView.trackTintColor = .neutral(.shade30)
    }

    // MARK: - UIKit bindings
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeAppearance()
    }

    @objc @IBOutlet var titleLabel: UILabel!
    @objc @IBOutlet var valueLabel: UILabel!
    @objc @IBOutlet var progressView: UIProgressView!
}
