import SwiftUI

struct LoadingLatestContentView: View {
    @State private var isVisible: Bool = false

    var body: some View {
        ZStack {
            // The toast container
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)

                Text("Loading latest content…")
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Loading latest content")
            .accessibilityAddTraits(.isStaticText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 24)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ForEach(0..<12) { i in
                Text("Row \(i)")
            }
        }
        .navigationTitle("Demo")
    }
    .overlay(alignment: .bottom) {
        LoadingLatestContentView()
    }
}
