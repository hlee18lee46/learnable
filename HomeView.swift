import SwiftUI

struct HomeView: View {
    let userEmail: String // Add userEmail as a property

    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(Tab.dashboard)

            QuizView(userEmail: userEmail) // Pass userEmail to QuizView
                .tabItem {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Quiz")
                }
                .tag(Tab.quiz)

            CollabView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Collab")
                }
                .tag(Tab.collab)

            BattleView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Battle")
                }
                .tag(Tab.battle)
            MarketView(userEmail: userEmail) // Pass userEmail to MarketView
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Market")
                }
                .tag(Tab.market)
        }
        .onAppear {
            print("HomeView Loaded")
        }
    }
}

// Enum for Tabs
enum Tab {
    case dashboard, quiz, collab, battle, market
}

struct CollabView: View {
    var body: some View {
        VStack {
            Text("Collaborate with Friends!")
                .font(.largeTitle)
                .padding()
        }
    }
}


// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(userEmail: "example@example.com") // Provide a test email
    }
}
