import SwiftUI

struct FontGallery: View {
    init() {
        FontManager.registerCustomFonts()
    }

    var body: some View {
        List {
            Section("Recoleta") {
                ForEach(textStyles, id: \.self.1) { (name, textStyle) in
                    Text(name)
                        .font(Font.make(.recoleta, textStyle: textStyle))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Fonts")
    }
}

private var textStyles: [(String, UIFont.TextStyle)] = [
    ("LargeTitle", .largeTitle),
    ("Title1", .title1),
    ("Title2", .title2),
    ("Title3", .title3),
    ("Headline", .headline),
    ("Body", .body),
    ("Callout", .callout),
    ("Subheadline", .subheadline),
    ("Footnote", .footnote),
    ("Caption1", .caption1),
    ("Caption2", .caption2),
]

#Preview {
    FontGallery()
}
