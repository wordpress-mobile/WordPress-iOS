import Foundation
import UIKit
import WordPressShared
import WordPressUI

// MARK: - View Model

protocol MediaSizeModel {
    var value: Int { get set }
    var minValue: Int { get set }
    var maxValue: Int { get set }
    var step: Int { get set }
    var valueText: String { get }
    var accessibleText: String { get }
    var sliderValue: Float { get }
    var sliderMinimumValue: Float { get }
    var sliderMaximumValue: Float { get }
}

class MediaSizeSliderCell: UITableViewCell {

    // MARK: - Public interface
    @objc var value: Int {
        get {
            model.value
        }
        set {
            model.value = newValue
        }
    }

    @objc var minValue: Int {
        get {
            model.minValue
        }
        set {
            model.minValue = newValue
        }
    }

    @objc var maxValue: Int {
        get {
            model.maxValue
        }
        set {
            model.maxValue = newValue
        }
    }

    @objc var step: Int {
        get {
            model.step
        }
        set {
            model.step = newValue
        }
    }

    @objc var title: String? {
        get {
            titleLabel.text
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
        titleLabel.textColor = UIAppColor.neutral(.shade70)
        valueLabel.font = .preferredFont(forTextStyle: .callout)
        valueLabel.textColor = .secondaryLabel
    }

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, slider, valueLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isOpaque = false
        stackView.axis = .vertical

        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            slider.heightAnchor.constraint(equalToConstant: 30),
            valueLabel.topAnchor.constraint(equalTo: slider.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 11)
        ])

        customizeAppearance()
        updateSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let titleLabel: UILabel = {
        let label = makeLabel(textAlignment: .left)
        label.numberOfLines = 0
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }()
    let valueLabel: UILabel = {
        let label = makeLabel(textAlignment: .center)
        label.isAccessibilityElement = false
        return label
    }()
    let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.contentHorizontalAlignment = .center
        slider.contentVerticalAlignment = .center
        slider.value = 1
        return slider
    }()

    private static func makeLabel(textAlignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.backgroundColor = nil
        label.contentMode = .left
        label.textAlignment = textAlignment
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        return label
    }

    @objc func sliderChanged(_ sender: UISlider) {
        model.value = Int(sender.value)
        onChange?(model.value)
    }
}

struct ImageSizeModel: MediaSizeModel {
    var value: Int {
        didSet {
            if step > 1 {
                value =
                    value
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
            return NSLocalizedString(
                "Original",
                comment: "Indicates an image will use its original size when uploaded."
            )
        }
        let format = NSLocalizedString(
            "mediaSizeSlider.valueFormat",
            value: "%d × %d px",
            comment: "Max image size in pixels (e.g. 300x300px)"
        )
        return String(format: format, value, value)
    }

    var accessibleText: String {
        if value == maxValue {
            return NSLocalizedString(
                "Original",
                comment: "Indicates an image will use its original size when uploaded."
            )
        }
        let format = NSLocalizedString("%d pixels", comment: "Sepoken image size in pixels (e.g. 300 pixels)")
        return String(format: format, value)
    }

    var sliderValue: Float {
        Float(value)
    }

    var sliderMinimumValue: Float {
        Float(minValue)
    }

    var sliderMaximumValue: Float {
        Float(maxValue)
    }

    static var `default`: ImageSizeModel {
        get {
            ImageSizeModel(value: 1500, minValue: 300, maxValue: 3000, step: 100)
        }
    }
}
