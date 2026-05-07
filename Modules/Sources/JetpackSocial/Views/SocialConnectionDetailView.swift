import SwiftUI

public struct SocialConnectionDetailView: View {
    let connection: SocialConnection
    @ObservedObject var connections: SiteSocialConnectionsService

    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion = false
    @State private var isDeleting = false
    @State private var isUpdatingShared = false
    @State private var failureAlert: FailureAlert?

    public var body: some View {
        Form {
            if let current {
                if connections.canMarkAsShared {
                    Section {
                        Toggle(isOn: sharedBinding(for: current)) {
                            Text(Strings.ConnectionDetail.availableToAllUsers)
                        }
                        .disabled(isUpdatingShared)
                    } header: {
                        Text(Strings.ConnectionDetail.settingsHeader)
                    } footer: {
                        Text(Strings.ConnectionDetail.availableToAllUsersFooter)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        pendingDeletion = true
                    } label: {
                        Text(Strings.ManageConnections.deleteButton)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .disabled(isDeleting)
        .overlay {
            if isDeleting {
                ZStack {
                    Color(.systemBackground).opacity(0.7)
                    ProgressView()
                        .controlSize(.large)
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle(handleTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            String.localizedStringWithFormat(
                Strings.ManageConnections.deleteConfirmTitleFormat,
                connection.displayName
            ),
            isPresented: $pendingDeletion
        ) {
            Button(Strings.ManageConnections.cancelButton, role: .cancel) {}
            Button(Strings.ManageConnections.yesButton, role: .destructive) {
                Task {
                    isDeleting = true
                    do throws(SocialSharingError) {
                        try await connections.deleteConnection(id: connection.id)
                        // Success: the service removes the connection from
                        // its @Published list, and `.onChange(of: currentId == nil)`
                        // auto-dismisses this view.
                    } catch {
                        failureAlert = FailureAlert(
                            title: Strings.ManageConnections.deleteFailedTitle,
                            dismissButton: Strings.ManageConnections.deleteFailedDismiss,
                            error: error
                        )
                    }
                    isDeleting = false
                }
            }
        }
        .alert(item: $failureAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.error.errorDescription ?? ""),
                dismissButton: .cancel(Text(alert.dismissButton))
            )
        }
        .onChange(of: currentId == nil) { _, missing in
            if missing {
                dismiss()
            }
        }
    }

    /// The current server-confirmed connection, looked up fresh on every render.
    /// Nil when the connection has been deleted (triggers auto-dismiss).
    private var current: SocialConnection? {
        (connections.connections.value ?? []).first(where: { $0.id == connection.id })
    }

    private var currentId: String? {
        current?.id
    }

    private var handleTitle: String {
        current?.externalHandle ?? connection.externalHandle ?? connection.displayName
    }

    private func sharedBinding(for connection: SocialConnection) -> Binding<Bool> {
        Binding(
            get: { connection.isShared },
            set: { newValue in
                guard !isUpdatingShared else { return }
                isUpdatingShared = true
                Task {
                    defer { isUpdatingShared = false }
                    do throws(SocialSharingError) {
                        try await connections.updateConnection(id: connection.id, shared: newValue)
                    } catch {
                        failureAlert = FailureAlert(
                            title: Strings.ConnectionDetail.updateFailedTitle,
                            dismissButton: Strings.ConnectionDetail.updateFailedDismiss,
                            error: error
                        )
                    }
                }
            }
        )
    }
}

private struct FailureAlert: Identifiable {
    let id = UUID()
    let title: String
    let dismissButton: String
    let error: SocialSharingError
}
