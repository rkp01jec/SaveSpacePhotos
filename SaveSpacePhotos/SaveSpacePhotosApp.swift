import SwiftUI

@main
struct SaveSpacePhotosApp: App {
    @StateObject private var library = PhotoLibraryService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
        }
    }
}
