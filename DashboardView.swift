import SwiftUI

struct DashboardView: View {
    @State private var userCharacters: [Character] = []
    let userEmail: String

    var body: some View {
        VStack {
            Text("Your Characters")
                .font(.title)
                .padding()

            List(userCharacters) { character in
                HStack {
                    Image(character.image)
                        .resizable()
                        .frame(width: 50, height: 50)
                    Text(character.name)
                }
            }
        }
        .onAppear {
            SupabaseManager.shared.fetchUserCharacters(userEmail: userEmail) { characters in
                DispatchQueue.main.async {
                    self.userCharacters = characters
                }
            }
        }
    }
}
