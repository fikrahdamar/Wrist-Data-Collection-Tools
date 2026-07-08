import SwiftUI

struct PhoneContentView: View {
    @ObservedObject private var manager = PhoneSessionManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if manager.receivedFiles.isEmpty {
                    ContentUnavailableView("Belum ada data",
                                           systemImage: "applewatch",
                                           description: Text("Rekam di Watch, file muncul di sini otomatis."))
                } else {
                    List {
                        ForEach(manager.receivedFiles, id: \.self) { url in
                            ShareLink(item: url) {
                                Label(url.lastPathComponent, systemImage: "doc.text")
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { manager.receivedFiles[$0] }.forEach(manager.delete)
                        }
                    }
                }
            }
            .navigationTitle("Wrist Data (\(manager.receivedFiles.count))")
        }
    }
}

#Preview {
    PhoneContentView()
}
