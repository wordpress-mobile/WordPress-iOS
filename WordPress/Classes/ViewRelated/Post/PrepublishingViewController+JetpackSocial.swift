extension PrepublishingViewController {

    /// Determines whether the account and the post's blog is eligible to see auto-sharing options.
    func isEligibleForAutoSharing(isJetpack: Bool = AppConfiguration.isJetpack,
                                  isFeatureEnabled: Bool = FeatureFlag.jetpackSocial.enabled) -> Bool {
        let blogSupportsPublicize = coreDataStack.performQuery { [postObjectID = post.objectID] context in
            let post = (try? context.existingObject(with: postObjectID)) as? Post
            return post?.blog.supportsPublicize() ?? false
        }

        return blogSupportsPublicize && isJetpack && isFeatureEnabled
    }

    func configureSocialCell(_ cell: UITableViewCell) {
        // TODO:
        // - Show the NoConnectionView if user has 0 connections.
        let autoSharingView = UIView.embedSwiftUIView(PrepublishingAutoSharingView(model: makeAutoSharingViewModel()))
        cell.contentView.addSubview(autoSharingView)

        // Pin constraints to the cell's layoutMarginsGuide so that the content is properly aligned.
        NSLayoutConstraint.activate([
            autoSharingView.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            autoSharingView.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
            autoSharingView.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor),
            autoSharingView.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
        ])
        cell.accessoryType = .disclosureIndicator // TODO: only for autoSharingView.
    }
}

// MARK: - Helper Methods

private extension PrepublishingViewController {

    func makeAutoSharingViewModel() -> PrepublishingAutoSharingViewModel {
        return coreDataStack.performQuery { [postObjectID = post.objectID] context in
            guard let post = (try? context.existingObject(with: postObjectID)) as? Post,
                  let connections = post.blog.sortedConnections as? [PublicizeConnection],
                  let supportedServices = try? PublicizeService.allSupportedServices(in: context) else {
                return .init(services: [], sharingLimit: nil)
            }

            // first, build a dictionary to categorize the connections.
            var connectionsMap = [PublicizeService.ServiceName: [PublicizeConnection]]()
            connections.forEach { connection in
                let serviceName = PublicizeService.ServiceName(rawValue: connection.service) ?? .unknown
                var serviceConnections = connectionsMap[serviceName] ?? []
                serviceConnections.append(connection)
                connectionsMap[serviceName] = serviceConnections
            }

            // then, transform [PublicizeService] to [PrepublishingAutoSharingViewModel.Service].
            let modelServices = supportedServices.compactMap { service -> PrepublishingAutoSharingViewModel.Service? in
                // skip services without connections.
                guard let serviceConnections = connectionsMap[service.name],
                      !serviceConnections.isEmpty else {
                    return nil
                }

                return PrepublishingAutoSharingViewModel.Service(
                    serviceName: service.name,
                    connections: serviceConnections.map {
                        .init(account: $0.externalDisplay,
                              enabled: !post.publicizeConnectionDisabledForKeyringID($0.keyringConnectionID))
                    }
                )
            }

            return .init(services: modelServices, sharingLimit: post.blog.sharingLimit)
        }
    }

}
