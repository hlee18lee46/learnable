import SwiftUI
import Combine
import Supabase
import MultipeerConnectivity

class BattleViewModel: ObservableObject {
    @Published var currentQuestion: String?
    @Published var answerOptions: [String] = []
    @Published var playerScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var connectedPeers: [String] = [] // List of peer display names
    @Published var isLoading = true

    private var multipeerManager = MultipeerManager()
    private var supabase = SupabaseManager.shared.supabaseClient // Supabase client instance
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Transform MCPeerID objects into their display names
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
        loadQuestions(for: category)
    }

    func joinSession() {
        multipeerManager.joinSession()
    }

    func stopSession() {
        multipeerManager.stopSession()
    }

    // Fetch questions from Supabase
    func loadQuestions(for category: String) {
        isLoading = true

        Task {
            do {
                let response = try await supabase
                    .from("questions")
                    .select("*")
                    .eq("category", value: category)
                    .execute()

                let fetchedQuestions = try JSONDecoder().decode([QuizQuestion].self, from: response.data)
                DispatchQueue.main.async {
                    self.questions = fetchedQuestions
                    self.currentQuestionIndex = 0
                    self.isLoading = false
                    self.sendNextQuestion()
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

    // Send the next question to all peers
    private func sendNextQuestion() {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        currentQuestion = question.question
        answerOptions = [question.option1, question.option2, question.option3, question.option4].shuffled()

        // Send question and options to peers
        let data: [String: Any] = [
            "action": "nextQuestion",
            "question": question.question,
            "options": answerOptions
        ]
        sendDataToPeers(data)
    }

    // Submit an answer
    func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        let isCorrect = answer == question.correctAnswer

        if isCorrect {
            playerScore += 1
        }

        // Send updated score to peers
        let data: [String: Any] = [
            "action": "updateScore",
            "score": playerScore
        ]
        sendDataToPeers(data)

        // Proceed to the next question
        currentQuestionIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sendNextQuestion()
        }
    }

    // Send data to connected peers
    private func sendDataToPeers(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            multipeerManager.send(data: jsonData) // Ensure this is Data
        } catch {
            print("Error sending data to peers: \(error.localizedDescription)")
        }
    }

    // Handle received data from peers
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
                        if let score = json["score"] as? Int {
                            self.opponentScore = score
                        }
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
