import Foundation
import Combine
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    let noteStore: NoteStore
    let siteCatalog: SiteCatalog
    let phoneBridge: any PhoneBridge
    let audioRecorder: AudioRecorder
    let handoffPublisher: HandoffPublisher

    init(
        noteStore: NoteStore,
        siteCatalog: SiteCatalog,
        phoneBridge: any PhoneBridge,
        audioRecorder: AudioRecorder,
        handoffPublisher: HandoffPublisher
    ) {
        self.noteStore = noteStore
        self.siteCatalog = siteCatalog
        self.phoneBridge = phoneBridge
        self.audioRecorder = audioRecorder
        self.handoffPublisher = handoffPublisher
    }

    static func live() -> AppEnvironment {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let noteStore = NoteStore(rootURL: docs)
        let siteCatalog = SiteCatalog(rootURL: docs)
        let seed = AppEnvironment.developmentSeedSites
        let bridge = MockPhoneBridge(seedSites: seed)
        let audioRecorder = AudioRecorder(rootURL: docs)
        let handoff = HandoffPublisher()

        bridge.onSitesReceived = { @MainActor @Sendable sites in
            siteCatalog.setSites(sites)
            if siteCatalog.defaultSiteID == nil, let first = sites.first {
                siteCatalog.setDefaultSiteID(first.id)
            }
        }
        bridge.onNoteStateUpdate = { @MainActor @Sendable id, status, postID, reason in
            guard var note = noteStore.notes.first(where: { $0.id == id }) else { return }
            note.status = status
            if let postID { note.postID = postID }
            note.statusReason = reason
            try? noteStore.update(note)
        }
        Task { await bridge.start() }

        return AppEnvironment(
            noteStore: noteStore,
            siteCatalog: siteCatalog,
            phoneBridge: bridge,
            audioRecorder: audioRecorder,
            handoffPublisher: handoff
        )
    }
}

private extension AppEnvironment {
    /// Seed shown while Plan 1 uses MockPhoneBridge. Plan 2 swaps this for
    /// real sites received over WatchConnectivity.
    static var developmentSeedSites: [Site] {
        #if DEBUG
        return Site.previewSeed
        #else
        return []
        #endif
    }
}

#if DEBUG
extension AppEnvironment {
    static func preview() -> AppEnvironment {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("watch-preview-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let noteStore = NoteStore(rootURL: tempDir)
        let siteCatalog = SiteCatalog(rootURL: tempDir)
        siteCatalog.setSites(Site.previewSeed)
        siteCatalog.setDefaultSiteID(Site.previewSeed.first?.id)
        return AppEnvironment(
            noteStore: noteStore,
            siteCatalog: siteCatalog,
            phoneBridge: MockPhoneBridge(seedSites: Site.previewSeed),
            audioRecorder: AudioRecorder(rootURL: tempDir),
            handoffPublisher: HandoffPublisher()
        )
    }
}
#endif
