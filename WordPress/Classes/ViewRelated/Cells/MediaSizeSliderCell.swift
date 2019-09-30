import Foundation
import UIKit
import WordPressShared

// MARK: - View Model

protocol MediaSizeModel {
    var value: Int {get set}
    var minValue: Int {get set}
    var maxValue: Int {get set}
    var step: Int {get set}
    var valueText: String {get}
    var accessibleText: String {get}
    var sliderValue: Float {get}
    var sliderMinimumValue: Float {get}
    var sliderMaximumValue: Float {get}
}

class MediaSizeSliderCell: WPTableViewCell {

    // MARK: - Public interface
    @objc var value: Int {
        get {
            return model.value
        }
        set {
            model.value = newValue
        }
    }

    @objc var minValue: Int {
        get {
            return model.minValue
        }
        set {
            model.minValue = newValue
        }
    }

    @objc var maxValue: Int {
        get {
            return model.maxValue
        }
        set {
            model.maxValue = newValue
        }
    }

    @objc var step: Int {
        get {
            return model.step
        }
        set {
            model.step = newValue
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

    @objc var onChange: ((Int) -> Void)?

    // MARK: - Private properties
    var model: MediaSizeModel = ImageSizeModel.default {
        didSet {
            updateSubviews()
        }
    }

    @objc func updateSubviews() {
        slider.minimumValue = model.sliderMinimumValue
        slider.maximumValue = model.sliderMaximumValue
        slider.value = model.sliderValue
        slider.accessibilityValue = model.accessibleText
        valueLabel.text = model.valueText
    }

    @objc func customizeAppearance() {
        titleLabel.font = WPStyleGuide.tableviewTextFont()
        titleLabel.textColor = .neutral(.shade70)
        valueLabel.font = WPStyleGuide.tableviewSubtitleFont()
        valueLabel.textColor = .neutral(.shade30)
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

    @IBAction func sliderChanged(_ sender: UISlider) {
        model.value = Int(sender.value)
        onChange?(model.value)
    }

}

struct ImageSizeModel: MediaSizeModel {
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

    static var `default`: ImageSizeModel {
        get {
            return ImageSizeModel(value: 1500, minValue: 300, maxValue: 3000, step: 100)
        }
    }
}
