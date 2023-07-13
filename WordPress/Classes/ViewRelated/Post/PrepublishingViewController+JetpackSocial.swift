/// Encapsulates logic related to Jetpack Social in the pre-publishing sheet.
///
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
        if hasExistingConnections {
            configureAutoSharingView(for: cell)
        } else {
            configureNoConnectionView(for: cell)
        }
    }
}

// MARK: - Helper Methods

private extension PrepublishingViewController {

    var hasExistingConnections: Bool {
        coreDataStack.performQuery { [postObjectID = post.objectID] context in
            guard let post = (try? context.existingObject(with: postObjectID)) as? Post,
                  let connections = post.blog.connections as? Set<PublicizeConnection> else {
                return false
            }
            return !connections.isEmpty
        }
    }

    // MARK: Auto Sharing View

    func configureAutoSharingView(for cell: UITableViewCell) {
        let viewModel = makeAutoSharingViewModel()
        let viewToEmbed = UIView.embedSwiftUIView(PrepublishingAutoSharingView(model: viewModel))
        cell.contentView.addSubview(viewToEmbed)

        // Pin constraints to the cell's layoutMarginsGuide so that the content is properly aligned.
        NSLayoutConstraint.activate([
            viewToEmbed.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            viewToEmbed.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
            viewToEmbed.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor),
            viewToEmbed.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
        ])

        cell.accessoryType = .disclosureIndicator
    }

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

    // MARK: - No Connection View

    func configureNoConnectionView(for cell: UITableViewCell) {
        let viewModel = makeNoConnectionViewModel()
        guard let viewToEmbed = JetpackSocialNoConnectionView.createHostController(with: viewModel).view else {
            return
        }

        cell.contentView.addSubview(viewToEmbed)
        cell.contentView.pinSubviewToSafeArea(viewToEmbed)
    }

    func makeNoConnectionView() -> UIView {
        let viewModel = makeNoConnectionViewModel()
        let controller = JetpackSocialNoConnectionView.createHostController(with: viewModel)
        return controller.view
    }

    func makeNoConnectionViewModel() -> JetpackSocialNoConnectionViewModel {
        let context = post.managedObjectContext ?? coreDataStack.mainContext
        guard let services = try? PublicizeService.allSupportedServices(in: context) else {
            return .init()
        }

        // TODO: Tap actions
        return .init(services: services, preferredBackgroundColor: tableView.backgroundColor)
    }
}
