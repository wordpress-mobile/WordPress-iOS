import SwiftUI

struct BannerView: View {
    let summary: MediaLibraryViewModel.BannerSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if summary.pendingCount > 0 {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                }
                Text(label)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var label: String {
        switch (summary.pendingCount, summary.failedCount) {
        case (let p, 0) where p > 0:
            return String.localizedStringWithFormat(Strings.uploadBannerUploadingOnly, p)
        case (let p, let f) where p > 0 && f > 0:
            return String.localizedStringWithFormat(Strings.uploadBannerMixed, p, f)
        case (0, let f) where f > 0:
            return String.localizedStringWithFormat(Strings.uploadBannerFailedOnly, f)
        default:
            return ""
        }
    }
}
