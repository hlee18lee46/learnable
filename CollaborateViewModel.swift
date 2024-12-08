
import SwiftUI
import MultipeerConnectivity
import Combine
import Supabase

struct Message: Identifiable, Codable {
    let id = UUID()
    let sender: String
    let content: String
}

class CollaborateViewModel: ObservableObject {
    @Published var currentQuestion: String?
    @Published var answerOptions: [String] = []
    @Published var score: Int = 0
    @Published var connectedPeers: [String] = []
    @Published var isLoading = true
    @Published var sessionEnded = false
    @Published var messages: [Message] = []
    @Published var proposedAnswer: String?
    @Published var partnerProposedAnswer: String?
    @Published var agreedAnswer: String?
    @Published var showCorrectFeedback = false  // New state for showing feedback
    private var multipeerManager = MultipeerManager()
    private var supabase = SupabaseManager.shared.supabaseClient
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex = 0
    private var cancellables = Set<AnyCancellable>()
    private let userEmail: String
    
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
        loadQuestions(for: category)
    }
    
    func joinSession(category: String) {
        multipeerManager.joinSession()
        loadQuestions(for: category)
    }
    
    func sendMessage(_ content: String) {
        let message = Message(sender: userEmail, content: content)
        messages.append(message)
        
        let data: [String: Any] = [
            "action": "chat",
            "message": [
                "sender": message.sender,
                "content": message.content
            ]
        ]
        sendDataToPeers(data)
    }
    
    func proposeAnswer(_ answer: String) {
        proposedAnswer = answer
        
        let data: [String: Any] = [
            "action": "proposeAnswer",
            "answer": answer
        ]
        sendDataToPeers(data)
    }
    
    func agreeWithProposal() {
        guard let partnerProposal = partnerProposedAnswer else { return }
        submitAnswer(partnerProposal)
    }
    
    private func loadQuestions(for category: String) {
        isLoading = true
        currentQuestionIndex = 0
        
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
                    self.isLoading = false
                    self.sendNextQuestion()
                }
            } catch {
                print("Error loading questions: \(error)")
                DispatchQueue.main.async {
                    self.questions = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        let isCorrect = answer == question.correctAnswer
        
        if isCorrect {
            score += 1
            updateCoinsForBothUsers()
        }
        
        // Reset answer states
        proposedAnswer = nil
        partnerProposedAnswer = nil
        agreedAnswer = nil
        
        currentQuestionIndex += 1
        sendNextQuestion()
        
        let data: [String: Any] = [
            "action": "answerSubmitted",
            "correct": isCorrect,
            "score": score
        ]
        sendDataToPeers(data)
    }
    
    private func updateCoinsForBothUsers() {
        Task {
            do {
                // Fetch current coins
                let response = try await supabase
                    .from("users")
                    .select("coin, character_id")
                    .eq("email", value: userEmail)
                    .single()
                    .execute()
                
                if let user = try? JSONDecoder().decode(UserDetails.self, from: response.data) {
                    let currentCoins = user.coin
                    let newCoins = currentCoins + 10 // Each correct answer gives 10 coins
                    
                    // Update coins in database
                    let updates: [String: AnyEncodable] = [
                        "coin": AnyEncodable(newCoins)
                    ]
                    
                    try await supabase
                        .from("users")
                        .update(updates)
                        .eq("email", value: userEmail)
                        .execute()
                    
                    print("Coins updated successfully in Supabase")
                    Text("Correct! 10 Coins Earned")
                        .foregroundColor(.green)
                        .font(.headline)
                        .padding()
                }
            } catch {
                print("Error updating coins: \(error)")
            }
        }
    }
    
    private func sendNextQuestion() {
        guard currentQuestionIndex < questions.count else {
            sessionEnded = true
            return
        }
        
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
    
    private func sendDataToPeers(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            multipeerManager.send(data: jsonData)
        } catch {
            print("Error sending data: \(error)")
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let action = json["action"] as? String else { return }
            
            DispatchQueue.main.async {
                switch action {
                case "chat":
                    if let messageData = json["message"] as? [String: String],
                       let sender = messageData["sender"],
                       let content = messageData["content"] {
                        self.messages.append(Message(sender: sender, content: content))
                    }
                    
                case "proposeAnswer":
                    if let answer = json["answer"] as? String {
                        self.partnerProposedAnswer = answer
                    }
                    
                case "nextQuestion":
                    self.currentQuestion = json["question"] as? String
                    self.answerOptions = json["options"] as? [String] ?? []
                    
                case "answerSubmitted":
                    if let isCorrect = json["correct"] as? Bool {
                        // Handle partner's submission result
                        if isCorrect {
                            self.updateCoinsForBothUsers()
                        }
                    }
                    
                default:
                    break
                }
            }
        } catch {
            print("Error handling received data: \(error)")
        }
    }
}



struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(message.sender)
                .font(.caption)
                .foregroundColor(.gray)
            Text(message.content)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
}
