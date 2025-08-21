import SwiftUI
import SwiftData

struct MyArticlesView: View {
    @Environment(\.modelContext) private var context // Access the ModelContext
    @Query private var articles: [Article] // Fetch all articles
    @StateObject private var newsService = NewsAPIService() // NewsAPI integration
    @State private var showCategoryPicker = false // State to show category picker
    @State private var selectedCategory: String? = "Favorites" // Set default to "Favorites"
    @State private var categories: [String] = [] // Fetched categories
    @State private var isLoadingCategories = true // State to show loading indicator for categories

    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // Ensure proper spacing
                // Fixed NewsTickerView at the top
                NewsTickerView()
                    .frame(height: 50)
                    .padding(.bottom, 5) // Add spacing below the ticker

                // Main content
                VStack(spacing: 10) {
                    // Section Title
                    Text(selectedCategory == "Favorites" ? "My Favorite Articles" : "\(selectedCategory?.capitalized ?? "Articles")")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 10)

                    // Article List or Empty State
                    if filteredArticles.isEmpty {
                        // Empty State View
                        VStack {
                            Spacer()
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No articles available.")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(selectedCategory == "Favorites"
                                 ? "Save articles to view them here."
                                 : "No articles available for \(selectedCategory?.capitalized ?? "this category").")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                    } else {
                        // Articles List with Swipe-to-Delete
                        List {
                            ForEach(filteredArticles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    ArticleRow(article: article)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteArticle(article)
                                    } label: {
                                        Label("Trash", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .padding(.horizontal) // Add horizontal padding for content
                .navigationBarTitleDisplayMode(.inline) // Ensure title is displayed inline
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCategoryPicker = true
                        }) {
                            Image(systemName: "line.horizontal.3.decrease.circle")
                                .imageScale(.large)
                        }
                    }
                }
                .onAppear {
                    Task {
                        await newsService.fetchAndSaveArticles(context: context) // Fetch and save articles on view appear
                        await loadCategories() // Load categories asynchronously
                    }
                }
                .sheet(isPresented: $showCategoryPicker) {
                    // Category Picker Sheet
                    NavigationView {
                        if isLoadingCategories {
                            ProgressView("Loading Categories...") // Show a loading indicator while fetching
                                .padding()
                        } else {
                            List {
                                // Add "My Favorite Articles" option
                                Button(action: {
                                    selectedCategory = "Favorites" // Show saved articles
                                    showCategoryPicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("My Favorite Articles")
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 5)

                                // Add other categories with icons
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        showCategoryPicker = false
                                    }) {
                                        HStack {
                                            Image(systemName: categoryIcon(for: category))
                                                .foregroundColor(.blue)
                                            Text(category.capitalized)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .navigationTitle("Select Category")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        showCategoryPicker = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom) // Ensure keyboard doesn't cause layout issues
        }
    }

    private func loadCategories() async {
        isLoadingCategories = true
        let fetchedCategories = await newsService.fetchCategories()
        
        // Optimistically set categories for faster UI update
        DispatchQueue.main.async {
            self.categories = fetchedCategories
        }
        
        // Save categories in the database asynchronously
        await newsService.fetchAndSaveCategories(context: context)
        
        // Update isLoadingCategories after saving
        DispatchQueue.main.async {
            self.isLoadingCategories = false
        }
    }


    private var filteredArticles: [Article] {
        if selectedCategory == "Favorites" {
            return articles.filter { $0.isSaved }
        } else if let selectedCategory = selectedCategory {
            return articles.filter { $0.category?.name.lowercased() == selectedCategory.lowercased() }
        } else {
            return articles
        }
    }

    private func deleteArticle(_ article: Article) {
        context.delete(article)
        try? context.save()
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "sports": return "sportscourt"
        case "business": return "briefcase.fill"
        case "health": return "heart.fill"
        case "technology": return "desktopcomputer"
        case "entertainment": return "film.fill"
        default: return "newspaper"
        }
    }
}

// Article Row for each article in the list
struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Article Image
            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }

            // Article Text
            VStack(alignment: .leading, spacing: 5) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                if let description = article.articleDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                if let publishedAt = article.publishedAt {
                    Text("Published on \(publishedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}


