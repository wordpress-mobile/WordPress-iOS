import Foundation

protocol JetpackErrorViewModel {
    /// The primary icon image
    /// If this is nil the image will be hidden
    var image: UIImage? { get }

    /// The title for the error description
    /// If nil, title will be hidden
    var title: String? { get }

    /// The error description text
    var description: FormattedStringProvider { get }

    /// The title for the first button
    /// If this is nil the button will be hidden
    var primaryButtonTitle: String? { get }

    /// The title for the second button
    /// If this is nil the button will be hidden
    var secondaryButtonTitle: String? { get }

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller secondary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapSecondaryButton(in viewController: UIViewController?)
}

/// Helper struct to define a type as both a regular string and an attributed one
struct FormattedStringProvider {
    let stringValue: String
    let attributedStringValue: NSAttributedString?

    init(string: String) {
        stringValue = string
        attributedStringValue = nil
    }

    init(attributedString: NSAttributedString) {
        attributedStringValue = attributedString
        stringValue = attributedString.string
    }
}
