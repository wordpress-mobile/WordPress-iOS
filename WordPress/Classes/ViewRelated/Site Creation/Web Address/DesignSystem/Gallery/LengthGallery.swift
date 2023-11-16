import SwiftUI

struct LengthGallery: View {
    var body: some View {
        List {
            Section("Padding") {
                VStack {
                    paddingRectangle(name: "Half").padding(.trailing, Length.Padding.half)
                    paddingRectangle(name: "Single").padding(.trailing, Length.Padding.single)
                    paddingRectangle(name: "Split").padding(.trailing, Length.Padding.split)
                    paddingRectangle(name: "Double").padding(.trailing, Length.Padding.double)
                    paddingRectangle(name: "Medium").padding(.trailing, Length.Padding.medium)
                    paddingRectangle(name: "Large").padding(.trailing, Length.Padding.large)
                    paddingRectangle(name: "Max").padding(.trailing, Length.Padding.max)
                }
                .background(Color.DS.Background.primary)
                .clipShape(RoundedRectangle(cornerRadius: Length.Radius.small))
            }
            .listRowBackground(Color.clear)
        }
    }

    private func paddingRectangle(name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Length.Radius.small)
                .fill(Color.DS.Background.tertiary)
                .frame(height: Length.Hitbox.minTappableLength)
            HStack {
                Text(name)
                    .offset(x: Length.Padding.double)
                    .foregroundStyle(Color.DS.Foreground.primary)
                Spacer()
            }
        }
    }
}
