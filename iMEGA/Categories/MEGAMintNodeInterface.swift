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
 
    @objc func MEGAMintNodeInterfaceView() -> UIViewController{
        let details = MEGAMintNode()
        return UIHostingController(rootView: details)
    }
}
