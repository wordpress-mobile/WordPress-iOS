import UIKit
import WordPressAuthenticator


/// The colors in here intentionally do not support light or dark modes since they're the same on both.
///
struct JetpackPrologueStyleGuide {
    static let backgroundColor = UIColor(red: 0.00, green: 0.11, blue: 0.18, alpha: 1.00)

    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        static let textColor: UIColor = .white
    }

    struct Stars {
        static let particleImage = UIImage(named: "circle-particle")

        static let colors = [
            UIColor(red: 0.05, green: 0.27, blue: 0.44, alpha: 1.00),
            UIColor(red: 0.64, green: 0.68, blue: 0.71, alpha: 1.00),
            UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.00)
        ]
    }

    static let continueButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: .white,
                                                                 borderColor: .white,
                                                                 titleColor: Self.backgroundColor),

                                                   highlighted: .init(backgroundColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90),
                                                                      titleColor: Self.backgroundColor),

                                                   disabled: .init(backgroundColor: .white,
                                                                   borderColor: .white,
                                                                   titleColor: Self.backgroundColor))

    static let siteAddressButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: Self.backgroundColor,
                                                                   borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.40),
                                                                   titleColor: .white),

                                                     highlighted: .init(backgroundColor: Self.backgroundColor,
                                                                        borderColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20),
                                                                        titleColor: UIColor.white.withAlphaComponent(0.7)),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: Self.backgroundColor))

}
