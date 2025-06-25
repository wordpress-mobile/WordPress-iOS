import SwiftUI
import WordPressUI

struct PostSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasChanges = false

    // Post data
    @State private var publishDate = Date(timeIntervalSince1970: 1750334820) // Jun 17, 2025 at 5:07 PM
    @State private var visibility = "Public"
    @State private var featuredImage: UIImage? = nil
    @State private var categories = "Uncategorized"
    @State private var tags = ""
    @State private var isSticky = false
    @State private var postFormat = "Standard"
    @State private var slug = "hello-world"
    @State private var excerpt = ""

    // Social
    @State private var showSocialCard = true
    @State private var connectedAccounts: [SocialAccount] = []

    // Navigation states
    @State private var showPublishDatePicker = false
    @State private var showCategories = false
    @State private var showTags = false
    @State private var showPostFormat = false
    @State private var showImagePicker = false
    
    let tagSuggestions = [
        "WordPress",
        "Blogging",
        "Technology",
        "Design",
        "Tutorial",
        "Development"
    ]
    
    var availableTagSuggestions: [String] {
        let currentTagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return tagSuggestions.filter { !currentTagList.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Publish Section
                    CardView("Publish") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "Publish Date",
                                value: formatDate(publishDate),
                                action: { showPublishDatePicker = true }
                            )

                            VisibilityRow(
                                value: $visibility
                            )
                        }
                    }

                    // Featured Image Section
                    CardView("Featured Image") {
                        FeaturedImageRow(image: featuredImage) {
                            showImagePicker = true
                        }
                    }

                    // Taxonomy Section
                    CardView("Taxonomy") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "Categories",
                                value: categories,
                                action: { showCategories = true }
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                SettingsRow(
                                    title: "Tags",
                                    value: tags.isEmpty ? "Add tags" : tags,
                                    action: { showTags = true }
                                )
                                
                                // Tag Suggestions
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                        Text("Suggestions")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(availableTagSuggestions, id: \.self) { suggestion in
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        addTag(suggestion)
                                                    }
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "plus")
                                                            .font(.system(size: 10, weight: .semibold))
                                                        Text(suggestion)
                                                            .font(.subheadline)
                                                    }
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color(UIColor.secondarySystemFill))
                                                    .foregroundColor(.primary)
                                                    .clipShape(Capsule())
                                                }
                                                .transition(.asymmetric(
                                                    insertion: .opacity.combined(with: .scale),
                                                    removal: .opacity.combined(with: .scale(scale: 0.8))
                                                ))
                                            }
                                        }
                                        .padding(.trailing, 16) // Add padding to the right for scroll content
                                    }
                                    .padding(.horizontal, -16) // Negative padding to extend to card edges
                                    .padding(.leading, 16) // Re-add left padding for content
                                }
                            }
                        }
                    }

                    // Jetpack Social Section
                    if showSocialCard {
                        CardView("Jetpack Social") {
                            SocialConnectionCard()
                        }
                    }

                    // More Options Section
                    CardView("More Options") {
                        VStack(spacing: 12) {
                            ToggleRow(
                                title: "Sticky",
                                subtitle: "Show at the top of the list",
                                isOn: $isSticky
                            )

                            SettingsRow(
                                title: "Post Format",
                                value: postFormat,
                                action: { showPostFormat = true }
                            )

                            SlugRow(
                                value: $slug
                            )

                            ExcerptRow(
                                value: $excerpt
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
//                .background(Color(.secondarySystemBackground))
            }
            .background(Color(.init(fromHex: 0xFCFCFC)))
            .navigationTitle("Post Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showPublishDatePicker) {
                PublishDatePickerView(date: $publishDate)
            }
            .navigationDestination(isPresented: $showCategories) {
                CategoriesView(selectedCategory: $categories)
            }
            .navigationDestination(isPresented: $showTags) {
                TagsView(tags: $tags)
            }
            .navigationDestination(isPresented: $showPostFormat) {
                PostFormatView(selectedFormat: $postFormat)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $featuredImage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(AppColor.tint)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
//                    .font(.body.weight(.semibold))
//                    .foregroundColor(AppColor.tint)
//                    .disabled(!hasChanges)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func addTag(_ tag: String) {
        let currentTags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentTags.isEmpty {
            tags = tag
        } else {
            // Check if tag already exists
            let tagList = currentTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !tagList.contains(tag) {
                tags = currentTags + ", " + tag
            }
        }
    }
}

// MARK: - Components

struct SettingsRow: View {
    let title: String
    let value: String?
    let action: () -> Void

    var isPlaceholder: Bool {
        value == "Add tags" || value == "Write an excerpt"
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let value {
                        Text(value)
                            .font(.subheadline.weight(.regular))
                            .foregroundColor(isPlaceholder ? Color(UIColor.tertiaryLabel) : AppColor.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.vertical, 4)
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(AppColor.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct VisibilityRow: View {
    @Binding var value: String

    let options: [(name: String, subtitle: String)] = [
        ("Public", "Visible to everyone"),
        ("Private", "Only visible to site admins and editors"),
        ("Password Protected", "Visible to everyone but requires a password")
    ]

    var currentSubtitle: String {
        options.first { $0.name == value }?.subtitle ?? ""
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.name) { option in
                Button(action: {
                    value = option.name
                }) {
                    Text(option.name)
                        .foregroundColor(.primary)
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visibility")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(value)
                            .font(.subheadline.weight(.regular))
                            .foregroundColor(AppColor.secondary)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColor.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
    }
}

struct SlugRow: View {
    @Binding var value: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Slug")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            TextField("post-slug", text: $value)
                .font(.subheadline.weight(.regular))
                .foregroundColor(AppColor.secondary)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
        }
        .padding(.vertical, 4)
    }
}

struct ExcerptRow: View {
    @Binding var value: String
    @State private var isGenerating = false
    @State private var shimmerOffset: CGFloat = -150
    @State private var sparkleRotation = 0.0
    @State private var textOpacity = 1.0
    @FocusState private var isFocused: Bool
    @State private var isPlaceholderHidden = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excerpt")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            ZStack {
                // Main text editor
                ZStack(alignment: .topLeading) {
                    if !isPlaceholderHidden && value.isEmpty && !isGenerating {
                        Text("Write an excerpt")
                            .font(.subheadline.weight(.regular))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $value)
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(.secondary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 4)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(UIColor.separator).opacity(0.8), lineWidth: 0.5)
                        )
                        .frame(height: 88) // Approximately 4 lines
                        .focused($isFocused)
                        .opacity(isGenerating ? 0.3 : textOpacity)
                        .disabled(isGenerating)
                }
                
                // Generating overlay
                if isGenerating {
                    ZStack {
                        // Background with shimmer
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.secondarySystemFill).opacity(0.4))
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 100)
                                .offset(x: shimmerOffset)
                                .animation(
                                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                                    value: shimmerOffset
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        VStack(spacing: 4) {
                            // Single gray sparkle
                            Image(systemName: "sparkle")
                                .font(.system(size: 26))
                                .rotationEffect(.degrees(sparkleRotation))
                            
                            Text("Generating...")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .frame(height: 88)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
            }
            
            HStack {
                Button(action: generateExcerpt) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                        Text("Generate")
                            .font(.subheadline.weight(.medium))
                    }
                }
//                .buttonStyle(.)
                .tint(Color.accentColor)
                .disabled(isGenerating)
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    private func generateExcerpt() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isGenerating = true
            textOpacity = 0
            value = "" // Clear existing text
        }
        
        // Start shimmer animation
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 150
        }
        
        // Rotate sparkle slowly
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            sparkleRotation = 360
        }
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Reset animations
            shimmerOffset = -150
            sparkleRotation = 0
            isPlaceholderHidden = true

            // Set the generated text
            let generatedText = "This blog post explores the fundamental concepts of modern web development, including responsive design, accessibility best practices, and performance optimization techniques that every developer should know."
            
            // First hide the overlay
            withAnimation(.easeOut(duration: 0.3)) {
                isGenerating = false
            }
            
            // Then fade in the new text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                value = generatedText
                withAnimation(.easeIn(duration: 0.8)) {
                    textOpacity = 1.0
                }
            }
        }
    }
}

