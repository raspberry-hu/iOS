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
class MEGAMintNodeInterface: NSObject, MEGARequestDelegate {
    private var nodesToExportCount = 1
    private var semaphore = DispatchSemaphore(value: 1)
    private var justUpgradedToProAccount = false
    override init() {
        nodesToExportCount = 1
        semaphore = DispatchSemaphore(value: 1)
    }
    private func exportNode(node: MEGANode){
        MEGASdkManager.sharedMEGASdk().export(node, delegate: MEGAExportRequestDelegate.init(completion: { [self] (request) in
//            print("测试打印：执行之前\(self?.nodesToExportCount)")
//            (self.nodesToExportCount -= 1)
//            if self.nodesToExportCount == 0 {
//                print("测试打印：执行之中")
                SVProgressHUD.dismiss()
                self.semaphore.signal()
//            }
//            print("测试打印：执行之后\(self?.nodesToExportCount)")
            }, multipleLinks: nodesToExportCount > 1))
    }
    private func removeDelegates() {
        MEGASdkManager.sharedMEGASdk().remove(self as MEGARequestDelegate)
    }
    @objc func MEGAMintNodeInterfaceView(_ node: MEGANode) -> UIViewController{
        if !node.isExported() {
            exportNode(node: node)
            self.semaphore.wait()
        }
//        if node.isExported() {
//            SVProgressHUD.dismiss()
//        }
        let details = MEGAMintNode(node: node)
        return UIHostingController(rootView: details)
    }
}


