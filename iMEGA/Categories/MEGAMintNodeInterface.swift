//
//  MEGAMintNodeInterface.swift
//  MEGA
//
//  Created by hu on 2022/03/04.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import SwiftUI
@objc
class MEGAMintNodeInterface: NSObject {
//    var node = MEGANode()

    @objc func MEGAMintNodeInterfaceView(_ node: MEGANode) -> UIViewController{
        let details = MEGAMintNode(node: node)
        return UIHostingController(rootView: details)
    }
}

