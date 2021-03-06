//
//  OrderViewDelegate.swift
//  RideAndFood
//
//  Created by Лаура Есаян on 22.11.2020.
//  Copyright © 2020 skillbox. All rights reserved.
//

import Foundation

protocol OrderViewDelegate: class {
    func stateChanged(to newState: MapScreenState)
    func shouldShowTranspatentView()
    func shouldRemoveTranspatentView()
    func buttonTapped(senderType: OrderViewType, addressInfo: String?)
    func locationButtonTapped(senderType: TextViewType)
    func mapButtonTapped(senderType: TextViewType)
}
