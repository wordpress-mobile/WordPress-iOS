import Foundation
import WordPressData

extension Blog {
    /// Determines if this blog requires an application password for editor features
    /// - Returns: true if application password is required but not yet configured
    func requiresApplicationPasswordForEditor() -> Bool {
        // Only require application password for non-WPCOM Simple sites (self-hosted sites)
        guard !isHostedAtWPcom && !isAtomic() else {
            return false
        }

        // Check if application password already exists
        let hasApplicationPassword = (try? getApplicationToken()) != nil
        return !hasApplicationPassword
    }
}
