import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        if isSignedIn {
            HomeView()
        } else {
            VStack {
                Text("Learn-Able! Gamification")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 20)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                }

                GoogleSignInButton(action: signInWithGoogle)
                    .frame(width: 200, height: 50)
                    .padding()
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    func signInWithGoogle() {
        guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
            errorMessage = "No presenting view controller"
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            if let error = error {
                errorMessage = "Error signing in: \(error.localizedDescription)"
                return
            }

            if let user = signInResult?.user {
                isSignedIn = true
                let userEmail = user.profile?.email ?? "Unknown email"
                
                Task {
                    do {
                        try await SupabaseService.shared.createUserData(email: userEmail)
                    } catch {
                        print("Error inserting user: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
