//
//  PersistenceManager.swift
//  SiteSafe
//
//  Local-only JSON persistence for the whole AppData graph. Writes are
//  debounced (coalesces rapid edits like typing) with a synchronous flush on
//  backgrounding so nothing is lost.
//

import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let fileName = "sitesafe.json"
    private var pendingSave: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.sitesafe.persistence", qos: .utility)

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var fileURL: URL { documentsURL.appendingPathComponent(fileName) }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: Load

    func load() -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let raw = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(AppData.self, from: raw) else {
            let seed = SampleData.seed()
            saveNow(seed)
            return seed
        }
        return decoded
    }

    // MARK: Save (debounced)

    func save(_ data: AppData) {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.write(data) }
        pendingSave = work
        queue.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// Immediate, synchronous write — used on scenePhase background.
    func saveNow(_ data: AppData) {
        pendingSave?.cancel()
        write(data)
    }

    func flush(_ data: AppData) { saveNow(data) }

    private func write(_ data: AppData) {
        guard let encoded = try? encoder.encode(data) else { return }
        try? encoded.write(to: fileURL, options: [.atomic])
    }

    // MARK: Backup export

    /// Returns a temporary URL holding a pretty-printed JSON backup for sharing.
    func exportBackup(_ data: AppData) -> URL? {
        guard let encoded = try? encoder.encode(data) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SiteSafe-Backup.json")
        do {
            try encoded.write(to: url, options: [.atomic])
            return url
        } catch { return nil }
    }

    func wipe() {
        pendingSave?.cancel()
        try? FileManager.default.removeItem(at: fileURL)
    }
}
