import SwiftUI

struct CommentModerationReplyTextView: View {
    @Binding var text: String

    let layout: CommentModerationViewModel.Layout

    @State private var isFirstResponder: Bool = false

    var body: some View {
        let clipShape = RoundedRectangle(cornerRadius: layout == .normal ? 23 : 0, style: .continuous)
        let lineWidth = layout == .normal ? 1 / UIScreen.main.scale : 0
        HStack(alignment: .top, spacing: .DS.Padding.single) {
            avatar
            textView
            submit
        }
        .padding(.horizontal, .DS.Padding.double)
        .padding(.vertical, .DS.Padding.split)
        .background(Color(UIColor.systemBackground))
        .clipShape(clipShape)
        .overlay {
            clipShape
                .stroke(Color.DS.Foreground.tertiary, lineWidth: lineWidth)
        }
        .onTapGesture {
            isFirstResponder = true
        }
    }

    @ViewBuilder
    private var submit: some View {
        let isEmpty = text.isEmpty
        let foregroundStyle = isEmpty ? Color.DS.Foreground.secondary : Color.DS.Foreground.brand(isJetpack: true)
        if isFirstResponder || !isEmpty {
            Button(action: {}) {
                Text("Send")
                    .font(.DS.font(.bodyLarge(.regular)))
                    .foregroundStyle(foregroundStyle)
            }
            .disabled(isEmpty)
            .transition(
                .asymmetric(
                    insertion: .opacity.animation(.smooth),
                    removal: .identity
                )
            )
        }
    }

    @ViewBuilder
    private var avatar: some View {
        CachedAsyncImage(url: .init(string: "https://i.pravatar.cc/300")) { image in
            image.resizable()
        } placeholder: {
            Image("gravatar").resizable()
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var textView: some View {
        CommentModerationReplyTextViewRepresentable(text: $text, isFirstResponder: $isFirstResponder)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

struct ContentView: View {
    @State private var text: String = ""

    var body: some View {
        CommentModerationReplyTextView(
            text: $text,
            layout: .normal
        )
        .padding(.horizontal, .DS.Padding.double)
    }
}

#Preview {
    ContentView()
}
