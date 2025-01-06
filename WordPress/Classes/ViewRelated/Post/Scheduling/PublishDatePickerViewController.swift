import Foundation
import Gridicons
import UIKit
import SwiftUI

struct PublishDatePickerConfiguration {
    var date: Date? {
        didSet { updated(date) }
    }
    /// If set to `true`, the user will no longer be able to remove the selection.
    var isRequired = false
    var timeZone: TimeZone
    var updated: (Date?) -> Void
}

private extension PublishDatePickerConfiguration {
    var isCurrentTimeZone: Bool {
        timeZone.secondsFromGMT() == TimeZone.current.secondsFromGMT()
    }
}

final class PublishDatePickerViewController: UIHostingController<PublishDatePickerView> {
    init(configuration: PublishDatePickerConfiguration) {
        if configuration.isRequired && configuration.date == nil {
            wpAssertionFailure("initial date value missing")
        }
        super.init(rootView: PublishDatePickerView(configuration: configuration))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
    }
}

extension PublishDatePickerViewController {
    static func make(viewModel: PublishSettingsViewModel, onDateUpdated: @escaping (Date?) -> Void) -> PublishDatePickerViewController {
        PublishDatePickerViewController(configuration: .init(
            date: viewModel.date,
            isRequired: viewModel.isRequired,
            timeZone: viewModel.timeZone,
            updated: onDateUpdated
        ))
    }
}

struct PublishDatePickerView: View {
    @State var configuration: PublishDatePickerConfiguration

    var body: some View {
        Form {
            Section {
                dateRow
                datePickerRow
                if let date = configuration.date, !configuration.isCurrentTimeZone {
                    makeTimeZoneMismatchWarningView(date: date)
                }
            } header: {
                Color.clear.frame(height: 0) // Reducing the top inset
            }
            if !configuration.isCurrentTimeZone {
                Section {
                    timeZoneRow
                }
            }
        }
        .padding(.top, -8)
        .environment(\.defaultMinListHeaderHeight, 0)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color(uiColor: UIAppColor.primary))
    }

    private var dateRow: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(Strings.date)
                    .font(.subheadline)
                Text(selectedValue)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer()

            if configuration.date != nil, !configuration.isRequired {
                Button(action: { configuration.date = nil }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .foregroundStyle(Color.secondary)
                .buttonStyle(.plain)
            }
        }
    }

    private var timeZoneRow: some View {
        HStack {
            Text(Strings.timeZone)
            Spacer()
            Text(getLocalizedTimeZoneDescription(for: configuration.timeZone))
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
        }.lineLimit(1)
    }

    private var datePickerRow: some View {
        DatePicker(Strings.date, selection: Binding(get: {
            configuration.date ?? Date()
        }, set: {
            configuration.date = $0
        }), displayedComponents: [.date, .hourAndMinute])
        .environment(\.timeZone, configuration.timeZone)
        .datePickerStyle(.graphical)
        .labelsHidden()
        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
    }

    private func makeTimeZoneMismatchWarningView(date: Date) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary.opacity(0.75))
            Text(Strings.footerCurrentTimezone + "\n" + "\(formattedString(from: date, timeZone: .current)) (\(getLocalizedTimeOffset(for: .current)))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var selectedValue: String {
        guard let date = configuration.date else {
            return Strings.immediately
        }
        let value = formattedString(from: date, timeZone: configuration.timeZone)
        guard !configuration.isCurrentTimeZone else {
            return value
        }
        return "\(value) (\(getLocalizedTimeOffset(for: configuration.timeZone)))"
    }
}

private func formattedString(from date: Date, timeZone: TimeZone?) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    dateFormatter.timeZone = timeZone
    return dateFormatter.string(from: date)
}

private func getLocalizedTimeZoneDescription(for timeZone: TimeZone) -> String {
    let name = timeZone.localizedName(for: .shortGeneric, locale: .current) ?? ""
    let offset = getLocalizedTimeOffset(for: timeZone)
    guard name != offset else { return name } // "GMT" will just say "GMT (GMT)"
    return "\(name) (\(offset))"
}

private func getLocalizedTimeOffset(for timeZone: TimeZone) -> String {
    let timeZoneFormatter = DateFormatter()
    timeZoneFormatter.dateFormat = "O"
    timeZoneFormatter.timeZone = timeZone
    return timeZoneFormatter.string(from: Date())
}

private enum Strings {
    static let title = NSLocalizedString("publishDatePicker.title", value: "Publish Date", comment: "Post publish date picker")
    static let date = NSLocalizedString("publishDatePicker.date", value: "Publish Date", comment: "Post publish date picker title for date cell")
    static let immediately = NSLocalizedString("publishDatePicker.immediately", value: "Immediately", comment: "Post publish date picker: selected value placeholder when no date is selected and the post will be published immediately")
    static let timeZone = NSLocalizedString("publishDatePicker.timeZone", value: "Time Zone", comment: "Post publish time zone cell title")
    static let footerCurrentTimezone = NSLocalizedString("publishDatePicker.footerCurrentTimezone", value: "The date in your current time zone:", comment: "Post publish date picker footer view when the selected date time zone is different from your current time zone; followed by the time in the current time zone.")
}

#Preview("Current Time Zone") {
    NavigationView {
        PublishDatePickerView(configuration: .init(date: nil, timeZone: .current, updated: { _ in }))
    }
}

#Preview("Other Time Zone") {
    NavigationView {
        PublishDatePickerView(configuration: .init(date: Date(), timeZone: .init(identifier: "Europe/London")!, updated: { _ in }))
    }
}
