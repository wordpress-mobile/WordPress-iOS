import SwiftUI

struct OverlayProgressView: View {

    enum ViewState {
        /// The view is hidden
        case mustBeHidden
        /// The view is visible
        case mustBeVisible
        /// The view has been signaled it should hide, but the `minimumDisplayTime` has not yet elapsed
        case awaitingHiding(until: Date)

        var isVisible: Bool {
            switch self {
            case .mustBeVisible: true
            case .mustBeHidden: false
            case .awaitingHiding: true
            }
        }
    }

    let shouldBeVisible: Bool
    private let minimumDisplayTime: Duration

    @State
    private var state: ViewState = .mustBeHidden // Start off hidden so the view animates in

    @State
    private var canHideAt: Date?

    init(shouldBeVisible: Bool, minimumDisplayTime: Duration = .seconds(1.8)) {
        self.shouldBeVisible = shouldBeVisible
        self.minimumDisplayTime = minimumDisplayTime
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in

            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)

                Text(Localization.loadingLatestContent)
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
            .opacity(state.isVisible ? 1 : 0)
            .offset(y: state.isVisible ? 0 : -12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Localization.loadingLatestContent)
            .accessibilityAddTraits(.isStaticText)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 24)
            .onChange(of: context.date, { oldValue, newValue in
                if case .awaitingHiding(let until) = state {
                    if until.hasPast {
                        withAnimation {
                            self.state = .mustBeHidden
                        }
                    }
                }
            })
            .onChange(of: self.shouldBeVisible) { oldValue, newValue in
                withAnimation {
                    if newValue {
                        self.state = .mustBeVisible
                        self.canHideAt = Date.now.addingTimeInterval(minimumDisplayTime / .seconds(1))
                    } else {
                        if let canHideAt, !canHideAt.hasPast {
                            self.state = .awaitingHiding(until: canHideAt)
                        } else {
                            self.state = .mustBeHidden
                        }
                    }
                }
            }
        }
    }
}

#Preview {

    @Previewable @State var shouldDisplay: Bool = false

    NavigationStack {
        List {
            ForEach(0..<12) { i in
                Text("Row \(i)")
            }
        }
        .navigationTitle("Demo")
        .toolbar {
            Button {
                shouldDisplay.toggle()
            } label: {
                Text("Toggle Progress View")
            }
        }
    }
    .overlay(alignment: .top) {
        OverlayProgressView(shouldBeVisible: shouldDisplay)
    }
}
