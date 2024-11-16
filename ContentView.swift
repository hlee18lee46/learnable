import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var errorMessage: String? = nil
    @State private var logoScale: CGFloat = 0.5  // Initial scale for animation
    @State private var logoOpacity: Double = 0.0  // Initial opacity for animation
    @State private var userEmail: String = "" // Add a property to store the user email

    var body: some View {
        if isSignedIn {
            HomeView(userEmail: userEmail) // Pass userEmail to HomeView
        } else {
            ZStack{
                Color.blue.ignoresSafeArea()
                
                VStack {
                    Text("Learn-Able! Math = Fun!")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.bottom, 20)
                    Image(uiImage: UIImage(named: "logo.png")!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.5)) {
                                logoScale = 1.8  // Scale up to original size
                                logoOpacity = 1.0  // Fade in to full opacity
                            }
                        }
                        .padding(.top, 40)
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.bottom, 20)
                    }

                    GoogleSignInButton(action: signInWithGoogle)
                        .frame(width: 200, height: 50)
                        .padding()
                }
            }
            

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
