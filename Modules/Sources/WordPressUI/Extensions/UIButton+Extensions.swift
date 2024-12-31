import UIKit

extension UIButton.Configuration {
    public static func primary() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.titleTextAttributesTransformer = .init { attributes in
            var attributes = attributes
            attributes.font = UIFont.preferredFont(forTextStyle: .headline)
            return attributes
        }
        configuration.buttonSize = .large
        return configuration
    }
}
