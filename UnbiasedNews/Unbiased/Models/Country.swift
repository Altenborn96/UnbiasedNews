

import SwiftData
import Foundation

@Model
class Country: Identifiable {
    let id: UUID
    var name: String
    var code: String 

    init(name: String, code: String) {
        self.id = UUID()
        self.name = name
        self.code = code
    }
}
