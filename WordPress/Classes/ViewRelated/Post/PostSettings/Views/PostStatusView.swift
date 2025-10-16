import SwiftUI
import WordPressUI
import WordPressData

struct PostStatusView: View {
    @Binding var settings: PostSettings
    let timeZone: TimeZone

    @State private var isShowingPublishDatePicker = false
    @State private var isShowingPasswordEntry = false

    @ScaledMetric
    private var statusRowLeadingInset: CGFloat = PostStatusRow.leadingInset

    private let statuses = [BasePost.Status.draft, .pending, .publishPrivate, .scheduled, .publish]

    var body: some View {
        Form {
            statusSection
            if settings.status != .publishPrivate {
                passwordSection
            }
            stickySection
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .animation(.default, value: settings)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingPublishDatePicker) {
            NavigationStack {
                PostStatusPublishDatePicker(selection: settings.publishDate, timeZone: timeZone) {
                    settings.status = .scheduled
                    settings.publishDate = $0
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingPasswordEntry) {
            passwordEntryView
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section {
            ForEach(statuses) { status in
                Button {
                    switch status {
                    case .draft, .pending, .publishPrivate, .publish:
                        if settings.status == .scheduled {
                            settings.publishDate = nil
                        }
                        settings.status = status
                    case .scheduled:
                        isShowingPublishDatePicker = true
                    default:
                        wpAssertionFailure("unsupported case")
                    }
                } label: {
                    VStack {
                        PostStatusRow(status: status, isSelected: settings.status == status)
                        if status == .scheduled && settings.status == .scheduled, let date = settings.publishDate {
                            HStack {
                                SettingsRow(Strings.scheduleDate, value: PostSettingsViewModel.formattedDate(date, in: timeZone))
                                Image(systemName: "chevron.forward")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding(.leading, statusRowLeadingInset)
                            .padding(.top, 8)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(status.title)
            }
        }
    }

    @ViewBuilder
    private var passwordSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {
                Toggle(isOn: Binding(
                    get: { !(settings.password ?? "").isEmpty },
                    set: { newValue in
                        if newValue {
                            isShowingPasswordEntry = true
                        } else {
                            settings.password = nil
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.passwordProtected)
                        Text(Strings.passwordProtectedSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !(settings.password ?? "").isEmpty {
                Button {
                    isShowingPasswordEntry = true
                } label: {
                    HStack {
                        Text(Strings.passwordLabel)
                        Spacer()
                        Text("••••••••••••")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.forward")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var stickySection: some View {
        Section {
            Toggle(isOn: $settings.isStickyPost) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.sticky)
                    Text(Strings.stickySubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var passwordEntryView: some View {
        PostSettingsPasswordEntryView(password: settings.password ?? "") {
            settings.password = $0
        }
        .presentationDetents([.large])
    }
}

private struct PostStatusPublishDatePicker: View {
    let selection: Date?
    let timeZone: TimeZone
    let onSubmit: (Date) -> Void

    @State private var newSelection: Date?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        PublishDatePickerView(configuration: PublishDatePickerConfiguration(
            date: selection,
            isRequired: true,
            timeZone: timeZone,
            range: Date.now...Date.distantFuture,
            updated: { date in
                newSelection = date
            }
        ))
        .onAppear {
            newSelection = selection
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button.make(role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button.make(role: .confirm) {
                    if let newSelection {
                        onSubmit(newSelection)
                    }
                    dismiss()
                }
                .disabled(newSelection == nil)
            }
        }
    }
}

private struct PostStatusRow: View {
    let status: BasePost.Status
    let isSelected: Bool

    @ScaledMetric
    private var leadingInset: CGFloat = Self.leadingInset

    static let leadingInset: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                ScaledImage(status.image, height: 23)
                    .foregroundStyle(isSelected ? Color.primary : .secondary.opacity(0.66))
                    .frame(width: leadingInset, alignment: .leading)
                    .offset(y: -1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.title)
                        .font(isSelected ? .body.weight(.medium) : .body)
                        .foregroundStyle(.primary)
                    Text(status.details)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            SettingsCheckmark(isSelected: isSelected)
        }
        .contentShape(Rectangle())
    }
}

private enum Strings {
    static let title = NSLocalizedString("postSettings.statusPicker.navigationTitle", value: "Status & Visibility", comment: "Navigation title for status picker")

    static let passwordProtected = NSLocalizedString("postSettings.statusPicker.passwordProtected", value: "Password Protected", comment: "Toggle label for password protection")
    static let passwordProtectedSubtitle = NSLocalizedString("postSettings.statusPicker.passwordProtectedSubtitle", value: "Only visible to those who know the password", comment: "Subtitle for password protected toggle")

    static let sticky = NSLocalizedString("postSettings.statusPicker.sticky", value: "Sticky", comment: "Toggle label for sticky posts")
    static let stickySubtitle = NSLocalizedString("postSettings.statusPicker.stickySubtitle", value: "Pin this post to the top of the blog", comment: "Subtitle for sticky toggle")

    static let passwordLabel = NSLocalizedString("postSettings.statusPicker.passwordLabel", value: "Password", comment: "Label showing the current password")

    static let scheduleDate = NSLocalizedString("postSettings.statusPicker.scheduleDate", value: "Date", comment: "Label for schedule date row")
}
