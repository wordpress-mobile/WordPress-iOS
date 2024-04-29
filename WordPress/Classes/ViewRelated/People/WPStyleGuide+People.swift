import Foundation
import DesignSystem

extension WPStyleGuide {
    struct People {
        struct RoleBadge {
            // MARK: Metrics
            static let horizontalPadding: CGFloat = .DS.Padding.single
            static let verticalPadding: CGFloat = .DS.Padding.half
            static let cornerRadius: CGFloat = .DS.Radius.small

            // MARK: Typography
            static var font: UIFont {
                return .DS.font(.footnote)
            }
        }

        // MARK: Colors
        struct Color {
            struct Admin {
                static let background: UIColor = .DS.Foreground.primary
                static let text: UIColor = .DS.Background.primary
            }

            struct Other {
                static let background: UIColor = .DS.Background.secondary
                static let text: UIColor = .DS.Foreground.primary
            }
        }
    }
}
