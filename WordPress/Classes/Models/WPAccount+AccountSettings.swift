import Foundation

extension WPAccount {
    func applyChange(change: AccountSettingsChange) {
        switch change {
        case .DisplayName(let value):
            self.displayName = value
        default:
            break
        }
    }
}
