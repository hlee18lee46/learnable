import SwiftUI

struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()
    @State private var selectedCategory: String = "math"

    var body: some View {
        VStack {
            if viewModel.connectedPeers.isEmpty {
                VStack {
                    Button("Start Hosting") {
                        viewModel.startHosting(category: selectedCategory)
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
                    if viewModel.isLoading {
                        Text("Loading Questions...")
                            .font(.title)
                            .padding()
                    } else if let question = viewModel.currentQuestion {
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
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }

                        Text("Your Score: \(viewModel.playerScore)")
                            .font(.headline)
                            .padding()

                        Text("Opponent Score: \(viewModel.opponentScore)")
                            .font(.headline)
                    } else {
                        Text("No questions available.")
                            .font(.title2)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadQuestions(for: selectedCategory)
        }
    }
}
