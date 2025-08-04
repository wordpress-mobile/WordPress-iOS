import SwiftUI

struct TimezoneInfoView: View {
    @State private var showingTimezoneInfo = false
    @Environment(\.context) private var context

    var body: some View {
        Button {
            showingTimezoneInfo = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "location")
                    .font(.caption2)
                Text(formattedTimeZone)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingTimezoneInfo) {
            timezoneInfoContent
        }
    }

    private var formattedTimeZone: String {
        let name = context.timeZone.localizedName(for: .standard, locale: .current)
        return name ?? context.timeZone.identifier
    }

    @ViewBuilder
    private var timezoneInfoContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.DatePicker.siteTimeZone)
                .font(.headline)
                .foregroundStyle(.primary)

            Text("\(formattedTimeZone) (\(context.formatters.date.formattedTimeOffset))")
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(Strings.DatePicker.siteTimeZoneDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

        }
        .padding()
        .frame(idealWidth: 280, maxWidth: 320)
        .modifier(PopoverPresentationModifier())
    }
}

#Preview {
    TimezoneInfoView()
        .padding()
}
