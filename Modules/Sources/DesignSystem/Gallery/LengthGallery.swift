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
                .background(Color.DS.Foreground.warning.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: Length.Radius.small))
            }
            .listRowBackground(Color.clear)

            Section("Radii") {
                radiusBoxesVStack
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Lengths")
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

    private var radiusBoxesVStack: some View {
        VStack(spacing: Length.Padding.double) {
            HStack(spacing: Length.Padding.double) {
                radiusBox(name: "Small", radius: Length.Radius.small)
                radiusBox(name: "Medium", radius: Length.Radius.medium)
            }
            HStack(spacing: Length.Padding.double) {
                radiusBox(name: "Large", radius: Length.Radius.large)
                radiusBox(name: "Max", radius: Length.Radius.max)
            }
        }
    }

    private func radiusBox(name: String, radius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.DS.Background.tertiary)
                .frame(width: 120, height: 120)
            Text(name)
                .foregroundStyle(Color.DS.Foreground.primary)

        }
    }
}
