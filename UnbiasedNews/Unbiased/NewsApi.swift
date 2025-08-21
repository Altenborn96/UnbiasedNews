import SwiftData
import Foundation

@MainActor
class NewsAPIService: ObservableObject {
    private let defaultApiKey = "YOUR_API_KEY_HERE" // PUT YOUR API KEY HERE
    private let topHeadlinesUrl = "https://newsapi.org/v2/top-headlines"
    private let everythingUrl = "https://newsapi.org/v2/everything"

    private var apiKey: String {
        // Use the user's saved API key if available, otherwise fallback to the default key
        UserDefaults.standard.string(forKey: "userApiKey") ?? defaultApiKey
    }

    // MARK: - Fetch and Save Articles
    func fetchAndSaveArticles(context: ModelContext) async {
        let categories = ["general", "technology", "business", "health", "sports", "entertainment"]

        for categoryName in categories {
            let normalizedCategoryName = categoryName.lowercased()

            guard let url = URL(string: "\(topHeadlinesUrl)?category=\(normalizedCategoryName)&apiKey=\(apiKey)") else {
                print("Invalid URL for category: \(normalizedCategoryName)")
                continue
            }

            print("Fetching articles for category: \(normalizedCategoryName)")

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let apiResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
                saveArticles(apiResponse.articles, context: context, category: normalizedCategoryName)
            } catch {
                print("Failed to fetch articles for category \(normalizedCategoryName): \(error)")
            }
        }
    }
    
    @MainActor
    private func saveArticles(_ articles: [ArticleResponse], context: ModelContext, category: String) {
        let categoryObject = getCategory(named: category, context: context)
        for articleResponse in articles {
            guard let url = articleResponse.url else { continue }
            if !articleExists(url: url, context: context) {
                let article = Article(
                    title: articleResponse.title,
                    articleDescription: articleResponse.description,
                    url: url,
                    urlToImage: articleResponse.urlToImage,
                    publishedAt: parseDate(articleResponse.publishedAt),
                    category: categoryObject,
                    country: nil,
                    countryCode: nil
                )
                context.insert(article)
            }
        }
        try? context.save()
    }

    // MARK: - Fetch Top Headlines by Country and Category
    func fetchTopHeadlines(for country: String, category: String) async throws -> [Article] {
        guard var urlComponents = URLComponents(string: topHeadlinesUrl) else {
            throw URLError(.badURL)
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        print("Constructed URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("HTTP Status Code: \(httpResponse.statusCode)") // Debugging
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return apiResponse.articles.map { articleResponse in
            Article(
                title: articleResponse.title,
                articleDescription: articleResponse.description,
                url: articleResponse.url,
                urlToImage: articleResponse.urlToImage,
                publishedAt: parseDate(articleResponse.publishedAt),
                category: nil,
                country: country,
                countryCode: country
            )
        }
    }

    // MARK: - Fetch and Save Categories
    func fetchAndSaveCategories(context: ModelContext) async {
        let categoryNames = await fetchCategories()
        
        // Fetch existing categories in a single query
        let existingCategories = try? context.fetch(FetchDescriptor<Categories>())
        let existingNames = Set(existingCategories?.map { $0.name } ?? [])
        
        // Insert only missing categories
        for name in categoryNames where !existingNames.contains(name) {
            let category = Categories(name: name)
            context.insert(category)
            print("Inserted category: \(category.name)")
        }
        
        // Save changes once
        try? context.save()
    }


    func fetchCategories() async -> [String] {
        return ["general", "technology", "business", "health", "sports", "entertainment"]
    }

    // MARK: - Search Articles
    func searchArticles(keyword: String) async -> [Article] {
        guard let url = URL(string: "\(everythingUrl)?q=\(keyword)&apiKey=\(apiKey)") else {
            print("Invalid URL for search keyword: \(keyword)")
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let apiResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)

            return apiResponse.articles.map { articleResponse in
                Article(
                    title: articleResponse.title,
                    articleDescription: articleResponse.description,
                    url: articleResponse.url,
                    urlToImage: articleResponse.urlToImage,
                    publishedAt: parseDate(articleResponse.publishedAt),
                    category: nil,
                    country: nil,
                    countryCode: nil
                )
            }
        } catch {
            print("Error searching articles: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods
    private func getCategory(named name: String, context: ModelContext) -> Categories {
        let fetchDescriptor = FetchDescriptor<Categories>(predicate: #Predicate { $0.name == name })
        return try! context.fetch(fetchDescriptor).first ?? Categories(name: name)
    }

    private func articleExists(url: String, context: ModelContext) -> Bool {
        let fetchDescriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == url })
        return (try? context.fetch(fetchDescriptor).isEmpty) == false
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Response Models
struct NewsAPIResponse: Codable {
    let articles: [ArticleResponse]
}

struct ArticleResponse: Codable {
    let title: String
    let description: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String?
}










