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
                Image(uiImage: UIImage(named: "basic.png")!) // Fallback to default
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
                let response = try await supabase
                    .from("users")
                    .select("coin, character_id")
                    .eq("email", value: userEmail)
                    .single() // Expecting a single result
                    .execute()

                // Decode the response
                let user = try JSONDecoder().decode(UserDetails.self, from: response.data)

                DispatchQueue.main.async {
                    self.userCoins = user.coin
                    self.userCharacterImage = "character_\(user.character_id).png"
                }
            } catch {
                print("Error fetching user details: \(error.localizedDescription)")
            }
        }
    }
}

