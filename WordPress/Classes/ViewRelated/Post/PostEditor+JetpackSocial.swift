import WordPressData

extension PostEditor {

    func disableSocialConnectionsIfNecessary() {
        let connections = self.post.blog.sortedConnections
        guard RemoteFeatureFlag.jetpackSocialImprovements.enabled(),
              let post = self.post as? Post,
              let remainingShares = self.post.blog.sharingLimit?.remaining,
              remainingShares < connections.count else {
            return
        }
        for connection in connections {
            post.disablePublicizeConnectionWithKeyringID(connection.keyringConnectionID)
        }
    }
}
