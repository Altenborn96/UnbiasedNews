

import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(\.modelContext) private var context // SwiftData context for saving
    @Bindable var article: Article
    @Query private var categories: [Categories] // Fetch categories from the database
    @State private var isEditing = false // State for editing notes
    @State private var showCategoryPicker = false // State for showing category picker
    @StateObject private var newsService = NewsAPIService() // Instance of your API service

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Article Title
                Text(article.title)
                    .font(.largeTitle)
                    .bold()

                // Article Author
                if let author = article.author {
                    Text("Author: \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Article Description
                if let description = article.articleDescription {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Article URL
                if let urlString = article.url, let url = URL(string: urlString) {
                    Link("Read Full Article", destination: url)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                }

               
                // Image if available
                if let urlToImage = article.urlToImage, let imageUrl = URL(string: urlToImage) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                        case .failure:
                            Text("Image failed to load.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            // Handle unexpected cases
                            Text("Unknown image loading state.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }


                // Current Category Display
                if let currentCategory = article.category {
                    Text("Current Category: \(currentCategory.name)")
                        .font(.subheadline)
                        .padding(.vertical, 8)
                } else {
                    Text("Current Category: None")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }

                // Assign Category Button
                Button("Assign Category") {
                    fetchCategories() // Fetch categories before showing the picker
                    showCategoryPicker = true
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showCategoryPicker) {
                    // Show a list of categories in a sheet
                    NavigationView {
                        List(categories) { category in
                            Button(action: {
                                assignCategory(category)
                                showCategoryPicker = false
                            }) {
                                Text(category.name)
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

                // Save Article Button
                Button(article.isSaved ? "Unsave Article" : "Save Article") {
                    toggleSaveArticle()
                }
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 8)

                // Notes Section
                Text("Notes")
                    .font(.headline)
                    .padding(.top)

                if isEditing {
                    TextField("Enter Notes", text: Binding(
                        get: { article.notes ?? "" }, // Provide a default value if notes is nil
                        set: { article.notes = $0 }  // Update notes when the text field changes
                    ))
                    .textFieldStyle(.roundedBorder)
                } else {
                    if let notes = article.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.gray)
                    } else {
                        Text("No notes available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                // Save or Edit Button
                Button(isEditing ? "Save Notes" : "Edit Notes") {
                    if isEditing {
                        try? context.save() // Save updated notes
                    }
                    isEditing.toggle()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            fetchCategories() // Ensure categories are fetched when the view appears
        }
    }

 
    private func toggleSaveArticle() {
        if article.isSaved {
            // If unsaving, remove from "Saved" category
            if let savedCategory = categories.first(where: { $0.name == "Saved" }) {
                if article.category == savedCategory {
                    article.category = nil // Remove "Saved" category
                }
            }
            article.isSaved = false
        } else {
            // If saving, assign to "Saved" category
            let savedCategory = getOrCreateSavedCategory()
            article.category = savedCategory
            article.isSaved = true
        }
        try? context.save() // Save the change
    }

  
    private func getOrCreateSavedCategory() -> Categories {
        if let savedCategory = categories.first(where: { $0.name == "Saved" }) {
            return savedCategory
        }

        // Create a new "Saved" category if it doesn't exist
        let newCategory = Categories(name: "Saved")
        context.insert(newCategory)
        try? context.save()
        return newCategory
    }


    private func assignCategory(_ category: Categories) {
        article.category = category
        try? context.save() // Save changes immediately
    }


    private func fetchCategories() {
        Task {
            await newsService.fetchAndSaveCategories(context: context)
        }
    }
}












