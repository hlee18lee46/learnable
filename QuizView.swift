import SwiftUI
import Supabase
struct AnswerData: Codable {
    let user_email: String
    let question_id: Int
    let is_correct: Bool
}
struct QuizView: View {
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var feedbackMessage = ""
    @State private var selectedOption: String = ""
    @State private var questions: [QuizQuestion] = []
    @State private var selectedCategory: String = "math"
    @State private var isLoading = true

    let userEmail: String // Pass this from login or context

    var body: some View {
        VStack {
            // Category Picker
            Picker("Select Category", selection: $selectedCategory) {
                Text("Math").tag("math")
                Text("Science").tag("science")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedCategory) { _ in
                loadQuestions(for: selectedCategory)
            }

            if isLoading {
                Text("Loading Questions...")
                    .font(.title)
                    .padding()
            } else {
                ScrollView{
                    VStack {
                        Text("Score: \(score)")
                            .font(.title)
                            .padding()

                        if !questions.isEmpty {
                            // Display current question
                            Text(questions[currentQuestionIndex].question)
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity) // Allow the question to take full width
                                .multilineTextAlignment(.center) // Center align the text
                                .background(Color.gray.opacity(0.1)) // Optional background
                                .cornerRadius(10)

                            Spacer(minLength: 20) // Add some spacing between question and options

                            // Display multiple-choice options
                            ForEach(getOptions(for: currentQuestionIndex), id: \.self) { option in
                                Button(action: {
                                    selectedOption = option
                                    checkAnswer()
                                }) {
                                    Text(option)
                                        .font(.subheadline) // Make options smaller
                                        .frame(maxWidth: .infinity) // Full width
                                        .padding(10)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }

                            Text(feedbackMessage)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            Text("No questions available.")
                                .font(.title2)
                                .padding()
                        }
                    }
                }


                Spacer()
            }
        }
        .padding()
        .onAppear(perform: {
            loadQuestions(for: selectedCategory)
        })
    }

    // MARK: - Helper Functions

    func loadQuestions(for category: String) {
        let supabase = SupabaseManager.shared.supabaseClient
        isLoading = true

        Task {
            do {
                print("Fetching questions for category: \(category)") // Debugging
                let response = try await supabase
                    .from("questions")
                    .select("*")
                    .eq("category", value: category)
                    .execute()

                // Debug raw response
                print("Supabase Response: \(response)")

                let fetchedQuestions = try JSONDecoder().decode([QuizQuestion].self, from: response.data)
                DispatchQueue.main.async {
                    self.questions = fetchedQuestions
                    self.currentQuestionIndex = 0
                    self.isLoading = false
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

    func getOptions(for index: Int) -> [String] {
        let question = questions[index]
        return [question.option1, question.option2, question.option3, question.option4].shuffled()
    }

    func checkAnswer() {
        guard !questions.isEmpty else { return }

        let correctAnswer = questions[currentQuestionIndex].correctAnswer
        let isCorrect = selectedOption == correctAnswer

        feedbackMessage = isCorrect ? "Correct!" : "Incorrect. Try Again."
        if isCorrect { score += 1 }

        storeAnswer(isCorrect: isCorrect)

        // Move to the next question after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedbackMessage = ""
            selectedOption = ""
            currentQuestionIndex = (currentQuestionIndex + 1) % questions.count
        }
    }

    func storeAnswer(isCorrect: Bool) {
        let supabase = SupabaseManager.shared.supabaseClient
        let questionId = questions[currentQuestionIndex].id

        let answerData = AnswerData(user_email: userEmail, question_id: questionId, is_correct: isCorrect)

        Task {
            do {
                let response = try await supabase
                    .from("user_answers")
                    .insert([answerData])
                    .execute()

                if response.status == 201 { // HTTP 201 means "Created"
                    print("Answer stored successfully")
                } else {
                    print("Error storing answer: \(response)")
                }
            } catch {
                print("Error storing answer: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - QuizQuestion Model

struct QuizQuestion: Codable, Identifiable {
    let id: Int
    let category: String
    let question: String
    let correctAnswer: String
    let option1: String
    let option2: String
    let option3: String
    let option4: String

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case question
        case correctAnswer = "correct_answer"
        case option1
        case option2
        case option3
        case option4
    }
}
