import SwiftUI

/// A short message shown at the bottom of the screen, like a failed refresh.
struct UnifiedSupportNotice: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

extension View {
    /// Shows the notice at the bottom of the view, and hides it after a few seconds or when tapped.
    func unifiedSupportNotice(_ notice: Binding<UnifiedSupportNotice?>) -> some View {
        modifier(UnifiedSupportNoticeModifier(notice: notice))
    }
}

private struct UnifiedSupportNoticeModifier: ViewModifier {

    @Binding var notice: UnifiedSupportNotice?

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let notice {
                    UnifiedSupportNoticeBanner(message: notice.message)
                        .onTapGesture {
                            self.notice = nil
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: notice)
            .task(id: notice?.id) {
                guard let notice else {
                    return
                }

                AccessibilityNotification.Announcement(notice.message).post()

                try? await Task.sleep(for: .seconds(4))
                if !Task.isCancelled, self.notice?.id == notice.id {
                    self.notice = nil
                }
            }
    }
}

struct UnifiedSupportNoticeBanner: View {

    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        UnifiedSupportNoticeBanner(message: "Something went wrong. Please try again later.")
    }
}
