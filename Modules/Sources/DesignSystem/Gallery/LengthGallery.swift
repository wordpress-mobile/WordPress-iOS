import SwiftUI

struct LengthGallery: View {
    var body: some View {
        List {
            Section("Padding") {
                VStack {
                    paddingRectangle(name: "Half").padding(.trailing, .DS.Padding.half)
                    paddingRectangle(name: "Single").padding(.trailing, .DS.Padding.single)
                    paddingRectangle(name: "Split").padding(.trailing, .DS.Padding.split)
                    paddingRectangle(name: "Double").padding(.trailing, .DS.Padding.double)
                    paddingRectangle(name: "Medium").padding(.trailing, .DS.Padding.medium)
                    paddingRectangle(name: "Large").padding(.trailing, .DS.Padding.large)
                    paddingRectangle(name: "Max").padding(.trailing, .DS.Padding.max)
                }
                .background(.red.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: .DS.Radius.small))
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
            RoundedRectangle(cornerRadius: .DS.Radius.small)
                .fill(.background)
                .frame(height: 44)
            HStack {
                Text(name)
                    .offset(x: .DS.Padding.double)
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    private var radiusBoxesVStack: some View {
        VStack(spacing: .DS.Padding.double) {
            HStack(spacing: .DS.Padding.double) {
                radiusBox(name: "Small", radius: .DS.Radius.small)
                radiusBox(name: "Medium", radius: .DS.Radius.medium)
            }
            HStack(spacing: .DS.Padding.double) {
                radiusBox(name: "Large", radius: .DS.Radius.large)
                radiusBox(name: "Max", radius: .DS.Radius.max)
            }
        }
    }

    private func radiusBox(name: String, radius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(.background)
                .frame(width: 120, height: 120)
            Text(name)
                .foregroundStyle(.primary)

        }
    }
}
