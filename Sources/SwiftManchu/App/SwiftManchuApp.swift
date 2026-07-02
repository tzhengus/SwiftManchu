import SwiftManchuCore
import SwiftUI

@main
struct SwiftManchuApp: App {
    @State private var model = DictionaryModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task {
                    await model.load()
                }
                #if os(macOS)
                .frame(minWidth: 860, minHeight: 560)
                #endif
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Reload Dictionary") {
                    Task { await model.load() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }

}
