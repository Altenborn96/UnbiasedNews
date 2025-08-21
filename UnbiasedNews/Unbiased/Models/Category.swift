

import SwiftData
import Foundation


@Model
class Categories: Identifiable {
    let id: UUID
    var name: String
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(name: String, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

