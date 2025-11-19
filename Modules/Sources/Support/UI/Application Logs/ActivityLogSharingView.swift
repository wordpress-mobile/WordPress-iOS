import SwiftUI

enum SharingOption: CaseIterable {
    case supportTicket
    case exportFile

    var title: String {
        switch self {
        case .supportTicket: Localization.newSupportTicket
        case .exportFile: Localization.exportAsFile
        }
    }

    var systemImage: String {
        switch self {
        case .supportTicket: "questionmark.circle"
        case .exportFile: "doc.badge.plus"
        }
    }

    var description: String {
        return switch self {
        case .supportTicket: Localization.sendLogsToSupport
        case .exportFile: Localization.saveAsFile
        }
    }
}

struct ActivityLogSharingView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var selectedOption: SharingOption = .supportTicket

    let applicationLog: ApplicationLog

    @ViewBuilder
    var destination: () -> AnyView

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {

                VStack(spacing: 12) {
                    ForEach(SharingOption.allCases, id: \.self) { option in
                        SharingOptionRow(
                            option: option,
                            isSelected: selectedOption == option
                        ) {
                            selectedOption = option
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    switch selectedOption {
                    case .exportFile:
                        ShareLink(item: applicationLog.path) {
                            Spacer()
                            Text(Localization.share)
                            Spacer()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                    case .supportTicket:
                        NavigationLink(destination: self.destination) {
                            Spacer()
                            Text(Localization.share)
                            Spacer()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(Localization.shareActivityLog)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SharingOptionRow: View {
    let option: SharingOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: option.systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(option.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            Color.clear
                .sheet(isPresented: $isPresented) {
                    ActivityLogSharingView(applicationLog: SupportDataProvider.applicationLog) {
                        AnyView(erasing: Text(Localization.sharingWithSupport))
                    }.presentationDetents([.medium])
                }
        }
    }

    return PreviewWrapper()
}
