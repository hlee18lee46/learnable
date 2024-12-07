import SwiftUI

struct MarketView: View {
    let userEmail: String
    @State private var items: [MarketItem] = []
    @State private var userCoins: Int?
    @State private var purchaseMessage: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            HStack {
                Text("Market")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let coins = userCoins {
                    Text("Coins: \(coins)")
                        .font(.headline)
                } else if let error = errorMessage {
                    Text(error)
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .padding()
            
            if isLoading {
                Spacer()
                ProgressView("Loading market items...")
                Spacer()
            } else {
                marketContent
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
    }
    
    private var marketContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(items) { item in
                    MarketItemView(
                        item: item,
                        userCoins: userCoins ?? 0,
                        onPurchase: { purchaseItem(item) }
                    )
                }
            }
            .padding()
        }
        .overlay(
            purchaseMessage.isEmpty ? nil :
                Text(purchaseMessage)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: purchaseMessage)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
        )
    }
    
    private func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load both user coins and market items concurrently
            async let coinsTask = fetchUserCoins()
            async let itemsTask = fetchMarketItems()
            
            // Wait for both tasks to complete
            let (coins, items) = try await (coinsTask, itemsTask)
            
            DispatchQueue.main.async {
                self.userCoins = coins
                self.items = items
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load market data"
                self.isLoading = false
                print("Error loading initial data: \(error)")
            }
        }
    }
    
    private func fetchUserCoins() async throws -> Int {
        let supabase = SupabaseManager.shared.supabaseClient
        
        let response = try await supabase
            .from("users")
            .select("coin, character_id")  // Match your UserDetails struct
            .eq("email", value: userEmail)
            .single()
            .execute()
        
        print("Coins response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
        
        let user = try JSONDecoder().decode(UserDetails.self, from: response.data)
        return user.coin
    }
    
    private func fetchMarketItems() async throws -> [MarketItem] {
        let response = try await SupabaseManager.shared.supabaseClient
            .from("characters")
            .select("*")
            .execute()
        
        return try JSONDecoder().decode([MarketItem].self, from: response.data)
    }
    
    private func purchaseItem(_ item: MarketItem) {
        guard let coins = userCoins, coins >= item.price else {
            purchaseMessage = "Not enough coins"
            return
        }
        
        Task {
            do {
                let newCoins = coins - item.price
                
                // Update user's coins
                try await SupabaseManager.shared.supabaseClient
                    .from("users")
                    .update(["coin": newCoins])
                    .eq("email", value: userEmail)
                    .execute()
                
                // Add character to user's collection
                let purchase = UserCharacter(user_email: userEmail, character_id: item.id)
                try await SupabaseManager.shared.supabaseClient
                    .from("user_characters")
                    .insert(purchase)
                    .execute()
                
                DispatchQueue.main.async {
                    self.userCoins = newCoins
                    self.purchaseMessage = "Successfully purchased \(item.name)!"
                    
                    // Clear purchase message after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.purchaseMessage = ""
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.purchaseMessage = "Purchase failed"
                    print("Purchase error: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Types
struct MarketItem: Identifiable, Codable {
    let id: Int
    let name: String
    let image: String
    let price: Int
}

struct UserCharacter: Codable {
    let user_email: String
    let character_id: Int
}

// MARK: - Market Item View
struct MarketItemView: View {
    let item: MarketItem
    let userCoins: Int
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text("Price: \(item.price) Coins")
                    .font(.subheadline)
            }
            
            Spacer()
            
            Button(action: onPurchase) {
                Text("Buy")
                    .font(.subheadline)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 15)
                    .background(userCoins >= item.price ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(userCoins < item.price)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