struct FeaturedImageRow: View {
    let image: UIImage?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(6)
            } else {
                ZStack {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)

                        Text("Set Featured Image")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SocialConnectionCard: View {
    var body: some View {
        VStack(spacing: 12) {
            // Social icons
            HStack(spacing: -6) {
                ForEach(socialIcons, id: \.self) { icon in
                    Image(systemName: icon.systemName)
                        .font(.system(size: 14))
                        .frame(width: 28, height: 28)
                        .background(icon.color)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                        )
                }
            }

            Text("Increase your traffic by auto-sharing your posts with your friends on social media.")
                .font(.subheadline)
                .foregroundColor(AppColor.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                Button("Connect accounts") {
                    // Handle connect
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.accentColor)

                Button("Not now") {
                    // Handle dismiss
                }
                .font(.subheadline)
                .foregroundColor(AppColor.secondary)
            }
        }
    }
}

// MARK: - Models

struct SocialAccount: Identifiable {
    let id = UUID()
    let service: String
    let username: String
    let isEnabled: Bool
}

struct SocialIcon: Hashable, Identifiable {
    var id: SocialIcon { self }
    let systemName: String
    let color: Color
}

let socialIcons = [
    SocialIcon(systemName: "bird.fill", color: .blue),
    SocialIcon(systemName: "f.square.fill", color: Color(red: 59 / 255, green: 89 / 255, blue: 152 / 255)),
    SocialIcon(systemName: "camera.fill", color: Color(red: 225 / 255, green: 48 / 255, blue: 108 / 255)),
    SocialIcon(systemName: "link", color: Color(red: 0 / 255, green: 119 / 255, blue: 181 / 255)),
    SocialIcon(systemName: "m.square.fill", color: Color(red: 143 / 255, green: 95 / 255, blue: 234 / 255)),
    SocialIcon(systemName: "n.square.fill", color: Color(red: 130 / 255, green: 190 / 255, blue: 0 / 255)),
    SocialIcon(systemName: "t.square.fill", color: .black),
    SocialIcon(systemName: "t.square.fill", color: .black)
]

