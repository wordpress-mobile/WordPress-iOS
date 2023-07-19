
extension PostEditor {

    func disableSocialConnectionsIfNecessary() {
        guard FeatureFlag.jetpackSocial.enabled,
              let post = self.post as? Post,
              let remainingShares = self.post.blog.sharingLimit?.remaining,
              let connections = self.post.blog.sortedConnections as? [PublicizeConnection],
              remainingShares < connections.count else {
            return
        }

        for connection in connections {
            post.disablePublicizeConnectionWithKeyringID(connection.keyringConnectionID)
        }
    }

}
