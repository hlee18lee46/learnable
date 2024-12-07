import SwiftUI

struct DashboardView: View {
    @State private var userCoins: Int = 0
    @State private var userCharacterImage: String = "basic.png"
    let userEmail: String // Pass the logged-in user's email address

    var body: some View {
        VStack {
            // Welcome message
            Text("Welcome to Learnable, \(userEmail)!")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 20)

            // Coin display
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.yellow)
                Text("\(userCoins)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Character display with fallback
            if let characterImage = UIImage(named: userCharacterImage) {
                Image(uiImage: characterImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
            } else {
                Image(uiImage: UIImage(named: "logo.png")!) // Fallback to default
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            fetchUserDetails()
        }
    }

    // Fetch the user's coins and character ID from Supabase
    private func fetchUserDetails() {
        Task {
            do {
                let supabase = SupabaseManager.shared.supabaseClient
                // Use a join query to fetch character details
                let response = try await supabase
                    .from("users")
                    .select("""
                        coin,
                        character_id,
                        characters(image)
                    """)
                    .eq("email", value: userEmail)
                    .single() // Expecting a single result
                    .execute()

                // Print the raw JSON for debugging
                if let rawJSON = String(data: response.data, encoding: .utf8) {
                    print("Raw JSON: \(rawJSON)")
                }

                // Decode the response
                let userWithCharacter = try JSONDecoder().decode(UserWithCharacterDetails.self, from: response.data)

                DispatchQueue.main.async {
                    self.userCoins = userWithCharacter.coin
                    self.userCharacterImage = userWithCharacter.character.image
                    print("User coins updated to \(self.userCoins)")
                    print("User character image updated to \(self.userCharacterImage)")
                }
            } catch {
                print("Error fetching user details: \(error.localizedDescription)")
            }
        }
    }



    struct UserWithCharacterDetails: Codable {
        let coin: Int
        let character: CharacterDetails

        enum CodingKeys: String, CodingKey {
            case coin
            case character = "characters" // Map "characters" in the JSON to "character" in Swift
        }

        struct CharacterDetails: Codable {
            let image: String
        }
    }

}

