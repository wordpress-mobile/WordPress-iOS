import AsyncImageKit
import SwiftUI

public struct AccountConfirmationView: View {
    private let service: SocialService
    private let connectionsService: SiteSocialConnectionsService
    private let onCancel: () -> Void
    private let onFinish: (Result<SocialKeyringAccount, SocialSharingError>) -> Void

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
        onFinish: @escaping (Result<SocialKeyringAccount, SocialSharingError>) -> Void
    ) {
        self.service = service
        self.connectionsService = connectionsService
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
        connectedExternalIDs = Set(
            (connectionsService.connections.value ?? [])
                .filter { $0.serviceName == service.id }
                .map(\.externalID)
        )
        do {
            let keyrings = try await connectionsService.fetchKeyringConnections()
            let matching = keyrings.filter { $0.service == service.id }
            if matching.isEmpty {
                state = .failed(.keyringNotFound(id: 0))
                return
            }
            let accounts = SocialKeyringAccount.flatten(matching)
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
            let result: Result<SocialKeyringAccount, SocialSharingError>
            do throws(SocialSharingError) {
                _ = try await connectionsService.createConnection(
                    keyringID: account.keyring.id,
                    externalUserID: account.externalUserID,
                    shared: sharedEnabled
                )
                result = .success(account)
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
            Text(Strings.AccountConfirmation.description)
                .foregroundStyle(.primary)
            ForEach(connectable) { account in
                Button {
                    selectedAccountID = account.id
                } label: {
                    AccountSelectableRow(
                        account: account,
                        isSelected: selectedAccountID == account.id,
                        showsSelectionIndicator: connectable.count > 1
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
            Section {
                Toggle(Strings.AccountConfirmation.markAsSharedLabel, isOn: $sharedEnabled)
            } footer: {
                Text(Strings.AccountConfirmation.markAsSharedFooter)
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
        }
    }

    private func failureSection(error: SocialSharingError) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(error.errorDescription ?? "")
                    .foregroundStyle(.red)
                Button(Strings.AccountConfirmation.retry) {
                    Task { await load() }
                }
            }
        }
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
    let showsSelectionIndicator: Bool

    var body: some View {
        HStack(spacing: 12) {
            KeyringAvatar(url: account.profilePictureURL)
            Text(account.name)
                .foregroundStyle(.primary)
            Spacer()
            if showsSelectionIndicator && isSelected {
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
