import SwiftUI

struct NewsTickerView: View {
    @StateObject private var newsService = NewsAPIService()
    @State private var headlines: [Article] = []
    @AppStorage("selectedCountry") private var selectedCountry: String = "us"
    @AppStorage("selectedCategory") private var selectedCategory: String = "general"
    @AppStorage("headlineCount") private var headlineCount: Int = 5 // Default number of headlines
    @AppStorage("fontSize") private var fontSize: Double = 16
    @AppStorage("backgroundColorHex") private var backgroundColorHex: String = "#CCCCCC"
    @AppStorage("textColorHex") private var textColorHex: String = "#000000"
    @State private var isLoading = true
    @State private var offsetX: CGFloat = 0 // Animation offset

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    ProgressView("Loading headlines...")
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .background(Color(hex: backgroundColorHex))
                } else if headlines.isEmpty {
                    Text("No headlines available.")
                        .foregroundColor(Color(hex: textColorHex))
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .background(Color(hex: backgroundColorHex))
                } else {
                    HStack(spacing: 30) {
                        ForEach(Array(headlines.prefix(headlineCount).enumerated()), id: \.offset) { index, article in
                            Text(article.title)
                                .font(.system(size: fontSize))
                                .foregroundColor(Color(hex: textColorHex))
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color(hex: backgroundColorHex))
                                .cornerRadius(8)
                                .fixedSize(horizontal: true, vertical: false) // Ensure all text is shown
                                .onTapGesture {
                                    openArticle(article)
                                }
                        }
                    }
                    .offset(x: offsetX)
                    .onAppear {
                        animateTicker(totalWidth: geometry.size.width)
                    }
                }
            }
        }
        .frame(height: 50)
        .onAppear {
            Task {
                await fetchHeadlines()
            }
        }
    }

    private func animateTicker(totalWidth: CGFloat) {
        let totalContentWidth = CGFloat(headlines.count) * (totalWidth / CGFloat(headlines.count)) + CGFloat(headlines.count) * 30 // Add spacing
        offsetX = totalWidth // Start from the right edge
        withAnimation(Animation.linear(duration: Double(headlines.count) * 1).repeatForever(autoreverses: false)) {
            offsetX = -totalContentWidth // Move to the left edge
        }
    }

    private func fetchHeadlines() async {
        isLoading = true
        do {
            headlines = try await newsService.fetchTopHeadlines(for: selectedCountry, category: selectedCategory)
            isLoading = false
        } catch {
            print("Failed to fetch headlines: \(error)")
            isLoading = false
        }
    }

    private func openArticle(_ article: Article) {
        guard let urlString = article.url, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

