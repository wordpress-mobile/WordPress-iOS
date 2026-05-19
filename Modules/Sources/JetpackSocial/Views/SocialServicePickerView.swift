import SwiftUI

public struct SocialServicePickerView: View {
    @ObservedObject private var connections: SiteSocialConnectionsService
    private let onPick: (SocialService) -> Void
    private let onCancel: () -> Void

    public init(
        connections: SiteSocialConnectionsService,
        onPick: @escaping (SocialService) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.connections = connections
        self.onPick = onPick
        self.onCancel = onCancel
    }

    public var body: some View {
        Form {
            content
        }
        .navigationTitle(Strings.ServicePicker.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .cancel, action: onCancel)
                } else {
                    Button(role: .cancel, action: onCancel) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .task {
            await connections.loadServices(force: false)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch connections.services {
        case .loading:
            loadingSection
        case .loaded(let services):
            loadedSection(services: services)
        case .failed(let error):
            failureSection(error: error)
        }
    }

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func loadedSection(services: [SocialService]) -> some View {
        let visible = services.filter(\.isActive)
        Section {
            ForEach(visible) { service in
                Button {
                    onPick(service)
                } label: {
                    HStack(spacing: 12) {
                        icon(for: service)
                        Text(service.label)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text(Strings.ManageConnections.footer)
        }
    }

    private func failureSection(error: SocialSharingError) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(error.errorDescription ?? "")
                    .foregroundStyle(.red)
                Button(Strings.ManageConnections.retry) {
                    Task { await connections.loadServices(force: true) }
                }
            }
        }
    }

    @ViewBuilder
    private func icon(for service: SocialService) -> some View {
        if let image = SocialServiceIcon.image(forServiceID: service.id) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 28, height: 28)
        }
    }
}
