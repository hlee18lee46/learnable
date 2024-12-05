import SwiftUI

struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()

    var body: some View {
        VStack {
            if viewModel.connectedPeers.isEmpty {
                VStack {
                    Text("Waiting for a connection...")
                        .font(.title)
                        .padding()

                    Button("Start Hosting") {
                        viewModel.startHosting()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Join Session") {
                        viewModel.joinSession()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                VStack {
                    Text("Connected to: \(viewModel.connectedPeers.first ?? "Unknown")")
                        .font(.headline)
                        .padding()

                    if let question = viewModel.currentQuestion {
                        Text(question)
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)

                        ForEach(viewModel.answerOptions, id: \.self) { option in
                            Button(action: {
                                viewModel.submitAnswer(option)
                            }) {
                                Text(option)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Text("Your Score: \(viewModel.playerScore)")
                        .font(.subheadline)
                        .padding()

                    Text("Opponent's Score: \(viewModel.opponentScore)")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .onAppear {
            viewModel.loadDummyQuestion()
        }
        .alert(isPresented: $viewModel.showGameOverAlert) {
            Alert(
                title: Text("Game Over"),
                message: Text(viewModel.gameOverMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.resetGame()
                })
            )
        }
    }
}
