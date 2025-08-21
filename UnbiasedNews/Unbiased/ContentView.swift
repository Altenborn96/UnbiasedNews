import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var navigateToSettings = false // State to control navigation

    var body: some View {
        NavigationStack {
            ZStack {
               
                Color(isDarkMode ? .black : .white)
                    .ignoresSafeArea()

                VStack {
                    Spacer() // Pushes the content above the TabView

                    // Custom background for the tab bar
                    Color(isDarkMode ? .gray : .blue.opacity(0.6))
                        .frame(height: 60) // Matches tab bar height
                        .ignoresSafeArea(edges: .bottom)
                }

                // TabView content
                TabView {
                    MyArticlesView()
                        .tabItem {
                            Label("My Articles", systemImage: "newspaper")
                        }

                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }

                    SetupView()
                        .tabItem {
                            Label("Setup", systemImage: "gear")
                        }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




