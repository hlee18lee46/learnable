//
//  CollaborateView.swift
//  learnable
//
//  Created by Han Lee on 12/7/24.
//
import SwiftUI

struct CollaborateView: View {
    @StateObject private var viewModel: CollaborateViewModel
    @State private var messageText: String = ""
    @State private var selectedCategory: String = "math"
    @State private var feedbackMessage = ""

    init(userEmail: String) {
        _viewModel = StateObject(wrappedValue: CollaborateViewModel(userEmail: userEmail))
    }
    
    var body: some View {
        VStack {
            if viewModel.sessionEnded {
                VStack {
                    Text("Session Completed!")
                        .font(.largeTitle)
                        .padding()
                    Text("Total Score: \(viewModel.score)")
                        .font(.headline)
                }
            } else if viewModel.connectedPeers.isEmpty {
                VStack {
                    Text("Select a Category to Start or Join a Collaboration")
                        .font(.headline)
                        .padding()
                    
                    HStack {
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
                    
                    HStack {
                        Button("Start Hosting (Science)") {
                            viewModel.startHosting(category: "science")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Join Session (Science)") {
                            viewModel.joinSession(category: "science")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            } else {
                collaborationContent
            }
        }
    }
    
    private var collaborationContent: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Questions...")
            } else {
                // Question and Answer Section
                VStack {
                    if let question = viewModel.currentQuestion {
                        Text(question)
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)
                        
                        ForEach(viewModel.answerOptions, id: \.self) { option in
                            Button(action: {
                                viewModel.proposeAnswer(option)
                            }) {
                                Text(option)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(getAnswerBackground(for: option))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.agreedAnswer != nil)
                        }
                        if viewModel.showCorrectFeedback {
                            Text("Correct! 10 Coins Earned")
                                .foregroundColor(.green)
                                .font(.headline)
                                .padding()
                        }
                        // Show proposed answers
                        if let proposed = viewModel.proposedAnswer {
                            Text("You proposed: \(proposed)")
                                .foregroundColor(.blue)
                        }
                        if let partnerProposed = viewModel.partnerProposedAnswer {
                            Text("Partner proposed: \(partnerProposed)")
                                .foregroundColor(.green)
                            Button("Agree") {
                                viewModel.agreeWithProposal()
                            }
                            .disabled(viewModel.agreedAnswer != nil)
                        }
                    }
                }
                .padding()
                
                Text(feedbackMessage)
                    .foregroundColor(.black)
                    .padding()

            }
        }
    }
    
    private func getAnswerBackground(for option: String) -> Color {
        if option == viewModel.proposedAnswer {
            return .blue
        } else if option == viewModel.partnerProposedAnswer {
            return .green
        } else if option == viewModel.agreedAnswer {
            return .purple
        }
        return .gray
    }
}
