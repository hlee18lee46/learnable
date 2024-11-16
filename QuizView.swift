
import SwiftUI

struct QuizView: View {
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var answer = ""
    @State private var feedbackMessage = ""
    
    let questions = [
        QuizQuestion(question: "What is 2 + 2?", answer: "4"),
        QuizQuestion(question: "What planet is known as the Red Planet?", answer: "Mars"),
        QuizQuestion(question: "What is the chemical symbol for water?", answer: "H2O")
    ]
    
    var body: some View {
        VStack {
            Text("Score: \(score)")
                .font(.title)
                .padding()
            
            Text(questions[currentQuestionIndex].question)
                .font(.headline)
                .padding()
            
            TextField("Your Answer", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Submit Answer") {
                checkAnswer()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text(feedbackMessage)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .padding()
    }
    
    func checkAnswer() {
        let correctAnswer = questions[currentQuestionIndex].answer.lowercased()
        if answer.lowercased() == correctAnswer {
            feedbackMessage = "Correct!"
            score += 1
        } else {
            feedbackMessage = "Incorrect. Try Again."
        }
        
        // Move to the next question after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedbackMessage = ""
            answer = ""
            currentQuestionIndex = (currentQuestionIndex + 1) % questions.count
        }
    }
}

struct QuizQuestion {
    let question: String
    let answer: String
}
