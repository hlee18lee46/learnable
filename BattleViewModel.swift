import Foundation
import MultipeerConnectivity
import Combine

class BattleViewModel: NSObject, ObservableObject {
    @Published var currentQuestion: String?
    @Published var answerOptions: [String] = []
    @Published var playerScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var connectedPeers: [String] = []
    @Published var showGameOverAlert = false
    @Published var gameOverMessage = ""

    private var multipeerManager: MultipeerManager
    private var cancellables = Set<AnyCancellable>()

    override init() {
        self.multipeerManager = MultipeerManager()
        super.init()
        
        multipeerManager.$connectedPeers
            .sink { [weak self] peers in
                self?.connectedPeers = peers.map { $0.displayName }
            }
            .store(in: &cancellables)
        
        multipeerManager.$receivedData
            .sink { [weak self] message in
                self?.handleReceivedMessage(message)
            }
            .store(in: &cancellables)
    }

    func startHosting() {
        multipeerManager.startHosting()
    }

    func joinSession() {
        multipeerManager.joinSession()
    }

    func loadDummyQuestion() {
        currentQuestion = "What is 2 + 2?"
        answerOptions = ["1", "2", "3", "4"].shuffled()
    }

    func submitAnswer(_ answer: String) {
        if answer == "4" {
            playerScore += 1
            sendGameUpdate()
        } else {
            // Handle incorrect answer if needed
        }
    }

    private func sendGameUpdate() {
        let message = "score:\(playerScore)"
        multipeerManager.send(data: message)
    }

    private func handleReceivedMessage(_ message: String) {
        if message.starts(with: "score:") {
            if let score = Int(message.replacingOccurrences(of: "score:", with: "")) {
                opponentScore = score
            }
        }
    }

    func resetGame() {
        playerScore = 0
        opponentScore = 0
        currentQuestion = nil
        multipeerManager.stopSession()
    }
}
