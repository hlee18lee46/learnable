import SwiftUI

struct StoreView: View {
    @State private var characters: [Character] = []
    @AppStorage("userCoins") private var userCoins: Int = 0
    let userEmail: String

    var body: some View {
        VStack {
            Text("Store")
                .font(.largeTitle)
                .padding()

            Text("Your Coins: \(userCoins)")
                .font(.headline)
                .padding()

            List(characters, id: \.id) { character in
                HStack {
                    Text(character.name)
                        .font(.title2)
                    Spacer()
                    Text("\(character.price) coins")
                        .foregroundColor(.gray)

                    Button("Buy") {
                        SupabaseManager.shared.purchaseCharacter(
                            userEmail: userEmail,
                            characterId: character.id,
                            characterPrice: character.price
                        ) { success in
                            if success {
                                DispatchQueue.main.async {
                                    userCoins -= character.price
                                    print("Purchase successful. Updated coins: \(userCoins)")
                                }
                            } else {
                                print("Purchase failed.")
                            }
                        }
                    }
                    .disabled(userCoins < character.price) // Disable button if not enough coins
                }
            }
        }
        .onAppear {
            fetchCharacters()
        }
    }

    func fetchCharacters() {
        SupabaseManager.shared.fetchCharacters { fetchedCharacters in
            DispatchQueue.main.async {
                self.characters = fetchedCharacters
            }
        }
    }
}
