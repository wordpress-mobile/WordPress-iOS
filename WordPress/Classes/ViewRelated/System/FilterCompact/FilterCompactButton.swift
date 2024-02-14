import SwiftUI

struct FilterCompactButton<Value, Content: View, Label: View>: View {
    private let title: String
    @Binding private var selection: Value?
    private let content: () -> Content
    private let label: (Value) -> Label
    private var contentStyle: FilterCompactContentStyle = .popover

    @State private var isShowingPopover = false

    init(_ title: String, selection: Binding<Value?>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping (Value) -> Label) {
        self.title = title
        self._selection = selection
        self.content = content
        self.label = label
    }

    /// Sets the style for the content view displayd when the button is tapped.
    /// The default presentation style is `popover`.
    ///
    /// - note: By default, on iPhone, popovers are displayed as sheets. You can
    /// use `presentationCompactAdaptation` to override this behavior.
    func contentPresentationStyle(_ style: FilterCompactContentStyle) -> Self {
        var copy = self
        copy.contentStyle = style
        return copy
    }

    var body: some View {
        HStack {
            mainButton
            clearButton
        }
        .buttonStyle(.plain)
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        )
        .cornerRadius(40)
        .popover(isPresented: $isShowingPopover, content: content)
    }

    @ViewBuilder
    private var mainButton: some View {
        let label = makeLabel()
            .lineLimit(1)
            .foregroundStyle(Color.primary)
            .font(.subheadline)
        switch contentStyle {
        case .menu:
            Menu(content: content) { label }
        case .popover:
            Button {
                isShowingPopover = true
            } label: {
                label
            }
        }
    }

    @ViewBuilder
    private func makeLabel() -> some View {
        if let selection {
            label(selection)
        } else {
            Text(title)
        }
    }

    @ViewBuilder
    private var clearButton: some View {
        if selection != nil {
            Button(action: { selection = nil }) {
                Image(systemName: "xmark.circle.fill")
            }
            .foregroundStyle(Color.secondary)
        }
    }
}

enum FilterCompactContentStyle {
    case menu
    case popover
}

#Preview {
    FilterCompactButtonPreview()
}

private struct FilterCompactButtonPreview: View {
    @State var selection: SampleEnum?

    enum SampleEnum: String, CaseIterable {
        case a, b, c
    }

    var body: some View {
        FilterCompactButton("Example", selection: $selection) {
            Picker("", selection: $selection) {
                ForEach(SampleEnum.allCases, id: \.self) {
                    Text($0.rawValue).tag(Optional.some($0))
                }
            }.pickerStyle(.inline)
        } label: {
            Text($0.rawValue)
        }
        .contentPresentationStyle(.menu)
    }
}
