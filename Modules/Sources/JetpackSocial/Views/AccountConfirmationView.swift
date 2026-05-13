import AsyncImageKit
import SwiftUI

public struct AccountConfirmationView: View {
    private let service: SocialService
    @ObservedObject private var connectionsService: SiteSocialConnectionsService
    private let onCancel: () -> Void
    private let onFinish: (Result<SocialConnection, SocialSharingError>) -> Void

    @State private var state: LoadingState = .loading
    @State private var connectedExternalIDs: Set<String> = []
    @State private var selectedAccountID: String?
    @State private var sharedEnabled: Bool = true
    @State private var submitting: Bool = false
    @State private var submitTask: Task<Void, Never>?

    public init(
        service: SocialService,
        connectionsService: SiteSocialConnectionsService,
        onCancel: @escaping () -> Void,
        onFinish: @escaping (Result<SocialConnection, SocialSharingError>) -> Void
    ) {
        self.service = service
        self.connectionsService = connectionsService
        _sharedEnabled = State(initialValue: connectionsService.canMarkAsShared)
        self.onCancel = onCancel
        self.onFinish = onFinish
    }

    public var body: some View {
        Form {
            switch state {
            case .loading:
                loadingSection
            case .loaded(let accounts):
                loadedSections(accounts: accounts)
            case .failed(let error):
                failureSection(error: error)
            }
        }
        .disabled(submitting)
        .overlay {
            if submitting {
                ZStack {
                    Color(.systemBackground).opacity(0.7)
                    ProgressView()
                        .controlSize(.large)
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle(Strings.AccountConfirmation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .cancel, action: cancel)
                } else {
                    Button(role: .cancel, action: cancel) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        state = .loading
        do {
            let siteConnections = try await connectionsService.loadConnections()
            connectedExternalIDs = Set(
                siteConnections
                    .filter { $0.serviceName == service.id }
                    .map(\.externalID)
            )
            let keyrings = try await connectionsService.fetchKeyringConnections()
            let matching = keyrings.filter { $0.service == service.id }
            if matching.isEmpty {
                state = .failed(.noKeyringForService(serviceLabel: service.label))
                return
            }
            let accounts = SocialKeyringAccount.flatten(
                matching,
                includesPrimary: !service.additionalUsersOnly
            )
            if accounts.isEmpty {
                // Most commonly hit by Facebook when the user has no Pages —
                // Publicize won't post to a personal profile, so there's no
                // usable account to pick.
                state = .failed(emptyAccountsError(for: service))
                return
            }
            state = .loaded(accounts)
            if selectedAccountID == nil {
                selectedAccountID =
                    accounts.first {
                        !connectedExternalIDs.contains($0.externalIDForMatching)
                    }?
                    .id
            }
        } catch {
            state = .failed(error)
        }
    }

    @MainActor
    private func submit(account: SocialKeyringAccount) {
        submitting = true
        submitTask = Task {
            let result: Result<SocialConnection, SocialSharingError>
            do throws(SocialSharingError) {
                let connection = try await connectionsService.createConnection(
                    keyringID: account.keyring.id,
                    externalUserID: account.externalUserID,
                    shared: connectionsService.canMarkAsShared ? sharedEnabled : nil
                )
                result = .success(connection)
            } catch {
                result = .failure(error)
            }
            guard !Task.isCancelled else { return }
            submitting = false
            onFinish(result)
        }
    }

    @MainActor
    private func cancel() {
        submitTask?.cancel()
        onCancel()
    }

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView(Strings.AccountConfirmation.loadingMessage)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func loadedSections(accounts: [SocialKeyringAccount]) -> some View {
        let connectable = accounts.filter { !connectedExternalIDs.contains($0.externalIDForMatching) }
        let connected = accounts.filter { connectedExternalIDs.contains($0.externalIDForMatching) }

        Section {
            Text(
                connectable.isEmpty
                    ? Strings.AccountConfirmation.allConnectedDescription
                    : Strings.AccountConfirmation.description
            )
            .foregroundStyle(.primary)
            ForEach(connectable) { account in
                Button {
                    selectedAccountID = account.id
                } label: {
                    AccountSelectableRow(
                        account: account,
                        isSelected: selectedAccountID == account.id
                    )
                }
                .buttonStyle(.plain)
            }
        }

        if !connected.isEmpty {
            Section(Strings.AccountConfirmation.connectedSectionTitle) {
                ForEach(connected) { account in
                    AccountInfoRow(account: account)
                }
            }
        }

        if !connectable.isEmpty {
            if connectionsService.canMarkAsShared {
                Section {
                    Toggle(Strings.AccountConfirmation.markAsSharedLabel, isOn: $sharedEnabled)
                } footer: {
                    Text(Strings.AccountConfirmation.markAsSharedFooter)
                }
            }

            Section {
                Button {
                    if let account = currentSelection {
                        submit(account: account)
                    }
                } label: {
                    Text(Strings.AccountConfirmation.confirm)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.tint)
                }
                .disabled(currentSelection == nil || submitting)
            }
        } else {
            Section {
                Button(action: cancel) {
                    Text(Strings.AccountConfirmation.done)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private func failureSection(error: SocialSharingError) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(error.errorDescription ?? "")
                    .foregroundStyle(.red)
                if let url = error.helpURL {
                    Link(Strings.Errors.learnMore, destination: url)
                }
                Button(Strings.AccountConfirmation.retry) {
                    Task { await load() }
                }
            }
        }
    }

    private func emptyAccountsError(for service: SocialService) -> SocialSharingError {
        if service.id == "facebook" {
            return .noPagesForFacebook
        }
        return .noKeyringForService(serviceLabel: service.label)
    }

    private var currentSelection: SocialKeyringAccount? {
        guard let id = selectedAccountID, case .loaded(let accounts) = state else {
            return nil
        }
        return accounts.first { $0.id == id }
    }
}

private enum LoadingState {
    case loading
    case loaded([SocialKeyringAccount])
    case failed(SocialSharingError)
}

private struct AccountSelectableRow: View {
    let account: SocialKeyringAccount
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            KeyringAvatar(url: account.profilePictureURL)
            Text(account.name)
                .foregroundStyle(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct AccountInfoRow: View {
    let account: SocialKeyringAccount

    var body: some View {
        HStack(spacing: 12) {
            KeyringAvatar(url: account.profilePictureURL)
            Text(account.name)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct KeyringAvatar: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.secondary.opacity(0.15)
                    }
                }
            } else {
                Color.secondary.opacity(0.15)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}
