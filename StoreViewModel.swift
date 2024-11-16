//
//  StoreViewModel.swift
//  learnable
//
//  Created by Han Lee on 11/16/24.
//
import SwiftUI

class StoreViewModel: ObservableObject {
    @Published var characters: [Character] = []

    func purchaseCharacter(userEmail: String, characterId: Int, characterPrice: Int) {
        SupabaseManager.shared.purchaseCharacter(userEmail: userEmail, characterId: characterId, characterPrice: characterPrice)
    }

    func fetchCharacters() {
        SupabaseManager.shared.fetchCharacters { fetchedCharacters in
            DispatchQueue.main.async {
                self.characters = fetchedCharacters
            }
        }
    }
}
