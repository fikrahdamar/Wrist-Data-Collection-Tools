import Foundation
import Combine
import CoreMotion
import WatchConnectivity

struct MotionSample {
    let t: TimeInterval
    let ax, ay, az: Double
    let gx, gy, gz: Double
}

final class MotionRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var sampleCount = 0
    @Published var lastFileName: String?

    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    private var samples: [MotionSample] = []
    private var startTime: TimeInterval = 0
    private let hz: Double = 100.0

    func start() {
        guard motion.isDeviceMotionAvailable, !isRecording else { return }
        samples.removeAll()
        startTime = 0
        motion.deviceMotionUpdateInterval = 1.0 / hz
        DispatchQueue.main.async { self.isRecording = true; self.sampleCount = 0 }

        motion.startDeviceMotionUpdates(to: queue) { [weak self] dm, _ in
            guard let self, let dm else { return }
            if self.startTime == 0 { self.startTime = dm.timestamp }
            let ax = dm.userAcceleration.x + dm.gravity.x
            let ay = dm.userAcceleration.y + dm.gravity.y
            let az = dm.userAcceleration.z + dm.gravity.z
            let k = 180.0 / .pi
            self.samples.append(MotionSample(
                t: dm.timestamp - self.startTime,
                ax: ax, ay: ay, az: az,
                gx: dm.rotationRate.x * k,
                gy: dm.rotationRate.y * k,
                gz: dm.rotationRate.z * k))
            let c = self.samples.count
            DispatchQueue.main.async { self.sampleCount = c }
        }
    }

    func stop(label: String, subject: String) {
        guard isRecording else { return }
        motion.stopDeviceMotionUpdates()
        DispatchQueue.main.async { self.isRecording = false }
        queue.addOperation { [weak self] in self?.saveAndSend(label: label, subject: subject) }
    }

    private func saveAndSend(label: String, subject: String) {
        var csv = "t,ax,ay,az,gx,gy,gz\n"
        for s in samples {
            csv += String(format: "%.4f,%.5f,%.5f,%.5f,%.3f,%.3f,%.3f\n",
                          s.t, s.ax, s.ay, s.az, s.gx, s.gy, s.gz)
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let safeLabel = label.replacingOccurrences(of: " ", with: "-")
        let safeSubject = subject.replacingOccurrences(of: " ", with: "-")
        let name = "\(safeSubject)_\(safeLabel)_\(stamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            DispatchQueue.main.async { self.lastFileName = name }
            WatchSessionManager.shared.sendFile(url, label: label, subject: subject)
        } catch {
            print("save error: \(error)")
        }
    }
}

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    func sendFile(_ url: URL, label: String, subject: String) {
        guard WCSession.default.activationState == .activated else {
            print("WC belum aktif, file di: \(url)"); return
        }
        WCSession.default.transferFile(url, metadata: ["label": label, "subject": subject])
    }
    func session(_ s: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
