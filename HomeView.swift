
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to HomeView!")
                .font(.largeTitle)
                .padding()

            Text("You are now signed in.")
                .font(.title2)
                .padding()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
