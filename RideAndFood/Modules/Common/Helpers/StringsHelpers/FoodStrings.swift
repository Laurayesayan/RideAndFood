//
//  FoodStrings.swift
//  RideAndFood
//
//  Created by Oleksandr Karpenko on 19.11.2020.
//  Copyright © 2020 skillbox. All rights reserved.
//

import Foundation

enum FoodSelectAddressStrings {
    case addressTextField
    
    func text() -> String {
        switch UserConfig.shared.settings.language {
        case .rus:
            return rus()
        case .eng:
            return eng()
        }
    }
    
    func rus() -> String {
        switch self {
        case .addressTextField:
            return "Введите адрес доставки"
        }
    }
    
    func eng() -> String {
        switch self {
        case .addressTextField:
            return "Enter delivery address"
        }
    }
}