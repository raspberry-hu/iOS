//
//  MEGAMintsNodeInterface.swift
//  MEGA
//
//  Created by hu on 2022/03/08.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import SwiftUI
@objc
class MEGAMintsNodeInterface: NSObject {

    @objc func MEGAMintsNodeInterfaceView(_ node: [MEGANode]) -> UIViewController{
        let details = MEGAMintsNode(node: node)
        return UIHostingController(rootView: details)
    }
}
