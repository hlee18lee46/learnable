
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
        let supabase = SupabaseManager.shared.supabaseClient

        do {
            // Check if user already exists
            let existingUserResponse = try await supabase
                .from("users")
                .select("*")
                .eq("email", value: email)
                .execute()

            if let existingUsers = try? JSONDecoder().decode([SupabaseUser].self, from: existingUserResponse.data),
               !existingUsers.isEmpty {
                print("User already exists with email: \(email)")
                return
            }

            // Insert new user
            let user = SupabaseUser(email: email, name: nil, industry: nil)
            let insertResponse = try await supabase
                .from("users")
                .insert(user)
                .execute()

            print("User successfully added to `users`: \(insertResponse)")
        } catch {
            print("Error inserting user: \(error.localizedDescription)")
        }
    }

}
