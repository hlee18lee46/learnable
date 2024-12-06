import SwiftUI
import Combine
import Supabase
import MultipeerConnectivity

class BattleViewModel: ObservableObject {
    @Published var currentQuestion: String?
    @Published var answerOptions: [String] = []
    @Published var playerScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var connectedPeers: [String] = []
    @Published var isLoading = true
    @Published var sessionEnded = false
    @Published var winner: Bool? // `true` if player wins, `false` if player loses
    @AppStorage("userCoins") private var userCoins: Int = 0 // Coins stored locally

    private var multipeerManager = MultipeerManager()
    private var supabase = SupabaseManager.shared.supabaseClient
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex = 0
    private var cancellables = Set<AnyCancellable>()
    private let userEmail: String // User email passed during initialization

    // Initialize with user email
    init(userEmail: String) {
        self.userEmail = userEmail

        multipeerManager.$connectedPeers
            .map { $0.map { $0.displayName } }
            .assign(to: &$connectedPeers)

        multipeerManager.$receivedData
            .sink { [weak self] data in
                self?.handleReceivedData(data)
            }
            .store(in: &cancellables)
    }

    func startHosting(category: String) {
        multipeerManager.startHosting()
        loadQuestions(for: category) // Load questions for the selected category
    }

    func joinSession(category: String) {
        multipeerManager.joinSession()
        loadQuestions(for: category) // Load questions for the selected category
    }



    func stopSession() {
        multipeerManager.stopSession()
    }

    func loadQuestions(for category: String) {
        isLoading = true
        currentQuestionIndex = 0 // Ensure the question index starts from 0
        questions = [] // Clear any previously loaded questions

        Task {
            do {
                let response = try await supabase
                    .from("questions")
                    .select("*")
                    .eq("category", value: category) // Filter by selected category
                    .execute()

                let fetchedQuestions = try JSONDecoder().decode([QuizQuestion].self, from: response.data)
                DispatchQueue.main.async {
                    self.questions = fetchedQuestions
                    self.isLoading = false
                    self.sendNextQuestion() // Start the session with the first question
                }
            } catch {
                print("Error loading questions: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.questions = []
                    self.isLoading = false
                }
            }
        }
    }



    func submitAnswer(_ answer: String) {
        guard !sessionEnded, currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        let isCorrect = answer == question.correctAnswer

        if isCorrect {
            playerScore += 1
        }

        let data: [String: Any] = [
            "action": "updateScore",
            "playerScore": playerScore
        ]
        sendDataToPeers(data)

        if playerScore == 10 {
            endSession(winner: true)
        } else if opponentScore == 10 {
            endSession(winner: false)
        } else {
            currentQuestionIndex += 1
            sendNextQuestion()
        }
    }

    private func endSession(winner: Bool) {
        sessionEnded = true
        self.winner = winner

        // Update coins locally
        let coinChange = winner ? 50 : -20
        userCoins = max(userCoins + coinChange, 0)

        Task {
            do {
                try await updateCoinsInSupabase(coinChange: coinChange)
                print("Coins updated successfully in Supabase.")
            } catch {
                print("Error updating coins in Supabase: \(error.localizedDescription)")
            }
        }

        let data: [String: Any] = [
            "action": "endSession",
            "winner": winner,
            "playerScore": playerScore,
            "opponentScore": opponentScore
        ]
        sendDataToPeers(data)
    }

    private func sendNextQuestion() {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        currentQuestion = question.question
        answerOptions = [question.option1, question.option2, question.option3, question.option4].shuffled()

        let data: [String: Any] = [
            "action": "nextQuestion",
            "question": question.question,
            "options": answerOptions
        ]
        sendDataToPeers(data)
    }

    private func updateCoinsInSupabase(coinChange: Int) async throws {
        let updateResponse = try await supabase
            .from("users")
            .update(["coins": userCoins])
            .eq("email", value: userEmail)
            .execute()

        print("Coins updated in Supabase: \(updateResponse)")
    }

    private func sendDataToPeers(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            multipeerManager.send(data: jsonData)
            print("Sent data to peers: \(data)")
        } catch {
            print("Error sending data to peers: \(error.localizedDescription)")
        }
    }

    private func handleReceivedData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let action = json["action"] as? String {
                DispatchQueue.main.async {
                    switch action {
                    case "nextQuestion":
                        self.currentQuestion = json["question"] as? String
                        self.answerOptions = json["options"] as? [String] ?? []
                    case "updateScore":
                        self.opponentScore = json["playerScore"] as? Int ?? 0
                        if self.opponentScore == 10 {
                            self.endSession(winner: false)
                        }
                    case "endSession":
                        self.sessionEnded = true
                        self.winner = json["winner"] as? Bool
                    default:
                        break
                    }
                }
            }
        } catch {
            print("Error decoding received data: \(error.localizedDescription)")
        }
    }
}