// MARK: - Placeholder Navigation Views

struct PublishDatePickerView: View {
    @Binding var date: Date
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()
    @State private var showTimePicker = false

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter
    }

    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    var timeZoneFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Combined Date Section
                CardView {
                    VStack(spacing: 20) {
                        // Header
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(AppColor.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Publish Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(dateFormatter.string(from: date)) (\(TimeZone.current.abbreviation() ?? ""))")
                                    .font(.subheadline)
                                    .foregroundColor(AppColor.secondary)
                            }
                            Spacer()
                        }
                        .allowsHitTesting(false) // Makes it non-interactive

                        // Calendar
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()

                        VStack(spacing: 16) {
                            HStack {
                                Text("Time")
                                    .font(.headline)

                                Spacer()

                                Text(timeFormatter.string(from: date))
                                    .font(.body)
                                    .foregroundColor(AppColor.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        withAnimation {
                                            showTimePicker.toggle()
                                        }
                                    }
                            }

                            if showTimePicker {
                                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .frame(height: 150)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Time Zone Warning (outside cards)
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(AppColor.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("The date in your current time zone:")
                            .font(.caption)
                            .foregroundColor(AppColor.secondary)
                        Text("\(dateFormatter.string(from: date.addingTimeInterval(-3 * 3600))) (GMT-4)")
                            .font(.caption)
                            .foregroundColor(AppColor.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

                // Time Zone Section
                CardView {
                    HStack {
                        Text("Time Zone")
                            .font(.body.weight(.medium))

                        Spacer()

                        Text("\(TimeZone.current.abbreviation() ?? "PT") (\(TimeZone.current.abbreviation() ?? "GMT-7"))")
                            .font(.body)
                            .foregroundColor(AppColor.secondary)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .navigationTitle("Publish Date")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Post Settings")
                    }
                }
                .foregroundColor(AppColor.tint)
            }
        }
    }
}

struct CategoriesView: View {
    @Binding var selectedCategory: String
    @Environment(\.dismiss) var dismiss

    let categories = ["Uncategorized", "News", "Updates", "Tutorials", "Announcements"]

    var body: some View {
        List(categories, id: \.self) { category in
            HStack {
                Text(category)
                Spacer()
                if selectedCategory == category {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedCategory = category
                dismiss()
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TagsView: View {
    @Binding var tags: String
    @Environment(\.dismiss) var dismiss
    
    let tagSuggestions = [
        "WordPress",
        "Blogging",
        "Technology",
        "Design",
        "Tutorial",
        "Development"
    ]
    
    var availableTagSuggestions: [String] {
        let currentTagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return tagSuggestions.filter { !currentTagList.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)

            TextField("Add tags separated by commas", text: $tags)
                .textFieldStyle(.roundedBorder)

            Text("Separate tags with commas")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Tag Suggestions
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                    Text("Suggestions")
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
                .opacity(0.4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableTagSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    addTag(suggestion)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(suggestion)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.secondarySystemFill))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale),
                                removal: .opacity.combined(with: .scale(scale: 0.8))
                            ))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
    
    private func addTag(_ tag: String) {
        let currentTags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentTags.isEmpty {
            tags = tag
        } else {
            // Check if tag already exists
            let tagList = currentTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !tagList.contains(tag) {
                tags = currentTags + ", " + tag
            }
        }
    }
}

struct PostFormatView: View {
    @Binding var selectedFormat: String
    @Environment(\.dismiss) var dismiss

    let formats = ["Standard", "Aside", "Gallery", "Link", "Image", "Quote", "Status", "Video", "Audio", "Chat"]

    var body: some View {
        List(formats, id: \.self) { format in
            HStack {
                Text(format)
                Spacer()
                if selectedFormat == format {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedFormat = format
                dismiss()
            }
        }
        .navigationTitle("Post Format")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ImagePickerView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Image Picker")
                    .font(.title)
                Text("(Image picker implementation would go here)")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Select Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PostSettingsView()
        .tint(AppColor.primary)
}
