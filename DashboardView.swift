import SwiftUI

struct DashboardView: View {
    @AppStorage("userCoins") private var userCoins: Int = 0

    var body: some View {
        VStack {
            // Welcome message with username
            Text("Welcome to Learnable!")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 20)

            // Coin image and total coins
            HStack {
                Image(systemName: "bitcoinsign.circle.fill") // Replace with your coin image if you have one
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.yellow) // Change the color if using a system image
                Text("\(userCoins)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Display the character image (basic.png)
            Image(uiImage: UIImage(named: "basic.png")!)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding()
        }
        .padding()
    }
}
