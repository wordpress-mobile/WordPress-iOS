import Foundation
import SwiftUI
import PhotosUI

public struct SupportForm: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    /// Focus state for managing field focus
    @FocusState private var focusedField: Field?

    /// Available support areas for the user to choose from
    let areas: [SupportFormArea] = [
        .application,
        .jetpackConnection,
        .siteManagement,
        .billing,
        .technical,
        .other
    ]

    /// Variable that holds the area of support for better routing.
    @State private var selectedArea: SupportFormArea?

    /// Variable that holds the subject of the ticket.
    @State private var subject = ""

    /// Variable that holds the site address of the ticket.
    @State private var siteAddress = ""

    /// Variable that holds the description of the ticket.
    @State private var plainTextProblemDescription = ""
    @State private var attributedProblemDescription: AttributedString = ""

    /// User's contact information
    private let supportIdentity: SupportUser

    /// Application Logs
    @State private var includeApplicationLogs = false
    @State private var applicationLogs: [ApplicationLog]

    @State private var selectedPhotos: [URL] = []

    /// UI State
    @State private var showLoadingIndicator = false
    @State private var shouldShowErrorAlert = false
    @State private var shouldShowSuccessAlert = false
    @State private var errorMessage = ""

    /// Callback for when form is dismissed
    public var onDismiss: (() -> Void)?

    private var problemDescriptionIsEmpty: Bool {
        plainTextProblemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && NSAttributedString(attributedProblemDescription).string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    /// Determines if the submit button should be enabled or not.
    private var submitButtonDisabled: Bool {
        selectedArea == nil
        || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || problemDescriptionIsEmpty
    }

    public init(
        onDismiss: (() -> Void)? = nil,
        supportIdentity: SupportUser,
        applicationLogs: [ApplicationLog] = []
    ) {
        self.onDismiss = onDismiss
        self.supportIdentity = supportIdentity
        self.applicationLogs = applicationLogs
    }

    public var body: some View {
        Form {
            // Support Area Selection
            supportAreaSection

            // Issue Details Section
            issueDetailsSection

            // Screenshots Section
            ScreenshotPicker(
                attachedImageUrls: $selectedPhotos
            )

            // Application Logs Section
            ApplicationLogPicker(
                includeApplicationLogs: $includeApplicationLogs
            )

            // Contact Information Section
            contactInformationSection

            // Submit Button Section
            submitButtonSection
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(Localization.errorTitle, isPresented: $shouldShowErrorAlert) {
            Button(Localization.gotIt) {
                shouldShowErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
        .alert(Localization.supportRequestSent, isPresented: $shouldShowSuccessAlert) {
            Button(Localization.gotIt) {
                shouldShowSuccessAlert = false
                onDismiss?()
            }
        } message: {
            Text(Localization.supportRequestSentMessage)
        }
    }
}

// MARK: - View Sections
private extension SupportForm {

    /// Support area selection section
    @ViewBuilder
    var supportAreaSection: some View {
        Group {
            Section {
            } header: {
                Text(Localization.iNeedHelp)
            } footer: {
                VStack {
                    ForEach(areas, id: \.id) { area in
                        SupportAreaRow(
                            area: area,
                            isSelected: isAreaSelected(area)
                        ) {
                            selectArea(area)
                        }
                    }
                }.listRowInsets(.zero)

            }
        }.padding(.bottom, 10)
    }

    /// Contact information section
    @ViewBuilder
    var contactInformationSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("We'll email you at this address.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProfileView(user: supportIdentity)
            }
        } header: {
            Text(Localization.contactInformation)
        }
        .listRowSeparator(.hidden)
        .listRowSpacing(0)
    }

    /// Issue details section
    @ViewBuilder
    var issueDetailsSection: some View {
        Section {
            // Subject field
            VStack(alignment: .leading) {
                Text(Localization.subject)
                    .onTapGesture { focusedField = .subject }

                TextField(Localization.subjectPlaceholder, text: $subject)
                    .focused($focusedField, equals: .subject)
            }

            // Site Address field (optional)
            VStack(alignment: .leading) {
                Text(Localization.siteAddress + " " + Localization.optional)
                    .onTapGesture { focusedField = .siteAddress }

                TextField(Localization.siteAddressPlaceholder, text: $siteAddress)
                    .multilineTextAlignment(.leading)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .siteAddress)
            }
        } header: {
            Text(Localization.issueDetails)
        }

        Section(Localization.message) {
            textEditor
        }
    }

    @ViewBuilder
    var textEditor: some View {
        if #available(iOS 26.0, *) {
            TextEditor(text: $attributedProblemDescription)
                .focused($focusedField, equals: .problemDescription)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 120)
        } else {
            TextEditor(text: $plainTextProblemDescription)
                .focused($focusedField, equals: .problemDescription)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 120)
        }
    }

    /// Submit button section
    @ViewBuilder
    var submitButtonSection: some View {
        Section {
            Button {
                submitSupportRequest()
            } label: {
                HStack {
                    if showLoadingIndicator {
                        ProgressView().tint(Color.white)
                    }
                    Text(Localization.submitRequest)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(submitButtonDisabled || showLoadingIndicator)
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSpacing(0)
        }
        .background(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Helper Methods
private extension SupportForm {

    /// Selects a support area
    func selectArea(_ area: SupportFormArea) {
        selectedArea = area
    }

    /// Determines if the given area is selected
    func isAreaSelected(_ area: SupportFormArea) -> Bool {
        selectedArea == area
    }

    private func getText() throws -> String {
        if #available(iOS 26.0, *) {
            return self.attributedProblemDescription.toHtml()
        } else {
            return self.plainTextProblemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Submits the support request
    func submitSupportRequest() {
        guard !submitButtonDisabled else { return }

        showLoadingIndicator = true

        Task {
            do {
                _ = try await self.dataProvider.createSupportConversation(
                    subject: self.subject,
                    message: self.getText(),
                    user: self.supportIdentity,
                    attachments: []
                )

                await MainActor.run {
                    showLoadingIndicator = false
                    shouldShowSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    errorMessage = error.localizedDescription
                    shouldShowErrorAlert = true
                }
            }
        }
    }

    /// Formats dates for display
    func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Field Focus Management
private extension SupportForm {
    /// Enum for managing field focus states
    enum Field: Hashable {
        case fullName
        case emailAddress
        case subject
        case siteAddress
        case problemDescription
    }
}

// MARK: - Support Area Row Component
struct SupportAreaRow: View {
    let area: SupportFormArea
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: area.systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(area.title)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: self.action)
    }
}

// MARK: - Support Form Area System Images Extension
private extension SupportFormArea {
    var systemImage: String {
        switch self.id {
        case "application":
            return "app.badge"
        case "jetpack_connection":
            return "powerplug"
        case "site_management":
            return "globe"
        case "billing":
            return "creditcard"
        case "technical":
            return "wrench.and.screwdriver"
        case "other":
            return "questionmark.circle"
        default:
            return "questionmark.circle"
        }
    }
}

// MARK: - Previews
#Preview {
    NavigationStack {
        SupportForm(
            supportIdentity: SupportDataProvider.supportUser,
            applicationLogs: [SupportDataProvider.applicationLog]
        )
    }
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // Close action for preview
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    .environmentObject(SupportDataProvider.testing)
}
