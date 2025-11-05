import SwiftUI

struct ChipView: View {

    private let string: String
    private let color: Color

    @Environment(\.self)
    private var environment

    @Environment(\.controlSize)
    private var controlSize

    init(string: String, color: Color) {
        self.string = string
        self.color = color
    }

    var body: some View {
        Text(self.string)
            .font(self.font)
            .foregroundStyle(self.computedTextColor)
            .padding(self.padding)
            .background(self.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var computedTextColor: Color {
        let resolved = self.color.resolve(in: environment)
        let r = resolved.red
        let g = resolved.green
        let b = resolved.blue

        let L = 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
        return L > 0.5 ? .black : .white
    }

    @inline(__always)
    private func linearize(_ c: Float) -> Float {
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    var font: Font {
        switch self.controlSize {
        case .mini: .caption2
        case .small: .caption
        case .regular: .body
        case .large: .subheadline.weight(.regular)
        case .extraLarge: .headline.weight(.regular)
        @unknown default: .body
        }
    }

    var padding: EdgeInsets {
        switch self.controlSize {
        case .mini: EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
        case .small: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .regular: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        case .large: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        case .extraLarge: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        @unknown default: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        }
    }
}

#Preview("Color") {
    NavigationStack {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ChipView(string: "teal", color: .teal)
                    ChipView(string: "red", color: .red)
                    ChipView(string: "orange", color: .orange)
                    ChipView(string: "yellow", color: .yellow)
                    ChipView(string: "green", color: .green)
                    ChipView(string: "blue", color: .blue)
                    ChipView(string: "purple", color: .purple)
                    ChipView(string: "black", color: .black)
                    ChipView(string: "white", color: .white)
                    ChipView(string: "brown", color: .brown)
                    ChipView(string: "cyan", color: .cyan)
                    ChipView(string: "gray", color: .gray)
                    ChipView(string: "indigo", color: .indigo)
                    ChipView(string: "mint", color: .mint)
                    ChipView(string: "pink", color: .pink)
                    ChipView(string: "primary", color: .primary)
                    ChipView(string: "secondary", color: .secondary)
                    ChipView(string: "accent", color: .accentColor)
                }.padding()
                Spacer()
            }
        }
    }
}

#Preview("Size") {
    NavigationStack {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ChipView(string: "mini", color: .accentColor)
                        .controlSize(.mini)
                    ChipView(string: "small", color: .accentColor)
                        .controlSize(.small)
                    ChipView(string: "regular", color: .accentColor)
                        .controlSize(.regular)
                    ChipView(string: "large", color: .accentColor)
                        .controlSize(.large)
                    ChipView(string: "extra large", color: .accentColor)
                        .controlSize(.extraLarge)
                }
            }
        }
    }
}
