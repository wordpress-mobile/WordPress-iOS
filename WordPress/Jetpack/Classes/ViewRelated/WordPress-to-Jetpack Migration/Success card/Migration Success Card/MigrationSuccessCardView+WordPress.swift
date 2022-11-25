import Foundation

extension MigrationSuccessCardView {

    @objc static var shouldShowMigrationSuccessCard: Bool {
        // Adding an empty implementation of this variable so Xcode doesn't complain.
        // The whole `shouldShowMigrationSuccessCard` shouldn't exist in WordPress. It's only needed for Jetpack.
        return false
    }
}
