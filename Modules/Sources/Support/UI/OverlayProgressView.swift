import SwiftUI

struct OverlayProgressView: View {

    enum ViewState {
        case mustBeHidden
        case mustBeVisible
        case inherit
    }

    let shouldBeVisible: Bool
    private let minimumDisplayTime: Duration

    @State
    private var state: ViewState = .mustBeHidden // Start off hidden so the view animates in

    private var isVisible: Bool {
        switch self.state {
        case .mustBeHidden: false
        case .mustBeVisible: true
        case .inherit: shouldBeVisible
        }
    }

    init(shouldBeVisible: Bool, minimumDisplayTime: Duration = .seconds(3.8)) {
        self.shouldBeVisible = shouldBeVisible
        self.minimumDisplayTime = minimumDisplayTime
    }

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)

            Text("Loading latest content")
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
        .offset(y: isVisible ? 0 : -12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading latest content")
        .accessibilityAddTraits(.isStaticText)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 24)
        .onAppear {
            withAnimation(.easeOut) {
                self.state = .mustBeVisible
            }
        }
        .task {
            try? await Task.sleep(for: self.minimumDisplayTime)
            await MainActor.run {
                withAnimation(.easeOut) {
                    self.state = .inherit
                }
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
    .overlay(alignment: .top) {
        OverlayProgressView(shouldBeVisible: true)
    }
}
