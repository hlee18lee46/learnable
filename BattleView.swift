import SwiftUI

struct BattleView: View {
    @StateObject private var viewModel: BattleViewModel
    @State private var selectedCategory: String = "math" // Default category is math

    init(userEmail: String) {
        _viewModel = StateObject(wrappedValue: BattleViewModel(userEmail: userEmail))
    }

    var body: some View {
        VStack {
            if viewModel.sessionEnded {
                VStack {
                    if viewModel.winner == true {
                        Text("You Lose!")
                            .font(.largeTitle)
                            .padding()
                        Text("You lost 20 coins.")
                    } else {
                        Text("You Win!")
                            .font(.largeTitle)
                            .padding()
                        Text("You earned 50 coins!")

                    }
                    Text("Your Score: \(viewModel.playerScore)")
                    Text("Opponent's Score: \(viewModel.opponentScore)")
                }
            } else if viewModel.connectedPeers.isEmpty {
                VStack {
                    Text("Select a Category to Start or Join a Battle")
                        .font(.headline)
                        .padding()
                    HStack{
                        // Buttons for Math category
                        Button("Start Hosting (Math)") {
                            viewModel.startHosting(category: "math")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Join Session (Math)") {
                            viewModel.joinSession(category: "math")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    HStack{
                        Button("Start Hosting (Science)") {
                            viewModel.startHosting(category: "science")
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Join Session (Science)") {
                            viewModel.joinSession(category: "science")
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }



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
