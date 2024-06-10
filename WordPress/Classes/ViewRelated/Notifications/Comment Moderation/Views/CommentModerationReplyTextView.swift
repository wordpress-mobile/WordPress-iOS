import SwiftUI

struct CommentModerationReplyTextView: View {
    @Binding var text: String

    let layout: CommentModerationViewModel.Layout

    var body: some View {
        let clipShape = RoundedRectangle(cornerRadius: layout == .normal ? 20 : 0, style: .continuous)
        let lineWidth = layout == .normal ? 1 / UIScreen.main.scale : 0
        CommentModerationReplyTextViewRepresentable(text: $text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .clipShape(clipShape)
            .overlay {
                clipShape
                    .stroke(Color.DS.Foreground.tertiary, lineWidth: lineWidth)
            }
    }
}
