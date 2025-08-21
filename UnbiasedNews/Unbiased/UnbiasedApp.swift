
import SwiftUI
import SwiftData


@main
struct UnbiasedApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView() 
                .modelContainer(for: [Article.self, Search.self, Categories.self, Country.self])
        }
    }
}
