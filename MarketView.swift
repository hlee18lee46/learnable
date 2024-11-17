//
//  MarketView.swift
//  learnable
//
//  Created by Han Lee on 11/16/24.
//
import SwiftUI

struct MarketView: View {
    let userEmail: String
    @State private var items: [MarketItem] = []
    @AppStorage("userCoins") private var userCoins: Int = 0
    @State private var purchaseMessage: String = ""

    var body: some View {
        VStack {
            HStack {
                Text("Market")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("Coins: \(userCoins)")
                    .font(.headline)
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(items) { item in
                        HStack {
                            Image(uiImage: UIImage(named: item.image)!)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Price: \(item.price) Coins")
                                    .font(.subheadline)
                            }
                            Spacer()

                            Button(action: {
                                purchaseItem(item)
                            }) {
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
                .padding()
            }

            if !purchaseMessage.isEmpty {
                Text(purchaseMessage)
                    .foregroundColor(.green)
                    .font(.footnote)
                    .padding()
            }
        }
        .onAppear {
            loadItems()
        }
    }

    func loadItems() {
        Task {
            do {
                print("Fetching characters...")
                let response = try await SupabaseManager.shared.supabaseClient
                    .from("characters")
                    .select("*")
                    .execute()

                print("Raw Supabase response: \(response)")

                let fetchedItems = try JSONDecoder().decode([MarketItem].self, from: response.data)
                DispatchQueue.main.async {
                    self.items = fetchedItems
                    print("Fetched characters: \(self.items)")
                }
            } catch {
                print("Error fetching items: \(error.localizedDescription)")
            }
        }
    }

    func purchaseItem(_ item: MarketItem) {
        Task {
            do {
                if userCoins >= item.price {
                    userCoins -= item.price

                    let purchaseData = UserCharacter(user_email: userEmail, character_id: item.id)
                    try await SupabaseManager.shared.supabaseClient
                        .from("user_characters")
                        .insert(purchaseData)
                        .execute()

                    DispatchQueue.main.async {
                        purchaseMessage = "Successfully purchased \(item.name)!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            purchaseMessage = ""
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        purchaseMessage = "Not enough coins to buy \(item.name)."
                    }
                }
            } catch {
                print("Error during purchase: \(error.localizedDescription)")
            }
        }
    }
}
struct UserCharacter: Encodable {
    let user_email: String
    let character_id: Int
}
struct UserItem: Encodable {
    let user_email: String
    let item_id: Int
}
// MARK: - MarketItem Model
struct MarketItem: Identifiable, Codable {
    let id: Int
    let name: String
    let image: String
    let price: Int
}
