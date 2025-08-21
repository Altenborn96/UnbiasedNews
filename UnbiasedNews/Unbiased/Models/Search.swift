

import SwiftData
import Foundation

@Model
class Search: Identifiable {
    let id: UUID
    var keyword: String
    var timestamp: Date 

    init(keyword: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.keyword = keyword
        self.timestamp = timestamp
    }
}
