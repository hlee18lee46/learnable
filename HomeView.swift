import SwiftUI

struct HomeView: View {
    let userEmail: String // Add userEmail as a property

    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(userEmail: userEmail)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(Tab.dashboard)

            QuizView(userEmail: userEmail)
                .tabItem {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Quiz")
                }
                .tag(Tab.quiz)

            CollaborateView(userEmail: userEmail)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Collab")
                }
                .tag(Tab.collab)

            BattleView(userEmail: userEmail)
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



// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(userEmail: "example@example.com") // Provide a test email
    }
}
