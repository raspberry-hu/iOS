//
//  walletView.swift
//  MEGA
//
//  Created by hu on 2022/03/02.
//  Copyright © 2022 MEGA. All rights reserved.
//

import SwiftUI

struct BoatDetailsView: View {
    var shipName = ""
    var body: some View {
        TabView {
            Text("资产")
                .tabItem {
                    Image(systemName: "bitcoinsign.square")
                    Text("资产")
                }
            Text("NFT市场")
                .tabItem {
                    Image(systemName: "cart")
                    Text("NFT市场")
                }
            Text("DSC网盘")
                .tabItem {
                    Image(systemName: "externaldrive.badge.icloud")
                    Text("DSC网盘")
                }
            Text("设置")
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
        .font(.headline)
    }
}

