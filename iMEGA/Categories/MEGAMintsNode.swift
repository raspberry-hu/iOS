//
//  MEGAMintsNode.swift
//  MEGA
//
//  Created by hu on 2022/03/08.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import SwiftUI
import ACarousel

class File {
static func getUserFilePath() -> URL{
    let manager = FileManager.default
    let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
    let url = urlForDocument[0] as URL
    return url
    }
}

struct MEGAMintsNode: View {
    var node = [MEGANode()]
    let docPath = File.getUserFilePath()

    var body: some View {
        VStack {
            ACarousel(node, id: \.self, spacing: 10, headspace: 10, sidesScaling: 0.7, isWrap: true, autoScroll: .active(5)) { nodes in
                let file = docPath.appendingPathComponent(nodes.name ?? "Nothing")
                let imgData = try! Data.init(contentsOf: file)
                let imageTemp = UIImage(data: imgData)
                Image(uiImage: imageTemp!)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .cornerRadius(20)
            }
            .frame(height: 300)
        }
    }
}


