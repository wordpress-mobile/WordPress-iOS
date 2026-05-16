import SwiftUI
import UIKit

struct MediaLibraryView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    let tracker: any MediaTracker

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var searchText: String = ""
    /// Incremented by the Retry button. A `.task(id: retryToken)` modifier
    /// listens for changes; the initial value 0 is ignored so we don't
    /// re-fire refresh on appearance (the filter-driven `.task(id:)` already
    /// covers initial load). Switching to a SwiftUI-owned token keeps Retry
    /// inside the same cancellation lifecycle as filter / search / observer
    /// tasks — an unstructured `Task { … }` from the button action would
    /// outlive view dismantle.
    @State private var retryToken: Int = 0
    @State private var activePicker: ActivePicker?
    @State private var isPresentingUploads = false

    private enum ActivePicker: Identifiable {
        case photoLibrary, takePhoto, takeVideo, chooseFile
        var id: Self { self }
    }

    private var spacing: CGFloat { viewModel.isAspectRatioModeEnabled ? 8 : 2 }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: sizeClass == .regular ? 5 : 4
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let summary = viewModel.bannerSummary {
                BannerView(summary: summary) {
                    isPresentingUploads = true
                }
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(viewModel.items) { item in
                        MediaGridCell(
                            item: item,
                            isAspectRatioMode: viewModel.isAspectRatioModeEnabled
                        )
                        // Cell-scoped pagination trigger. SwiftUI cancels
                        // this task on cell disappear AND on view dismantle.
                        .task(id: item.id) {
                            await viewModel.loadNextPageIfNeeded(after: item)
                        }
                    }
                }
                .padding(.top, spacing)
                .animation(.default, value: viewModel.isAspectRatioModeEnabled)
            }
            .refreshable { await viewModel.refresh(pullToRefresh: true) }
            .task { tracker.track(.mediaLibraryOpened) }
            .task(id: viewModel.filter) { await viewModel.refresh() }
            .task(id: viewModel.filter) { await viewModel.handleDataChanges() }
            .task(id: searchText) {
                // SwiftUI cancels this on every searchText change and on
                // view dismantle. try-await propagates cancellation so the
                // setFilter hop never fires after dismissal or mid-typing.
                do {
                    try await Task.sleep(for: .milliseconds(300))
                } catch {
                    return
                }
                viewModel.setFilter(viewModel.filter.with(search: searchText))
            }
            .task(id: retryToken) {
                // Skip the initial value — first appearance is driven by the
                // `.task(id: viewModel.filter)` modifier above.
                guard retryToken > 0 else { return }
                await viewModel.refresh()
            }
            .navigationTitle(Strings.title)
            .searchable(text: $searchText, prompt: Strings.searchPrompt)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .toolbar {
                filterMenu
                addMenu
            }
            .overlay { contentOverlay }
        }
        // `MediaLibraryView` is hosted in a UIKit `UINavigationController`
        // via `UIHostingController`, so there's no SwiftUI `NavigationStack`
        // ancestor for `.navigationDestination` to push into. Present the
        // Uploads queue as a sheet instead — it's a self-contained
        // management surface (its own toolbar + bulk menu) and survives
        // the SwiftUI/UIKit boundary cleanly.
        .sheet(isPresented: $isPresentingUploads) {
            NavigationStack {
                UploadsView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(Strings.uploadsScreenClose) {
                                isPresentingUploads = false
                            }
                        }
                    }
            }
        }
        .sheet(item: $activePicker) { picker in
            switch picker {
            case .photoLibrary:
                PhotosPickerRepresentable(
                    onPicked: { sources in
                        activePicker = nil
                        Task { await viewModel.enqueue(sources: sources) }
                    },
                    onCancel: { activePicker = nil }
                )
                .ignoresSafeArea()
            case .takePhoto:
                CameraPickerRepresentable(
                    mode: .photo,
                    onPicked: { source in
                        activePicker = nil
                        Task { await viewModel.enqueue(sources: [source]) }
                    },
                    onCancel: { activePicker = nil }
                )
                .ignoresSafeArea()
            case .takeVideo:
                CameraPickerRepresentable(
                    mode: .video,
                    onPicked: { source in
                        activePicker = nil
                        Task { await viewModel.enqueue(sources: [source]) }
                    },
                    onCancel: { activePicker = nil }
                )
                .ignoresSafeArea()
            case .chooseFile:
                EmptyView()
                    .fileImporter(
                        isPresented: .constant(true),
                        allowedContentTypes: viewModel.uploader.filePickerContentTypes,
                        allowsMultipleSelection: true,
                        onCompletion: { result in
                            activePicker = nil
                            if case .success(let urls) = result {
                                let sources = urls.map { UploadSource.file($0) }
                                Task { await viewModel.enqueue(sources: sources) }
                            }
                        }
                    )
            }
        }
    }

    @ToolbarContentBuilder private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    filterButton(for: nil)
                    ForEach(MediaKind.allCases, id: \.self) { kind in
                        filterButton(for: kind)
                    }
                }
                Section {
                    Button {
                        viewModel.isAspectRatioModeEnabled.toggle()
                    } label: {
                        Label(
                            viewModel.isAspectRatioModeEnabled ? Strings.squareGrid : Strings.aspectRatioGrid,
                            systemImage: viewModel.isAspectRatioModeEnabled
                                ? "rectangle.arrowtriangle.2.outward"
                                : "rectangle.arrowtriangle.2.inward"
                        )
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
    }

    @ToolbarContentBuilder private var addMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(Strings.addMenuPhotoLibrary, systemImage: "photo.on.rectangle") {
                    activePicker = .photoLibrary
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(Strings.addMenuTakePhoto, systemImage: "camera") {
                        activePicker = .takePhoto
                    }
                    Button(Strings.addMenuTakeVideo, systemImage: "video") {
                        activePicker = .takeVideo
                    }
                }
                Button(Strings.addMenuChooseFile, systemImage: "folder") {
                    activePicker = .chooseFile
                }
            } label: {
                Image(systemName: "plus")
                    .accessibilityLabel(Strings.addMenuTitle)
            }
        }
    }

    @ViewBuilder private func filterButton(for kind: MediaKind?) -> some View {
        let title = kind?.title ?? Strings.filterAll
        let isSelected = kind == viewModel.filter.kind
        Button {
            viewModel.setFilter(viewModel.filter.with(kind: kind))
        } label: {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else if let systemImage = kind?.systemImageName {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
    }

    @ViewBuilder private var contentOverlay: some View {
        if viewModel.shouldDisplayInitialLoading {
            ProgressView()
        } else if let error = viewModel.errorToDisplay() {
            errorView(error)
        } else if viewModel.shouldDisplaySearchEmpty {
            ContentUnavailableView.search(text: viewModel.filter.search)
        } else if viewModel.shouldDisplayFilterEmpty {
            ContentUnavailableView(Strings.emptyFiltered, systemImage: "photo.on.rectangle")
        } else if viewModel.shouldDisplayEmpty {
            ContentUnavailableView(Strings.empty, systemImage: "photo.on.rectangle")
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(Strings.errorRetry) {
                retryToken += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
