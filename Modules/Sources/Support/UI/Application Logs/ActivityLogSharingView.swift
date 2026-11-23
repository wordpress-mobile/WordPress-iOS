import SwiftUI

struct ActivityLogSharingView: View {

    @Environment(\.dismiss)
    private var dismiss

    let applicationLog: ApplicationLog

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                exportOption
                    .padding(.horizontal)

                Spacer()

                ShareLink(item: applicationLog.path) {
                    Spacer()
                    Text(Localization.share)
                    Spacer()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
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

    private var exportOption: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.exportAsFile)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(Localization.saveAsFile)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            Color.clear
                .sheet(isPresented: $isPresented) {
                    ActivityLogSharingView(applicationLog: SupportDataProvider.applicationLog)
                        .presentationDetents([.medium])
                }
        }
    }

    return PreviewWrapper()
}
