import WordPressData

extension PostEditor {

    // Deprecated: Jetpack Social no longer enforces per-post share limits, and post editing now uses
    // connection_id-keyed PostSocialSharingDraft metadata instead of keyring publicize state.
    func disableSocialConnectionsIfNecessary() {
    }
}
