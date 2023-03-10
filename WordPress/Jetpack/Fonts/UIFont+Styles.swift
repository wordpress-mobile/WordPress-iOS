import UIKit

extension UIFont {

    static let current: FontStyles = {
        return .init(prominent: UIFont.prominentFont(style:weight:))
    }()

    private static func prominentFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.fontForTextStyle(style, fontWeight: weight)
    }
}
