import Foundation

extension Blog {
    /// If the blog should show the "Jetpack" or the "General" section
    @objc var shouldShowJetpackSection: Bool {
        (supports(.activity) && !isWPForTeams()) || supports(.jetpackSettings)
    }
}
