import SwiftUI
import UIKit
import WordPressMediaLibrary

/// SwiftUI wrapper around the V1 `ExternalMediaPickerViewController`, shared by
/// every external source that vends `ExternalMediaAsset`s (Stock Photos).
/// Per-source differences (data source, welcome view, title, asset mapping) are
/// injected; the picker-to-delegate bridging is common to all of them.
struct ExternalMediaPickerSheet: View {
    let title: String
    let source: MediaSource
    let makeDataSource: () -> ExternalMediaDataSource
    let makeWelcomeView: () -> UIView
    let mapAsset: (ExternalMediaAsset) -> ExternalRemoteMedia
    let delegate: any ExternalMediaPickerDelegate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExternalMediaPickerVCRepresentable(
            title: title,
            mediaSource: source,
            makeDataSource: makeDataSource,
            makeWelcomeView: makeWelcomeView
        ) { selection in
            // V1 picker uses a single didFinishWithSelection callback;
            // empty array = cancel, non-empty = done.
            if selection.isEmpty {
                delegate.didCancel()
            } else {
                delegate.didPick(remoteMedia: selection.map(mapAsset))
            }
            dismiss()
        }
        .ignoresSafeArea()
    }
}

private struct ExternalMediaPickerVCRepresentable: UIViewControllerRepresentable {
    let title: String
    let mediaSource: MediaSource
    let makeDataSource: () -> ExternalMediaDataSource
    let makeWelcomeView: () -> UIView
    let onFinished: ([ExternalMediaAsset]) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = ExternalMediaPickerViewController(
            dataSource: makeDataSource(),
            source: mediaSource,
            allowsMultipleSelection: true
        )
        picker.title = title
        picker.welcomeView = makeWelcomeView()
        picker.delegate = context.coordinator
        return UINavigationController(rootViewController: picker)
    }

    func updateUIViewController(_: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinished: onFinished) }

    final class Coordinator: NSObject, ExternalMediaPickerViewDelegate {
        let onFinished: ([ExternalMediaAsset]) -> Void
        init(onFinished: @escaping ([ExternalMediaAsset]) -> Void) {
            self.onFinished = onFinished
        }
        func externalMediaPickerViewController(
            _ viewController: ExternalMediaPickerViewController,
            didFinishWithSelection selection: [ExternalMediaAsset]
        ) {
            // V1 callback runs on the main thread (it's a UIKit dismiss path).
            // assumeIsolated bridges into the @MainActor closure without an
            // async hop. Same pattern as MediaPickerController.swift:78-82.
            MainActor.assumeIsolated {
                onFinished(selection)
            }
        }
    }
}
