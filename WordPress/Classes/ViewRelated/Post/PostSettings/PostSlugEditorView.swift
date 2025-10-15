import SwiftUI
import WordPressData

@MainActor
struct PostSlugEditorView: View {
    @Binding var slug: String
    let post: AbstractPost
    
    @FocusState private var isFocused: Bool
    @Environment(\.openURL) private var openURL
    
    private var permalinkURL: String {
        guard let blog = post.blog,
              let blogURL = blog.url,
              !blogURL.isEmpty else {
            return ""
        }
        
        let baseURL = blogURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let slugToUse = effectiveSlug
        
        // Try to use the blog's permalink structure if available
        if let permalinkStructure = blog.options?["permalink_structure"] as? String,
           !permalinkStructure.isEmpty {
            return constructPermalinkWithStructure(baseURL: baseURL, structure: permalinkStructure, slug: slugToUse)
        } else {
            // Fallback to common WordPress permalink structure
            return constructDefaultPermalink(baseURL: baseURL, slug: slugToUse)
        }
    }
    
    private var basePermalinkURL: String {
        guard let blog = post.blog,
              let blogURL = blog.url,
              !blogURL.isEmpty else {
            return ""
        }
        
        let baseURL = blogURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Try to use the blog's permalink structure if available
        if let permalinkStructure = blog.options?["permalink_structure"] as? String,
           !permalinkStructure.isEmpty {
            return constructBasePermalinkWithStructure(baseURL: baseURL, structure: permalinkStructure)
        } else {
            // Fallback to common WordPress permalink structure
            return constructDefaultBasePermalink(baseURL: baseURL)
        }
    }
    
    private var effectiveSlug: String {
        if !slug.isEmpty {
            return slug
        } else if let postTitle = post.postTitle, !postTitle.isEmpty {
            return sanitizeSlug(postTitle)
        } else {
            return "untitled"
        }
    }
    
    // MARK: - Permalink Construction Helpers
    
    private func constructPermalinkWithStructure(baseURL: String, structure: String, slug: String) -> String {
        let postDate = post.dateCreated ?? Date()
        let calendar = Calendar.current
        
        var permalink = structure
        permalink = permalink.replacingOccurrences(of: "%year%", with: String(calendar.component(.year, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%monthnum%", with: String(format: "%02d", calendar.component(.month, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%day%", with: String(format: "%02d", calendar.component(.day, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%hour%", with: String(format: "%02d", calendar.component(.hour, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%minute%", with: String(format: "%02d", calendar.component(.minute, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%second%", with: String(format: "%02d", calendar.component(.second, from: postDate)))
        permalink = permalink.replacingOccurrences(of: "%postname%", with: slug)
        
        // Handle post ID if available
        if let postID = post.postID {
            permalink = permalink.replacingOccurrences(of: "%post_id%", with: String(postID.intValue))
        }
        
        return "\(baseURL)\(permalink)"
    }
    
    private func constructBasePermalinkWithStructure(baseURL: String, structure: String) -> String {
        let postDate = post.dateCreated ?? Date()
        let calendar = Calendar.current
        
        var basePermalink = structure
        basePermalink = basePermalink.replacingOccurrences(of: "%year%", with: String(calendar.component(.year, from: postDate)))
        basePermalink = basePermalink.replacingOccurrences(of: "%monthnum%", with: String(format: "%02d", calendar.component(.month, from: postDate)))
        basePermalink = basePermalink.replacingOccurrences(of: "%day%", with: String(format: "%02d", calendar.component(.day, from: postDate)))
        basePermalink = basePermalink.replacingOccurrences(of: "%hour%", with: String(format: "%02d", calendar.component(.hour, from: postDate)))
        basePermalink = basePermalink.replacingOccurrences(of: "%minute%", with: String(format: "%02d", calendar.component(.minute, from: postDate)))
        basePermalink = basePermalink.replacingOccurrences(of: "%second%", with: String(format: "%02d", calendar.component(.second, from: postDate)))
        
        // Handle post ID if available
        if let postID = post.postID {
            basePermalink = basePermalink.replacingOccurrences(of: "%post_id%", with: String(postID.intValue))
        }
        
        // Remove the postname placeholder to get the base
        basePermalink = basePermalink.replacingOccurrences(of: "%postname%", with: "")
        
        return "\(baseURL)\(basePermalink)"
    }
    
    private func constructDefaultPermalink(baseURL: String, slug: String) -> String {
        let postDate = post.dateCreated ?? Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: postDate)
        let month = String(format: "%02d", calendar.component(.month, from: postDate))
        let day = String(format: "%02d", calendar.component(.day, from: postDate))
        
        return "\(baseURL)/\(year)/\(month)/\(day)/\(slug)/"
    }
    
    private func constructDefaultBasePermalink(baseURL: String) -> String {
        let postDate = post.dateCreated ?? Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: postDate)
        let month = String(format: "%02d", calendar.component(.month, from: postDate))
        let day = String(format: "%02d", calendar.component(.day, from: postDate))
        
        return "\(baseURL)/\(year)/\(month)/\(day)/"
    }
    
    private func sanitizeSlug(_ title: String) -> String {
        return title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    // MARK: - View Body
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Customize the last part of the Permalink.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        // Open learn more URL - you can customize this URL as needed
                        if let url = URL(string: "https://wordpress.com/support/permalinks/") {
                            openURL(url)
                        }
                    } label: {
                        Label("Learn more", systemImage: "arrow.up.right")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section {
                HStack {
                    TextField(Strings.slugPlaceholder, text: $slug)
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button {
                        UIPasteboard.general.string = slug
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .disabled(slug.isEmpty)
                }
            }
            
            Section("Permalink") {
                Button {
                    if let url = URL(string: permalinkURL) {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 0) {
                        Text(basePermalinkURL)
                            .foregroundColor(.accentColor)
                        Text(effectiveSlug)
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(0.1))
                                    .padding(.horizontal, -2)
                                    .padding(.vertical, -1)
                            )
                        
                        // Add trailing slash if the permalink structure ends with one
                        if permalinkURL.hasSuffix("/") {
                            Text("/")
                                .foregroundColor(.accentColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle(Strings.slugLabel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Strings

private enum Strings {
    static let slugLabel = NSLocalizedString(
        "postSettings.slug.label",
        value: "Slug",
        comment: "Label for the slug field. Should be the same as WP core."
    )
    
    static let slugPlaceholder = NSLocalizedString(
        "postSettings.slug.placeholder",
        value: "Enter slug",
        comment: "Placeholder for the slug field"
    )
}