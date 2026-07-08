import Foundation
import Combine
import WatchConnectivity

final class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()
    @Published var receivedFiles: [URL] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        reload()
    }

    private var folder: URL {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WristData", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func reload() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil)) ?? []
        DispatchQueue.main.async {
            self.receivedFiles = files.sorted { $0.lastPathComponent > $1.lastPathComponent }
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let dest = folder.appendingPathComponent(file.fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: file.fileURL, to: dest)
        reload()
    }
    
    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        reload()
    }

    func session(_ s: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ s: WCSession) {}
    func sessionDidDeactivate(_ s: WCSession) { WCSession.default.activate() }
}
