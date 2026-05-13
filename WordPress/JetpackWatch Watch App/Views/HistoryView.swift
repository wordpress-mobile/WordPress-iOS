import SwiftUI
import os

struct HistoryView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Group {
            if env.noteStore.notes.isEmpty {
                ContentUnavailableView(
                    "No voice notes yet",
                    systemImage: "mic.slash",
                    description: Text("Tap the record button to start one.")
                )
            } else {
                List(env.noteStore.notes) { note in
                    Button { tap(note) } label: {
                        NoteRowView(note: note)
                    }
                    .disabled(note.status != .draftReady)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            do {
                                try env.noteStore.delete(id: note.id)
                            } catch {
                                watchLogger.error("HistoryView: delete note failed: \(error, privacy: .public)")
                            }
                            let bridge = env.phoneBridge
                            Task { await bridge.deleteNote(note.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        if note.status == .failed {
                            let bridge = env.phoneBridge
                            Button {
                                Task { await bridge.retry(noteID: note.id) }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
    }

    private func tap(_ note: VoiceNote) {
        guard note.status == .draftReady, let postID = note.postID else { return }
        env.handoffPublisher.publishDraftReady(postID: postID, siteID: note.siteID)
    }
}
