import SwiftUI
import WordPressKit
import WordPressShared

struct RestoreBackupSheet: View {
    let activity: Activity
    let site: JetpackSiteRef
    
    @StateObject private var viewModel: RestoreBackupViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(activity: Activity, site: JetpackSiteRef) {
        self.activity = activity
        self.site = site
        self._viewModel = StateObject(wrappedValue: RestoreBackupViewModel(activity: activity, site: site))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.state == .loading || viewModel.state == .success || viewModel.state == .failure {
                    progressView
                } else {
                    confirmationView
                }
            }
            .navigationTitle(Strings.restoreTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.state == .idle {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(Strings.cancel) {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.state == .loading)
        }
        .onAppear {
            WPAnalytics.track(.restoreOpened, properties: ["source": "activity_detail"])
        }
    }
    
    @ViewBuilder
    private var confirmationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Activity Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        if let icon = activity.icon {
                            Image(uiImage: icon)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(Color(activity.statusColor))
                                .padding(12)
                                .background(Color(activity.statusColor).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.summary)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text(formattedDate)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if !activity.text.isEmpty {
                        Text(activity.text)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Warning Section
                VStack(alignment: .leading, spacing: 12) {
                    Label(Strings.warningTitle, systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(Strings.warningMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.infoTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(Strings.infoMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        
        Spacer()
        
        // Bottom Action Button
        VStack(spacing: 16) {
            Divider()
            
            Button(action: {
                viewModel.restore()
                WPAnalytics.track(.restoreConfirmed, properties: ["source": "activity_detail"])
            }) {
                Text(Strings.confirmRestore)
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            switch viewModel.state {
            case .loading:
                VStack(spacing: 24) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    VStack(spacing: 8) {
                        Text(Strings.restoringTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(String(format: Strings.restoringMessage, formattedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
            case .success:
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 8) {
                        Text(Strings.successTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(Strings.successMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
            case .failure:
                VStack(spacing: 24) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    VStack(spacing: 8) {
                        Text(Strings.failureTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(viewModel.errorMessage ?? Strings.failureMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
            default:
                EmptyView()
            }
            
            Spacer()
            
            if viewModel.state == .success || viewModel.state == .failure {
                Button(action: {
                    dismiss()
                }) {
                    Text(Strings.done)
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.published)
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let restoreTitle = NSLocalizedString(
        "restore.sheet.title",
        value: "Restore Site",
        comment: "Title for the restore backup sheet"
    )
    
    static let cancel = NSLocalizedString(
        "restore.sheet.cancel",
        value: "Cancel",
        comment: "Cancel button for restore sheet"
    )
    
    static let warningTitle = NSLocalizedString(
        "restore.sheet.warning.title",
        value: "Warning",
        comment: "Warning section title in restore sheet"
    )
    
    static let warningMessage = NSLocalizedString(
        "restore.sheet.warning.message",
        value: "Restoring your site will revert all content, settings, and configurations to this backup point. Any changes made after this backup will be lost.",
        comment: "Warning message about restore consequences"
    )
    
    static let infoTitle = NSLocalizedString(
        "restore.sheet.info.title",
        value: "What happens next",
        comment: "Info section title in restore sheet"
    )
    
    static let infoMessage = NSLocalizedString(
        "restore.sheet.info.message",
        value: "The restore process typically takes a few minutes. You'll receive a notification when it's complete. Your site may be temporarily unavailable during the restore.",
        comment: "Information about the restore process"
    )
    
    static let confirmRestore = NSLocalizedString(
        "restore.sheet.confirm.button",
        value: "Restore to This Point",
        comment: "Confirm button for restore action"
    )
    
    static let restoringTitle = NSLocalizedString(
        "restore.sheet.restoring.title",
        value: "Restoring Your Site",
        comment: "Title shown while restore is in progress"
    )
    
    static let restoringMessage = NSLocalizedString(
        "restore.sheet.restoring.message",
        value: "We're restoring your site back to %1$@",
        comment: "Message shown while restore is in progress. %1$@ is the backup date"
    )
    
    static let successTitle = NSLocalizedString(
        "restore.sheet.success.title",
        value: "Restore Complete!",
        comment: "Title shown when restore succeeds"
    )
    
    static let successMessage = NSLocalizedString(
        "restore.sheet.success.message",
        value: "Your site has been successfully restored. It may take a few moments for all changes to appear.",
        comment: "Message shown when restore succeeds"
    )
    
    static let failureTitle = NSLocalizedString(
        "restore.sheet.failure.title",
        value: "Restore Failed",
        comment: "Title shown when restore fails"
    )
    
    static let failureMessage = NSLocalizedString(
        "restore.sheet.failure.message",
        value: "We couldn't restore your site. Please try again or contact support if the problem persists.",
        comment: "Message shown when restore fails"
    )
    
    static let done = NSLocalizedString(
        "restore.sheet.done.button",
        value: "Done",
        comment: "Done button to dismiss the sheet"
    )
}