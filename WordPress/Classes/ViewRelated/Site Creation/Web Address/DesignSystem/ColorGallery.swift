import SwiftUI

struct ColorGallery: View {
    var body: some View {
        List {
            Section(header: Text("Foreground").font(Font.title3)) {
                listItem(with: "Primary", color: Color.DS.Foreground.primary)
                listItem(with: "Secondary", color: Color.DS.Foreground.secondary)
                listItem(with: "Tertiary", color: Color.DS.Foreground.tertiary)
            }
            Section(header: Text("Background").font(Font.title3)) {
                listItem(with: "Primary", color: Color.DS.Background.primary)
                listItem(with: "Secondary", color: Color.DS.Background.secondary)
                listItem(with: "Tertiary", color: Color.DS.Background.tertiary)
            }
        }
    }

    private func colorSquare(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 44, height: 44)
    }

    private func listItem(with name: String, color: Color) -> some View {
        HStack(spacing: 16) {
            colorSquare(color)
            Text(name)
        }
    }
}
