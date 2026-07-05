import SwiftUI

struct WatchContentView: View {
    @StateObject private var recorder = MotionRecorder()
    @State private var selectedSubject = "P1"
    @State private var selectedLabel = "ADL-walking"

    private let subjects = ["P1", "P2", "P3", "P4", "P5"]
    private let labels = [
        "FALL-forward", "FALL-backward", "FALL-lateral", "FALL-slow",
        "ADL-walking", "ADL-sit-down-fast", "ADL-lie-down",
        "ADL-pick-object", "ADL-arm-move"
    ]

    var body: some View {
        VStack(spacing: 8) {
            if recorder.isRecording {
                Text("● REC").font(.title3).bold().foregroundStyle(.red)
                Text("\(selectedSubject) · \(selectedLabel)").font(.caption2)
                Text("\(recorder.sampleCount) samples").font(.caption)
                Button("Stop & Save") {
                    recorder.stop(label: selectedLabel, subject: selectedSubject)
                }.tint(.red)
            } else {
                Picker("Subject", selection: $selectedSubject) {
                    ForEach(subjects, id: \.self) { Text($0) }
                }.frame(height: 48)
                Picker("Label", selection: $selectedLabel) {
                    ForEach(labels, id: \.self) { Text($0) }
                }.frame(height: 56)
                Button("Start") { recorder.start() }.tint(.green)
                if let f = recorder.lastFileName {
                    Text("✓ \(f)").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear { _ = WatchSessionManager.shared }
    }
}

#Preview {
    WatchContentView()
}
