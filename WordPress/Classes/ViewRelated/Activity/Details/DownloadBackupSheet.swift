import SwiftUI
import WordPressKit
import WordPressShared

struct DownloadBackupSheet: View {
    let activity: Activity
    let blog: Blog
    
    @StateObject private var viewModel: DownloadBackupViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(activity: Activity, blog: Blog) {
        self.activity = activity
        self.blog = blog
        self._viewModel = StateObject(wrappedValue: DownloadBackupViewModel(activity: activity, blog: blog))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.state == .loading || viewModel.state == .success || viewModel.state == .failure {
                    progressView
                } else {
                    downloadOptionsView
                }
            }
            .navigationTitle(Strings.downloadTitle)
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
            WPAnalytics.track(.backupDownloadOpened, properties: ["source": "activity_detail"])
        }
    }
    
    @ViewBuilder
    private var downloadOptionsView: some View {
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
                
                // Download Options
                VStack(alignment: .leading, spacing: 16) {
                    Text(Strings.optionsTitle)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        DownloadOptionRow(
                            title: Strings.optionThemes,
                            isSelected: $viewModel.includeThemes
                        )
                        Divider().padding(.leading, 44)
                        
                        DownloadOptionRow(
                            title: Strings.optionPlugins,
                            isSelected: $viewModel.includePlugins
                        )
                        Divider().padding(.leading, 44)
                        
                        DownloadOptionRow(
                            title: Strings.optionUploads,
                            isSelected: $viewModel.includeUploads
                        )
                        Divider().padding(.leading, 44)
                        
                        DownloadOptionRow(
                            title: Strings.optionContent,
                            subtitle: Strings.optionContentSubtitle,
                            isSelected: $viewModel.includeContent
                        )
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
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
                viewModel.downloadBackup()
                WPAnalytics.track(.backupDownloadConfirmed, properties: ["source": "activity_detail"])
            }) {
                Text(Strings.confirmDownload)
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.hasSelection ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.hasSelection)
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
                        Text(Strings.preparingTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(Strings.preparingMessage)
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
                        
                        if let downloadURL = viewModel.downloadURL {
                            Link(destination: URL(string: downloadURL)!) {
                                Text(Strings.downloadLink)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 8)
                        }
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

// MARK: - Download Option Row

private struct DownloadOptionRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let downloadTitle = NSLocalizedString(
        "download.sheet.title",
        value: "Download Backup",
        comment: "Title for the download backup sheet"
    )
    
    static let cancel = NSLocalizedString(
        "download.sheet.cancel",
        value: "Cancel",
        comment: "Cancel button for download sheet"
    )
    
    static let optionsTitle = NSLocalizedString(
        "download.sheet.options.title",
        value: "Choose items to download",
        comment: "Title for download options section"
    )
    
    static let optionThemes = NSLocalizedString(
        "download.sheet.option.themes",
        value: "Themes",
        comment: "Option to download themes"
    )
    
    static let optionPlugins = NSLocalizedString(
        "download.sheet.option.plugins",
        value: "Plugins",
        comment: "Option to download plugins"
    )
    
    static let optionUploads = NSLocalizedString(
        "download.sheet.option.uploads",
        value: "Media uploads",
        comment: "Option to download media uploads"
    )
    
    static let optionContent = NSLocalizedString(
        "download.sheet.option.content",
        value: "Content",
        comment: "Option to download content"
    )
    
    static let optionContentSubtitle = NSLocalizedString(
        "download.sheet.option.content.subtitle",
        value: "Posts, pages, and comments",
        comment: "Subtitle for content option"
    )
    
    static let infoTitle = NSLocalizedString(
        "download.sheet.info.title",
        value: "About backup downloads",
        comment: "Info section title in download sheet"
    )
    
    static let infoMessage = NSLocalizedString(
        "download.sheet.info.message",
        value: "Your backup will be prepared as a downloadable file. You'll receive an email with the download link when it's ready.",
        comment: "Information about the download process"
    )
    
    static let confirmDownload = NSLocalizedString(
        "download.sheet.confirm.button",
        value: "Create downloadable file",
        comment: "Confirm button for download action"
    )
    
    static let preparingTitle = NSLocalizedString(
        "download.sheet.preparing.title",
        value: "Preparing Your Backup",
        comment: "Title shown while backup is being prepared"
    )
    
    static let preparingMessage = NSLocalizedString(
        "download.sheet.preparing.message",
        value: "We're creating a downloadable backup file. This may take a few moments.",
        comment: "Message shown while backup is being prepared"
    )
    
    static let successTitle = NSLocalizedString(
        "download.sheet.success.title",
        value: "Backup Ready!",
        comment: "Title shown when backup is ready"
    )
    
    static let successMessage = NSLocalizedString(
        "download.sheet.success.message",
        value: "Your backup has been prepared. You'll receive an email with the download link shortly.",
        comment: "Message shown when backup is ready"
    )
    
    static let downloadLink = NSLocalizedString(
        "download.sheet.success.link",
        value: "Download now",
        comment: "Link to download the backup"
    )
    
    static let failureTitle = NSLocalizedString(
        "download.sheet.failure.title",
        value: "Backup Failed",
        comment: "Title shown when backup preparation fails"
    )
    
    static let failureMessage = NSLocalizedString(
        "download.sheet.failure.message",
        value: "We couldn't prepare your backup. Please try again or contact support if the problem persists.",
        comment: "Message shown when backup preparation fails"
    )
    
    static let done = NSLocalizedString(
        "download.sheet.done.button",
        value: "Done",
        comment: "Done button to dismiss the sheet"
    )
}