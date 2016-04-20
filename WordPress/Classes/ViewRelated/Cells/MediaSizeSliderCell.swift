import Foundation
import UIKit
import WordPressShared

class MediaSizeSliderCell: WPTableViewCell {
    // MARK: - Default values
    struct Default {
        static let value = 1500
        static let minValue = 300
        static let maxValue = 3000
        static let step = 100

        static var model: Model {
            get {
                return Model(value: value, minValue: minValue, maxValue: maxValue, step: step)
            }
        }
    }

    static let height: Float = 108.0

    // MARK: - Public interface
    var value: Int {
        get {
            return model.value
        }
        set {
            model.value = newValue
        }
    }

    var minValue: Int {
        get {
            return model.minValue
        }
        set {
            model.minValue = newValue
        }
    }

    var maxValue: Int {
        get {
            return model.maxValue
        }
        set {
            model.maxValue = newValue
        }
    }

    var step: Int {
        get {
            return model.step
        }
        set {
            model.step = newValue
        }
    }

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var onChange: (Int -> Void)?

    // MARK: - Private properties
    private var model: Model = Default.model {
        didSet {
            updateSubviews()
        }
    }

    func updateSubviews() {
        slider.minimumValue = model.sliderMinimumValue
        slider.maximumValue = model.sliderMaximumValue
        slider.value = model.sliderValue
        slider.accessibilityValue = model.accessibleText
        valueLabel.text = model.valueText
    }

    func customizeAppearance() {
        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = WPStyleGuide.darkGrey()
        valueLabel.font = WPStyleGuide.tableviewSubtitleFont()
        valueLabel.textColor = WPStyleGuide.grey()
    }

    // MARK: - UIKit bindings
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeAppearance()
        updateSubviews()
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet var slider: UISlider!

    @IBAction func sliderChanged(sender: UISlider) {
        model.value = Int(sender.value)
        onChange?(model.value)
    }

    // MARK: - View Model
    struct Model {
        var value: Int {
            didSet {
                if step > 1 {
                    value = value
                        .round(UInt(step))
                        .clamp(min: minValue, max: maxValue)
                }
            }
        }
        var minValue: Int
        var maxValue: Int
        var step: Int

        var valueText: String {
            if value == maxValue {
                return NSLocalizedString("Original", comment: "Indicates an image will use its original size when uploaded.")
            }
            let format = NSLocalizedString("%dx%dpx", comment: "Max image size in pixels (e.g. 300x300px)")
            return String(format: format, value, value)
        }

        var accessibleText: String {
            if value == maxValue {
                return NSLocalizedString("Original", comment: "Indicates an image will use its original size when uploaded.")
            }
            let format = NSLocalizedString("%d pixels", comment: "Sepoken image size in pixels (e.g. 300 pixels)")
            return String(format: format, value)
        }

        var sliderValue: Float {
            return Float(value)
        }

        var sliderMinimumValue: Float {
            return Float(minValue)
        }

        var sliderMaximumValue: Float {
            return Float(maxValue)
        }
    }
}

