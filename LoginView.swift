import SwiftUI

struct User: Codable {
    let username: String
    let password: String
}

struct AuthResponse: Codable {
    let message: String
}

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var authMessage = ""

    var body: some View {
        VStack {
            Text(isLogin ? "Login" : "Register")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if isLogin {
                    login()
                } else {
                    register()
                }
            }) {
                Text(isLogin ? "Login" : "Register")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }

            Text(authMessage)
                .padding()
                .foregroundColor(authMessage == "Login successful" ? .green : .red)

            Button(action: {
                isLogin.toggle()
            }) {
                Text(isLogin ? "Don't have an account? Register" : "Already have an account? Login")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }

    // MARK: - Backend Calls
    func register() {
        let user = User(username: username, password: password)
        sendAuthRequest(to: "https://your_ngrok_or_flask_server_url/register", user: user)
    }

    func login() {
        let user = User(username: username, password: password)
        sendAuthRequest(to: "https://your_ngrok_or_flask_server_url/login", user: user)
    }

    func sendAuthRequest(to url: String, user: User) {
        guard let requestUrl = URL(string: url) else {
            authMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(user)
            request.httpBody = jsonData
        } catch {
            authMessage = "Failed to encode user data"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    authMessage = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    authMessage = "No data in response"
                }
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                DispatchQueue.main.async {
                    authMessage = authResponse.message
                }
            } catch {
                DispatchQueue.main.async {
                    authMessage = "Failed to parse JSON response"
                }
            }
        }.resume()
    }
}
