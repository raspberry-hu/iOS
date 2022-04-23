//
//  folderMonitorInterface.swift
//  MEGA
//
//  Created by hu on 2022/03/07.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import SwiftUI
@objc

class FolderMonitorInterface: NSObject {
 
    var numbers: Int?
//    var url: URL?
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
    private lazy var folderMonitor = folderMonitor(url: self.url)
    
    override init() {
        folderMonitor.folderDidChange = { [weak self] in
            self?.handleChanges()
        }
        folderMonitor.startMonitoring()
        self.handleChanges()
    }
    
    func handleChanges() {
        DispatchQueue.main.async {
            self.numbers! -= 1
        }
    }
}
