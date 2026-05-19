import Foundation
import SwiftUI
import UIKit

@MainActor
public final class ManageConnectionsHostingController: UIHostingController<AnyView> {
    private let connectionsService: SiteSocialConnectionsService
    private let authenticator: any SocialOAuthAuthenticator
    private var addCoordinator: AddConnectionCoordinator?

    public init(
        connectionsService: SiteSocialConnectionsService,
        authenticator: any SocialOAuthAuthenticator
    ) {
        self.connectionsService = connectionsService
        self.authenticator = authenticator
        super.init(rootView: AnyView(EmptyView()))

        rootView = AnyView(
            ManageSocialConnectionsView(
                connections: connectionsService,
                onAddConnection: { [weak self] in
                    self?.presentAdd()
                }
            )
        )
    }

    @preconcurrency required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func presentAdd() {
        let coordinator = AddConnectionCoordinator(
            connectionsService: connectionsService,
            authenticator: authenticator,
            presenter: self
        )
        // Strong reference keeps the coordinator alive during the OAuth flow.
        addCoordinator = coordinator
        coordinator.start()
    }
}
