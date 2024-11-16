//
//  Character.swift
//  learnable
//
//  Created by Han Lee on 11/16/24.
//


struct Character: Codable, Identifiable {
    let id: Int
    let name: String
    let image: String
    let price: Int
}