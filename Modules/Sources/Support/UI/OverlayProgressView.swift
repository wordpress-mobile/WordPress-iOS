import SwiftUI

struct OverlayProgressView: View {

    enum ViewState {
        case mustBeHidden
        case mustBeVisible
        case inherit
    }

    enum Style {
        case toast
        case horizontalBar
    }

    let shouldBeVisible: Bool
    private let minimumDisplayTime: Duration
    private let style: Style

    @State
    private var state: ViewState = .mustBeHidden // Start off hidden so the view animates in

    private var isVisible: Bool {
        switch self.state {
        case .mustBeHidden: false
        case .mustBeVisible: true
        case .inherit: shouldBeVisible
        }
    }

    init(shouldBeVisible: Bool, minimumDisplayTime: Duration = .seconds(3.8), style: Style = .horizontalBar) {
        self.shouldBeVisible = shouldBeVisible
        self.minimumDisplayTime = minimumDisplayTime
        self.style = style
    }

    var body: some View {
        ZStack {
            switch style {
            case .toast:
                toastView
            case .horizontalBar:
                horizontalBarView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style == .toast ? .top : .bottom)
        .padding(.top, style == .toast ? 24 : 0)
        .padding(.bottom, style == .horizontalBar ? 0 : 0)
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

    @ViewBuilder
    private var toastView: some View {
        // The toast container
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
    }

    @ViewBuilder
    private var horizontalBarView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 4)
                .frame(maxWidth: .infinity)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(x: isVisible ? 1 : 0, y: 1, anchor: .leading)
                .overlay(
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.7))
                        .scaleEffect(x: 0.3, y: 1)
                        .offset(x: isVisible ? UIScreen.main.bounds.width : -100)
                        .animation(
                            isVisible ? .easeInOut(duration: 1.2).repeatForever(autoreverses: false) : .default,
                            value: isVisible
                        )
                )
                .accessibilityLabel("Loading")
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

#Preview("Toast Style") {
    NavigationStack {
        List {
            ForEach(0..<12) { i in
                Text("Row \(i)")
            }
        }
        .navigationTitle("Demo")
    }
    .overlay(alignment: .top) {
        OverlayProgressView(shouldBeVisible: true, style: .toast)
    }
}

#Preview("Horizontal Bar Style") {
    NavigationStack {
        List {
            ForEach(0..<12) { i in
                Text("Row \(i)")
            }
        }
        .navigationTitle("Demo")
    }
    .overlay(alignment: .bottom) {
        OverlayProgressView(shouldBeVisible: true, style: .horizontalBar)
    }
}
