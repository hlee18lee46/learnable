
import Foundation
import Supabase
import UIKit
import GoogleSignIn


class SupabaseManager {
    static let shared = SupabaseManager()

    let supabaseClient = SupabaseClient(
        supabaseURL: URL(string: "https://uvpgvfprspgfctmezlza.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cGd2ZnByc3BnZmN0bWV6bHphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwNzE4NzQsImV4cCI6MjA0NTY0Nzg3NH0.WNgFYJAWjpgKgtSgkeLlZkgN5Y7Bok6VZOvYspIYMQA"
    )
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
        // Update to use "users" (plural)
        let existingUserResponse = try await supabase
            .from("user") // Corrected table name
            .select("*")
            .eq("email", value: email)
            .execute()

        if let existingUsers = try? JSONDecoder().decode([User].self, from: existingUserResponse.data),
           !existingUsers.isEmpty {
            print("User already exists with email: \(email)")
            return
        }

        // Insert the new user record into the "users" table
        let user = ["email": email]
        let insertResponse = try await supabase
            .from("user") // Corrected table name
            .insert([user])
            .execute()

        print("Email saved to Supabase: \(insertResponse)")
    } catch {
        print("Error saving email to Supabase: \(error.localizedDescription)")
    }
}

