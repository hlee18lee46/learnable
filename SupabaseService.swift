
import Supabase
import Foundation
// User struct to match the schema in Supabase
struct SupabaseUser: Codable {
    let email: String
    let name: String?
    let industry: String?
}
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    private let supabaseClient = SupabaseManager.shared.supabaseClient

    func createUserData(email: String) async throws {
        do {
            // Check if user already exists in the "user" table
            let existingUserResponse = try await supabaseClient
                .from("user")
                .select("*")
                .eq("email", value: email)
                .execute()

            if let existingUsers = try? JSONDecoder().decode([User].self, from: existingUserResponse.data),
               !existingUsers.isEmpty {
                print("User already exists with email: \(email)")
                return
            }

            // Insert new user data
            let user = SupabaseUser(email: email, name: nil, industry: nil)
            let insertResponse = try await supabaseClient
                .from("user")
                .insert(user)
                .execute()

            print("Insert success: \(insertResponse)")

        } catch {
            print("Error inserting user: \(error.localizedDescription)")
        }
    }
}
