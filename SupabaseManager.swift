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

            // Save the email to Supabase and ensure user is added to `user_characters`
            Task {
                await saveEmailAndCharacterToSupabase(email: email)
            }
        }
    }
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// Save the email to the `users` table and ensure the user is added to `user_characters`
func saveEmailAndCharacterToSupabase(email: String) async {
    let supabase = SupabaseManager.shared.supabaseClient

    do {
        // Check if the user already exists in the `users` table
        let existingUserResponse = try await supabase
            .from("users") // Updated table name
            .select("*")
            .eq("email", value: email)
            .execute()

        let existingUsers = try JSONDecoder().decode([User].self, from: existingUserResponse.data)

        if existingUsers.isEmpty {
            // Insert new user into `users` table
            let newUser: [String: AnyEncodable] = [
                "email": AnyEncodable(email),
                "coin": AnyEncodable(0) // Default coin value set to 0
            ]
            let insertResponse = try await supabase
                .from("users")
                .insert(newUser)
                .execute()
            print("User successfully added to `users`: \(insertResponse)")
        } else {
            print("User already exists in `users`: \(email)")
        }

        // Check if the user already exists in the `user_characters` table
        let existingCharacterResponse = try await supabase
            .from("user_characters")
            .select("*")
            .eq("user_email", value: email)
            .execute()

        let existingCharacters = try JSONDecoder().decode([UserCharacter].self, from: existingCharacterResponse.data)

        if existingCharacters.isEmpty {
            // Insert default character (e.g., character_id = 1) into `user_characters` table
            let newCharacterEntry: [String: AnyEncodable] = [
                "user_email": AnyEncodable(email),
                "character_id": AnyEncodable(1)
            ]
            let insertCharacterResponse = try await supabase
                .from("user_characters")
                .insert(newCharacterEntry)
                .execute()
            print("User successfully added to `user_characters`: \(insertCharacterResponse)")
        } else {
            print("User already exists in `user_characters`: \(email)")
        }
    } catch {
        print("Error saving email and character to Supabase: \(error.localizedDescription)")
    }
}
