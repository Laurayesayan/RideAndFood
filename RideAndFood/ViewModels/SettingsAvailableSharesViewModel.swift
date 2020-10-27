//
//  AvailableSharesViewModel.swift
//  RideAndFood
//
//  Created by Oleksandr Karpenko on 27.10.2020.
//  Copyright © 2020 skillbox. All rights reserved.
//

import RxSwift
import RxDataSources
import Foundation

class SettingsAvailableSharesViewModel {
    
    let items = Observable.just([
        SectionModel(model: "", items: [
            TableItem(title: "Food", cellTypes: [.default()]),
            TableItem(title: "Taxi", cellTypes: [.default()])
        ])
    ])
    
    func dataSource(cellIdentifier: String) -> RxTableViewSectionedReloadDataSource<SectionModel<String, TableItem>> {
        
        return RxTableViewSectionedReloadDataSource<SectionModel<String, TableItem>>(
            configureCell: { (_, tv, indexPath, item) in
                
                let cell = tv.dequeueReusableCell(withIdentifier: cellIdentifier)!
                TableHelper.shared.setupCell(cell, item: item)
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
    }
}
