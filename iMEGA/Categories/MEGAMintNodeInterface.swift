//
//  MEGAMintNodeInterface.swift
//  MEGA
//
//  Created by hu on 2022/03/04.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@objc
class MEGAMintNodeInterface: NSObject {
    var nodesToExportCount = 0
    func exportNode(node: MEGANode) {
        MEGASdkManager.sharedMEGASdk().export(node, delegate: MEGAExportRequestDelegate.init(completion: { [weak self] (request) in
            (self?.nodesToExportCount -= 1)
            if self?.nodesToExportCount == 0 {
                SVProgressHUD.dismiss()
            }
            guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: node.handle) else {
                return
            }
            }, multipleLinks: nodesToExportCount > 1))
    }
    
    @objc func MEGAMintNodeInterfaceView(_ node: MEGANode) -> UIViewController{
        if !node.isExported() {
            nodesToExportCount += 1
        }
        exportNode(node: node)
        let details = MEGAMintNode(node: node)
        return UIHostingController(rootView: details)
    }
}

