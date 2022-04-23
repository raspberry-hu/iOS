//
//  EthereumTransaction.swift
//  MEGA
//
//  Created by hu on 2022/03/24.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import Web3

extension EthereumTransaction {
var description: String {
    return """
    from: \(String(describing: from!.hex(eip55: true)))
    to: \(String(describing: to!.hex(eip55: true))),
    value: \(String(describing: value!.hex())),
    gasPrice: \(String(describing: gasPrice?.hex())),
    gas: \(String(describing: gas?.hex())),
    data: \(data.hex()),
    nonce: \(String(describing: nonce?.hex()))
    """
}
}
