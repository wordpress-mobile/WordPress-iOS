import Foundation
import UIKit

// MARK: - GhostStyle: Ghost Animation Preferences.
//
public struct GhostStyle {

    /// Default Style
    ///
    public static let `default` = GhostStyle()

    /// Default Animation Duration.
    ///
    let beatDuration: TimeInterval

    /// Beat Initial Color: Applied at the beginning of the Beat Animation.
    ///
    let beatStartColor: UIColor

    /// Beat Final Color: Applied at the end of the Beat Animation.
    ///
    let beatEndColor: UIColor

    /// Designated Initializer
    ///
    public init(beatDuration: TimeInterval = Defaults.beatDuration,
                beatStartColor: UIColor = Defaults.beatStartColor,
                beatEndColor: UIColor = Defaults.beatEndColor) {
        self.beatDuration = beatDuration
        self.beatStartColor = beatStartColor
        self.beatEndColor = beatEndColor
    }
}

// MARK: - Nested Types
//
extension GhostStyle {

    public struct Defaults {
        public static let beatDuration = TimeInterval(0.75)
        public static let beatStartColor = UIColor(red: 236.0/255.0, green: 240.0/255.0, blue: 241.0/255.0, alpha: 1.0)
        public static let beatEndColor = UIColor(red: 245.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    }
}
