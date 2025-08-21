import SwiftUI

struct SetupView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false // Dark mode toggle
    @AppStorage("selectedCountry") private var selectedCountry: String = "br" // Default country
    @AppStorage("selectedCategory") private var selectedCategory: String = "general" // Default category
    @AppStorage("fontSize") private var fontSize: Double = 16 // Font size
    @AppStorage("backgroundColorHex") private var backgroundColorHex: String = "#CCCCCC" // Default gray color as hex
    @AppStorage("textColorHex") private var textColorHex: String = "#000000" // Default black color as hex
    @AppStorage("headlineCount") private var headlineCount: Int = 5 // Default number of headlines
    @AppStorage("userApiKey") private var userApiKey: String = "" // User API key
    @State private var apiKeyInput: String = "" // Temporary input field for the API key

    private let categories = [
        "general", "business", "entertainment", "health", "science", "sports", "technology"
    ]

    var body: some View {
        NavigationView {
            Form {
                // Dark Mode Toggle
                Section(header: Text("Display Settings")) {
                    Toggle("Enable Dark Mode", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                // News Ticker Settings Section
                Section(header: Text("News Ticker Settings")) {
                    // Category Picker
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category.capitalized).tag(category)
                        }
                    }

                    // Headline Count Adjustment
                    HStack {
                        Text("Number of Headlines")
                        Spacer()
                        Button(action: {
                            if headlineCount > 1 {
                                headlineCount -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Text("\(headlineCount)")
                            .frame(width: 40, alignment: .center)

                        Button(action: {
                            if headlineCount < 20 { // Limit to a reasonable max
                                headlineCount += 1
                            }
                        }) {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    // Font Size Slider
                    Slider(value: $fontSize, in: 10...30, step: 1) {
                        Text("Font Size")
                    }
                    Text("Font Size: \(Int(fontSize))")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Background Color Picker
                    ColorPicker("Background Color", selection: Binding(
                        get: { Color(hex: backgroundColorHex) },
                        set: { backgroundColorHex = $0.toHex() }
                    ))

                    // Text Color Picker
                    ColorPicker("Text Color", selection: Binding(
                        get: { Color(hex: textColorHex) },
                        set: { textColorHex = $0.toHex() }
                    ))
                }

                // API Key Section
                Section(header: Text("API Key Settings")) {
                    HStack {
                        TextField("Enter API Key", text: $apiKeyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onAppear {
                                apiKeyInput = userApiKey // Pre-fill if the API key already exists
                            }

                        Button("Save") {
                            userApiKey = apiKeyInput // Save the entered API key
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    if userApiKey.isEmpty {
                        Text("No API key saved. Using default API key.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("API key saved.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count > 3 ? components[3] : 1
        return String(format: "#%02X%02X%02X%02X",
                      Int(a * 255),
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}




struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}




