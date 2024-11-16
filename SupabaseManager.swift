
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
    
    func fetchCoins(for userEmail: String, completion: @escaping (Int?) -> Void) {
        Task {
            do {
                let response = try await supabaseClient
                    .from("users")
                    .select("coins")
                    .eq("email", value: userEmail)
                    .single()
                    .execute()

                // Decode the response and pass the coins value to the completion handler
                if let data = response.data as? [String: Any],
                   let coins = data["coins"] as? Int {
                    completion(coins)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error fetching coins: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func assignDefaultCharacter(to userEmail: String) {
        let supabase = SupabaseManager.shared.supabaseClient

        Task {
            do {
                let response = try await supabase
                    .from("user_characters")
                    .insert(["user_email": userEmail, "character_id": 1]) // Default character ID
                    .execute()

                if response.status == 201 {
                    print("Default character assigned successfully.")
                } else {
                    print("Error assigning default character: \(response)")
                }
            } catch {
                print("Error assigning default character: \(error.localizedDescription)")
            }
        }
    }
    
    func purchaseCharacter(userEmail: String, characterId: Int, characterPrice: Int) {
        let supabase = SupabaseManager.shared.supabaseClient

        Task {
            do {
                // Fetch user's current coins
                let userResponse = try await supabase
                    .from("users")
                    .select("coins")
                    .eq("email", value: userEmail)
                    .single()
                    .execute()

                if let userData = userResponse.data as? [String: Any],
                   let userCoins = userData["coins"] as? Int, userCoins >= characterPrice {

                    // Deduct coins and add the character
                    try await supabase
                        .from("users")
                        .update(["coins": userCoins - characterPrice])
                        .eq("email", value: userEmail)
                        .execute()

                    try await supabase
                        .from("user_characters")
                        .insert(["user_email": userEmail, "character_id": characterId])
                        .execute()

                    print("Character purchased successfully!")
                } else {
                    print("Not enough coins to purchase this character.")
                }
            } catch {
                print("Error purchasing character: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUserCharacters(userEmail: String, completion: @escaping ([Character]) -> Void) {
        Task {
            do {
                let response = try await supabaseClient
                    .from("user_characters")
                    .select("character:characters(*)") // Ensure correct nesting
                    .eq("user_email", value: userEmail)
                    .execute()

                if let data = response.data {
                    // Decode the nested structure
                    let userCharacters: [UserCharacter] = try JSONDecoder().decode([UserCharacter].self, from: data)
                    let characters = userCharacters.map { $0.character }
                    completion(characters)
                } else {
                    print("No user characters found.")
                    completion([])
                }
            } catch {
                print("Error fetching user characters: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    func fetchCharacters(completion: @escaping ([Character]) -> Void) {
        Task {
            do {
                let response = try await supabaseClient
                    .from("characters")
                    .select("*")
                    .execute()

                if let data = response.data {
                    // Explicitly specify the type
                    let characters: [Character] = try JSONDecoder().decode([Character].self, from: data)
                    completion(characters)
                } else {
                    print("No data received from Supabase.")
                    completion([])
                }
            } catch {
                print("Error fetching characters: \(error.localizedDescription)")
                completion([])
            }
        }
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

