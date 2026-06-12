import UIKit
import WordPressShared
import WordPressUI

extension UIButton.Configuration {
    /// Replicates the legacy WordPressAuthenticator `NUXButton` primary style
    /// so screens converted off the library keep rendering identically:
    /// corner radius 8, content insets (12, 20, 12, 20), medium-weight title3
    /// font. All state colors, including the normal state, are owned by the
    /// update handler installed by `configureAsPrimaryNUXButton()`; apply via
    /// that method, never directly.
    fileprivate static func primaryNUX() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = WPStyleGuide.mediumWeightFont(forStyle: .title3)
            return attributes
        }
        return configuration
    }
}

extension UIButton {
    static func makePrimaryNUXButton() -> UIButton {
        let button = UIButton()
        button.configureAsPrimaryNUXButton()
        return button
    }

    /// Applies the `primaryNUX` configuration plus the state-dependent colors
    /// the legacy `NUXButton` rendered (highlighted and disabled backgrounds),
    /// which a static configuration cannot express.
    func configureAsPrimaryNUXButton() {
        configuration = .primaryNUX()
        configurationUpdateHandler = { button in
            guard var configuration = button.configuration else {
                return
            }
            if button.state.contains(.highlighted) {
                configuration.baseBackgroundColor = UIAppColor.primary(.shade80)
                configuration.baseForegroundColor = .white
            } else if button.state.contains(.disabled) {
                configuration.baseBackgroundColor = .secondarySystemFill
                configuration.baseForegroundColor = UIAppColor.neutral(.shade20)
            } else {
                configuration.baseBackgroundColor = UIAppColor.primary
                configuration.baseForegroundColor = .white
            }
            button.configuration = configuration
        }
    }

    /// Mirrors the legacy `NUXButton.showActivityIndicator(_:)`: the spinner is
    /// shown centered in place of the title. Showing the indicator clears the
    /// configuration title (which may shrink the button to its intrinsic spinner
    /// size) but keeps the title as the accessibility label; callers must set
    /// the title again after hiding the indicator.
    func setActivityIndicatorVisible(_ visible: Bool) {
        guard var configuration else {
            return
        }
        configuration.showsActivityIndicator = visible
        if visible {
            accessibilityLabel = configuration.title
            configuration.title = nil
        } else {
            accessibilityLabel = nil
        }
        self.configuration = configuration
    }
}

extension UIButton {
    /// Creates a bar button item that looks like the native title menu
    /// (see `navigationItem.titleMenuProvider`, iOS 16+).
    static func makeMenu(title: String, menu: UIMenu) -> UIButton {
        let button = makeMenuButton(title: title)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        return button
    }

    /// Creates a bar button item that looks like the native title menu
    /// (see `navigationItem.titleMenuProvider`, iOS 16+).
    static func makeMenuButton(title: String) -> UIButton {
        UIButton(
            configuration: {
                var configuration = UIButton.Configuration.plain()
                configuration.title = title
                configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
                    var attributes = $0
                    attributes.font = AppStyleGuide.current.navigationBarStandardFont
                    return attributes
                }
                configuration.image = UIImage(systemName: "chevron.down.circle.fill")?.withBaselineOffset(fromBottom: 4)
                configuration.preferredSymbolConfigurationForImage =
                    UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
                    .applying(
                        UIImage.SymbolConfiguration(
                            font: WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
                        )
                    )
                configuration.imagePlacement = .trailing
                configuration.imagePadding = 4
                configuration.baseForegroundColor = .label
                return configuration
            }()
        )
    }
}
