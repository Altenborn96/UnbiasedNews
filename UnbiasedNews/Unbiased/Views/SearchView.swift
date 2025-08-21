import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var context // Access the SwiftData context
    @Query private var searches: [Search] // Previously saved search keywords
    @State private var searchKeyword: String = "" // Current search query
    @State private var searchResults: [Article] = [] // Results fetched from NewsAPI
    @FocusState private var isFocused: Bool // Track if the TextField is focused
    @StateObject private var newsService = NewsAPIService() // API service for fetching articles
    @State private var showDeleteConfirmation: Bool = false // Show delete confirmation dialog
    @State private var searchToDelete: Search? // Store the search to delete
    @State private var isDropdownVisible: Bool = false // Track dropdown visibility
    @State private var sortOption: SortOption = .releaseDate // Current sort option
    @State private var isLoading = false // Loading state for search results

    enum SortOption: String, CaseIterable {
        case releaseDate = "Release Date"
        case popularity = "Popularity"
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar with Dropdown
                searchBar

                // Sorting Picker
                Picker("Sort By", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .disabled(searchResults.isEmpty) // Disable picker when no results

                Divider().padding(.vertical)

                // Search Results or Empty State
                if isLoading {
                    ProgressView("Loading articles...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    emptyStateView
                } else {
                    articleList
                }
            }
            .navigationTitle("Search Articles")
            .background(Color(.systemBackground).ignoresSafeArea())
            .confirmationDialog("Are you sure you want to delete this search?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let searchToDelete = searchToDelete {
                        deleteSearch(searchToDelete)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onTapGesture {
                isDropdownVisible = false // Dismiss dropdown when tapping outside
            }
        }
    }

    // Computed property for sorted articles
    private var sortedArticles: [Article] {
        switch sortOption {
        case .releaseDate:
            return searchResults.sorted {
                ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
            }
        case .popularity:
            return searchResults.sorted {
                ($0.popularity ?? 0) > ($1.popularity ?? 0)
            }
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(sortedArticles, id: \.id) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleRow(article: article)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                TextField("Search for news...", text: $searchKeyword)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($isFocused)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                Button(action: {
                    Task { await performSearch() }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                }

                Button(action: {
                    isDropdownVisible.toggle()
                }) {
                    Image(systemName: isDropdownVisible ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .padding(10)
                }
            }
            .padding(.horizontal)

            // Dropdown Menu
            if isDropdownVisible && !searches.isEmpty {
                dropdownMenu
            }
        }
        .padding(.top)
    }

    private var dropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(searches) { search in
                HStack {
                    Text(search.keyword)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(5)
                        .onTapGesture {
                            searchKeyword = search.keyword
                            isDropdownVisible = false
                            Task { await performSearch() }
                        }

                    Button(action: {
                        searchToDelete = search
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal)
                .background(Color(.white))
            }
        }
        .background(Color(.white).shadow(radius: 5))
        .cornerRadius(10)
        .padding(.horizontal)
        .zIndex(1) // Ensure dropdown appears above other content
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "newspaper.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No articles found")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Start by searching for something newsworthy.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private func performSearch() async {
        guard !searchKeyword.isEmpty else { return }

        isLoading = true // Show loading state

        // Save the search term locally if it doesn't already exist
        if !searches.contains(where: { $0.keyword == searchKeyword }) {
            let newSearch = Search(keyword: searchKeyword, timestamp: Date())
            context.insert(newSearch)
            try? context.save()
        }

        // Perform API search
        searchResults = await newsService.searchArticles(keyword: searchKeyword)

        isLoading = false // Hide loading state
    }

    private func deleteSearch(_ search: Search) {
        context.delete(search)
        try? context.save()
    }
}




























