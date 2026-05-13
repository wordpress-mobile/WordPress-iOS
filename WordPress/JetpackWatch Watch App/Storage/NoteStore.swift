import Foundation
import Combine
import os

enum NoteStoreError: Error, Equatable, Sendable {
    case notFound
}

/// On-disk persistence for the Watch's voice notes. Single JSON file, rewritten
/// on every mutation. Eviction: when over `cap`, oldest terminal notes go first;
/// active notes are never auto-evicted.
@MainActor
class NoteStore: ObservableObject {
    static let cap = 20

    @Published private(set) var notes: [VoiceNote] = []

    private let fileURL: URL
    private let audioRootURL: URL

    init(rootURL: URL, audioRootURL: URL) {
        self.fileURL = rootURL.appendingPathComponent("notes.json")
        self.audioRootURL = audioRootURL
        load()
    }

    func add(_ note: VoiceNote) throws {
        notes.append(note)
        sortNewestFirst()
        evictIfNeeded()
        try save()
    }

    func update(_ note: VoiceNote) throws {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else {
            throw NoteStoreError.notFound
        }
        notes[idx] = note
        sortNewestFirst()
        try save()
    }

    func delete(id: UUID) throws {
        if let note = notes.first(where: { $0.id == id }) {
            removeAudioFile(for: note)
        }
        notes.removeAll { $0.id == id }
        try save()
    }

    private func sortNewestFirst() {
        notes.sort { $0.createdAt > $1.createdAt }
    }

    private func evictIfNeeded() {
        guard notes.count > Self.cap else { return }
        let overage = notes.count - Self.cap
        let terminalSortedOldestFirst = notes.enumerated()
            .filter { $0.element.status.isTerminal }
            .sorted { $0.element.createdAt < $1.element.createdAt }
        var indicesToRemove = Set<Int>()
        for item in terminalSortedOldestFirst.prefix(overage) {
            indicesToRemove.insert(item.offset)
            removeAudioFile(for: item.element)
        }
        notes = notes.enumerated()
            .filter { !indicesToRemove.contains($0.offset) }
            .map(\.element)
    }

    private func removeAudioFile(for note: VoiceNote) {
        let audioURL = audioRootURL.appendingPathComponent(note.audioFilename)
        do {
            try FileManager.default.removeItem(at: audioURL)
        } catch let error as NSError where error.code == NSFileNoSuchFileError {
            // File never written (e.g. recording never completed) — expected, ignore.
        } catch {
            watchLogger.warning("NoteStore: failed to delete audio file \(note.audioFilename, privacy: .public): \(error, privacy: .public)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([VoiceNote].self, from: data) else {
            return
        }
        notes = decoded
        sortNewestFirst()
    }

    private func save() throws {
        let data = try JSONEncoder().encode(notes)
        try data.write(to: fileURL, options: .atomic)
    }
}
