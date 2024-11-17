
import Foundation
import Supabase
import UIKit
import GoogleSignIn


class SupabaseManager {
    static let shared = SupabaseManager()

    let supabaseClient: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://uvpgvfprspgfctmezlza.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cGd2ZnByc3BnZmN0bWV6bHphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwNzE4NzQsImV4cCI6MjA0NTY0Nzg3NH0.WNgFYJAWjpgKgtSgkeLlZkgN5Y7Bok6VZOvYspIYMQA"

        self.supabaseClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)

        print("SupabaseClient initialized with URL: \(supabaseURL) and API key: \(supabaseKey.prefix(10))...") // Partial key for debugging
    }
    
    func fetchCharacters() async throws -> [MarketItem] {
        let response = try await supabaseClient
            .from("character")
            .select("*")
            .execute()

        let items = try JSONDecoder().decode([MarketItem].self, from: response.data)
        return items
    }
}

// Function to handle Google Sign-In
func signInWithGoogle() {
    guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
        print("No presenting view controller")
        return
    }

    GIDSignIn.sharedInstance.signIn(
        withPresenting: presentingVC
    ) { signInResult, error in
        if let error = error {
            print("Error signing in: \(error.localizedDescription)")
            return
        }

        if let user = signInResult?.user {
            let email = user.profile?.email ?? ""
            print("Signed in with Google. User's email: \(email)")

            // Save the email to Supabase
            Task {
                await saveEmailToSupabase(email: email)
            }
        }
    }
}
func saveEmailToSupabase(email: String) async {
    let supabase = SupabaseManager.shared.supabaseClient

    do {
        // Check if the user already exists
        let existingUserResponse = try await supabase
            .from("users")
            .select("*")
            .eq("email", value: email)
            .execute()

        let existingUsers = try JSONDecoder().decode([User].self, from: existingUserResponse.data)

        if !existingUsers.isEmpty {
            print("User already exists: \(email)")
            return // Exit early if the user exists
        }

        // Insert new user
        let newUser = ["email": email]
        let insertResponse = try await supabase
            .from("users")
            .insert([newUser])
            .execute()

        print("User successfully added: \(insertResponse)")
    } catch {
        print("Error inserting user: \(error.localizedDescription)")
    }
}

