import SwiftUI
import TipKit

/// A pre-Liquid Glass version.
struct LegacyFloatingDateControl: View {
    @Binding var dateRange: StatsDateRange
    @State private var isShowingCustomRangePicker = false

    private var buttonHeight: CGFloat { min(_buttonHeight, 60) }
    @ScaledMetric private var _buttonHeight = 46

    @Environment(\.context) var context

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            dateRangeButton
            Spacer(minLength: 8)
            navigationControls
        }
        .modifier(MinimumBottomSafeArea(minPadding: 16))
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(.horizontal, 24)
        .background {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: .systemBackground).opacity(0.1),
                    Color(uiColor: .systemBackground).opacity(0.8),
                    Color(uiColor: .systemBackground).opacity(1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .offset(y: buttonHeight / 4)
            .frame(height: buttonHeight * 2 + buttonHeight / 4)
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingCustomRangePicker) {
            CustomDateRangePicker(dateRange: $dateRange)
        }
    }

    // MARK: - Date Range Picker

    private var dateRangeButton: some View {
        Menu {
            StatsDateRangePickerMenu(
                selection: $dateRange,
                isShowingCustomRangePicker: $isShowingCustomRangePicker
            )
        } label: {
            dateRangeButtonContent
                .contentShape(Rectangle())
                .frame(height: buttonHeight)
                .floatingStyle()
        }
        .tint(Color.primary)
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .popoverTip(StatsDateRangeTip(), arrowEdge: .bottom)
    }

    private var dateRangeButtonContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.headline.weight(.regular))
                .foregroundStyle(.primary.opacity(0.8))

            VStack(alignment: .leading, spacing: 0) {
                Text(currentRangeText)
                    .fontWeight(.medium)
                    .allowsTightening(true)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, 15)
        .padding(.trailing, 2)
    }

    private var currentRangeText: String {
        if let preset = dateRange.preset, !preset.prefersDateIntervalFormatting {
            return preset.localizedString
        }
        return context.formatters.dateRange
            .string(from: dateRange.dateInterval)
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 8) {
            makeNavigationButton(direction: .backward)
            makeNavigationButton(direction: .forward)
        }
        .floatingStyle()
    }

    private func makeNavigationButton(direction: Calendar.NavigationDirection) -> some View {
        let isDisabled = !dateRange.canNavigate(in: direction)
        return Menu {
            ForEach(dateRange.availableAdjacentPeriods(in: direction)) { period in
                Button(period.displayText) {
                    dateRange = period.range
                }
            }
        } label: {
            Image(systemName: direction.systemImage)
                .font(.title3.weight(.medium))
                .foregroundColor(isDisabled ? Color(.quaternaryLabel) : Color(.label))
                .frame(width: 48)
                .frame(height: buttonHeight)
                .opacity(isDisabled ? 0.5 : 1.0)
                .contentShape(Rectangle())
        } primaryAction: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dateRange = dateRange.navigate(direction)
        }
        .disabled(isDisabled)
    }
}

private struct FloatingStyle: ViewModifier {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 40) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground).opacity(0.2))
            .background(Material.thin)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Constants.Colors.shadowColor, radius: 8, x: 0, y: 4)
            .shadow(color: Constants.Colors.shadowColor.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

private struct StatsDateRangeTip: Tip {
    var title: Text {
        Text(Strings.DateRangeTips.title)
    }

    var message: Text? {
        Text(Strings.DateRangeTips.message)
    }

    var image: Image? {
        Image(systemName: "calendar")
    }

    var options: [any TipOption] {
        [Tips.MaxDisplayCount(1)]
    }
}

private struct MinimumBottomSafeArea: ViewModifier {
    let minPadding: CGFloat

    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomInset == 0 ? minPadding : 0)
            .overlay(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        self.bottomInset = geometry.safeAreaInsets.bottom
                    }
                }
            )
    }
}

private extension View {
    func floatingStyle(cornerRadius: CGFloat = 40) -> some View {
        modifier(FloatingStyle(cornerRadius: cornerRadius))
    }
}
