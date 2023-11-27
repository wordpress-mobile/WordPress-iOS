import SwiftUI

struct IconGallery: View {
    var body: some View {
        List {
            Group {
                iconHStack(title: DSImageNames.globe, image: .DS.globe)
                iconHStack(title: DSImageNames.settingsGear, image: .DS.settingsGear)
                iconHStack(title: DSImageNames.checkmark, image: .DS.checkmark)
            }
            .listRowBackground(Color.clear)
        }
        .padding(.horizontal, Length.Padding.medium)
        .navigationTitle("Icons")
    }

    private func iconHStack(title: String, image: Image) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: Length.Radius.small)
                    .fill(Color.DS.Background.secondary)
                    .frame(
                        width: Length.Hitbox.minTappableLength,
                        height: Length.Hitbox.minTappableLength
                    )
                image
                    .imageScale(.large)
            }
            Text(title)
                .foregroundStyle(Color.DS.Foreground.primary)
            Spacer()
        }
    }
}


extension Image {
    enum DS {
        static let globe = Image(systemName: DSImageNames.globe)
        static let settingsGear = Image(systemName: DSImageNames.settingsGear)
        static let checkmark = Image(systemName: DSImageNames.checkmark)
    }
}

private enum DSImageNames {
    static let globe = "globe"
    static let settingsGear = "gearshape.fill"
    static let checkmark = "checkmark"
}
