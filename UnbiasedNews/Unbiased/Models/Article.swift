

import SwiftData
import Foundation

@Model
class Article: Identifiable {
   
    var title: String
    var articleDescription: String?
    var author: String?
    var url: String?
    var urlToImage: String?
    var publishedAt: Date?
    var category: Categories?
    var notes: String?
    var isSaved: Bool = false
    var isSavedFromSearch: Bool = false
    var country: String?
    var countryCode: String?
    var popularity: Int?
    let createdAt: Date

    init(
        title: String,
        articleDescription: String? = nil,
        author: String? = nil,
        url: String? = nil,
        urlToImage: String? = nil,
        publishedAt: Date? = nil,
        category: Categories? = nil,
        notes: String? = nil,
        isSaved: Bool = false,
        isSavedFromSearch: Bool = false,
        country: String? = nil,
        countryCode: String? = nil,
        popularity: Int? = nil
    ) {
        self.title = title
        self.articleDescription = articleDescription
        self.author = author
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.category = category
        self.notes = notes
        self.isSaved = isSaved
        self.isSavedFromSearch = isSavedFromSearch
        self.country = country
        self.countryCode = countryCode
        self.popularity = popularity
        self.createdAt = Date()
    }

    var isFullySaved: Bool {
        return isSaved || isSavedFromSearch
    }
}








