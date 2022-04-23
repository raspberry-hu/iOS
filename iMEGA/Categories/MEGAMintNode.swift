//
//  MEGAMintNode.swift
//  MEGA
//
//  Created by hu on 2022/03/04.
//  Copyright © 2022 MEGA. All rights reserved.
//

import SwiftUI

struct MEGAMintNode: View {
    var node = MEGANode()
    var body: some View {
        VStack {
            Text(node.base64Handle ?? "No Base64")
            Text(node.name ?? "No Name")
            Text(node.publicLink ?? "No URL")
        }
    }
}
