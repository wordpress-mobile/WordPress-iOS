import SwiftUI

struct BannerView: View {
    let summary: MediaLibraryViewModel.BannerSummary
    let onTap: (() -> Void)?

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } else {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            if summary.pendingCount > 0 {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
            Text(label)
                .font(.subheadline)
            Spacer()
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }

    private var label: String {
        switch (summary.pendingCount, summary.failedCount) {
        case (let p, 0) where p > 0:
            let template = p == 1 ? Strings.uploadBannerUploadingOnlySingle : Strings.uploadBannerUploadingOnly
            return String.localizedStringWithFormat(template, p)
        case (let p, let f) where p > 0 && f > 0:
            return String.localizedStringWithFormat(Strings.uploadBannerMixed, p, f)
        case (0, let f) where f > 0:
            let template = f == 1 ? Strings.uploadBannerFailedOnlySingle : Strings.uploadBannerFailedOnly
            return String.localizedStringWithFormat(template, f)
        default:
            return ""
        }
    }
}
