
import SwiftUI

/// a Text containing a stats value, replaced by a placeholder when the placeholder condition is met
struct StatsValueView: View {

    let value: Int
    let font: Font
    let fontWeight: Font.Weight
    let foregroundColor: Color
    let lineLimit: Int?

    private var isPlaceholder: Bool {
        value < 0
    }

    var body: some View {

        switch isPlaceholder {
        case true:
            textView.redacted(reason: .placeholder)
        case false:
            textView
        }
    }

    private var textView: some View {
        Text(value.abbreviatedString())
            .font(font)
            .fontWeight(fontWeight)
            .foregroundColor(foregroundColor)
            .lineLimit(lineLimit)
    }
}
