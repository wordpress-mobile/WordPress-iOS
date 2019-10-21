import UIKit
import Gridicons

struct PluginDirectoryAccessoryItem {

    static func accessoryView(plugin: PluginDirectoryEntry) -> UIView {
        return PluginDirectoryAccessoryItem.stars(count: plugin.starRating)
    }

    static func accessoryView(pluginState: PluginState) -> UIView {
        guard !pluginState.automanaged else {
            return PluginDirectoryAccessoryItem.automanaged()
        }

        guard pluginState.active else {
            return PluginDirectoryAccessoryItem.inactive()
        }

        switch pluginState.updateState {
        case .available:
            return PluginDirectoryAccessoryItem.needsUpdate()
        case .updating:
            return PluginDirectoryAccessoryItem.updating()
        case .updated:
            return PluginDirectoryAccessoryItem.active()
        }
    }

    private static func automanaged() -> UIView {
        let color = UIColor.neutral(.shade40)
        let text = NSLocalizedString("Auto-managed", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryItem.label(with: nil, tintColor: color, text: text)
    }

    private static func active() -> UIView {
        let icon = Gridicon.iconOfType(.checkmark, withSize: Constants.imageSize)
        let color = UIColor.success
        let text = NSLocalizedString("Active", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryItem.label(with: icon, tintColor: color, text: text)
    }

    private static func inactive() -> UIView {
        let icon = Gridicon.iconOfType(.cross, withSize: Constants.imageSize)
        let color = UIColor.neutral(.shade40)
        let text = NSLocalizedString("Inactive", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryItem.label(with: icon, tintColor: color, text: text)
    }

    private static func needsUpdate() -> UIView {
        let icon = Gridicon.iconOfType(.sync, withSize: Constants.imageSize)
        let color = UIColor.warning
        let text = NSLocalizedString("Needs Update", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryItem.label(with: icon, tintColor: color, text: text)
    }

    private static func updating() -> UIView {
        let icon = Gridicon.iconOfType(.sync, withSize: Constants.imageSize)
        let color = UIColor.warning
        let text = NSLocalizedString("Updating", comment: "Describes a status of a plugin")

        return PluginDirectoryAccessoryItem.label(with: icon, tintColor: color, text: text)
    }

    private static func label(with icon: UIImage?, tintColor: UIColor, text: String) -> UIView {
        let container = UIStackView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: icon)
        imageView.tintColor = tintColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = .textSubtle
        label.text = text

        container.axis = .horizontal
        container.distribution = .fillProportionally
        container.spacing = Constants.trailingSpacing

        if icon == nil {
            imageView.isHidden = true
        }

        container.addArrangedSubview(imageView)
        container.addArrangedSubview(label)

        return container
    }

    private static func stars(count: Double) -> UIView {
        let spacing: CGFloat = 0

        let totalWidth = (Constants.starImageSize.width * CGFloat(Constants.totalStarsCount)) + (spacing * (CGFloat(Constants.totalStarsCount) - 1))

        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = spacing

        container.addSubview(stackView)

        stackView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        let (wholeStars, half) = modf(count)

        for i in 1...Constants.totalStarsCount {

            if i == Int(wholeStars) + 1, half > 0 {
                // if this is the next iteration after the last "whole" star, and `half` is > 0, add a half-star.
                stackView.addArrangedSubview(PluginDirectoryAccessoryItem.halfStar(size: Constants.starImageSize))
                continue
            }

            let image: UIImage
            let color: UIColor

            if i <= Int(wholeStars) {
                image = Gridicon.iconOfType(.star, withSize: Constants.starImageSize)
                color = .primary(.shade40)
            } else {
                image = Gridicon.iconOfType(.starOutline, withSize: Constants.starImageSize)
                color = .neutral(.shade10)
            }

            let imageView = UIImageView(image: image)
            imageView.tintColor = color

            stackView.addArrangedSubview(imageView)
        }

        return container
    }

    private static func halfStar(size: CGSize) -> UIView {
        let color = UIColor.primary(.shade40)

        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: size.height),
            container.widthAnchor.constraint(equalToConstant: size.width)
        ])

        let leftHalf = UIImageView(image: Gridicon.iconOfType(.star, withSize: size))
        leftHalf.tintColor = color
        leftHalf.translatesAutoresizingMaskIntoConstraints = false
        leftHalf.contentMode = .left
        leftHalf.clipsToBounds = true
        leftHalf.setContentHuggingPriority(.required, for: .vertical)
        leftHalf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leftHalf.addConstraint(NSLayoutConstraint(item: leftHalf, attribute: .width, relatedBy: .equal, toItem: leftHalf, attribute: .height, multiplier: 0.5, constant: 0))

        let rightHalf = UIImageView(image: Gridicon.iconOfType(.starOutline, withSize: size))
        rightHalf.tintColor = .neutral(.shade10)
        rightHalf.translatesAutoresizingMaskIntoConstraints = false
        rightHalf.contentMode = .right
        rightHalf.clipsToBounds = true
        rightHalf.setContentHuggingPriority(.required, for: .vertical)
        rightHalf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rightHalf.addConstraint(NSLayoutConstraint(item: rightHalf, attribute: .width, relatedBy: .equal, toItem: rightHalf, attribute: .height, multiplier: 0.5, constant: 0))

        container.addSubview(leftHalf)
        container.addSubview(rightHalf)

        leftHalf.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        leftHalf.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        leftHalf.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        leftHalf.trailingAnchor.constraint(equalTo: rightHalf.leadingAnchor).isActive = true
        rightHalf.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        rightHalf.centerYAnchor.constraint(equalTo: leftHalf.centerYAnchor).isActive = true

        return container
    }

    private enum Constants {
        static var totalStarsCount = 5
        static var imageSize = CGSize(width: 14, height: 14)
        static var starImageSize = CGSize(width: 12, height: 12)
        static var trailingSpacing: CGFloat = 4

    }
}
