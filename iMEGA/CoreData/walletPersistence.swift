//
//  HDWalletPersistence.swift
//  MEGA
//
//  Created by hu on 2022/03/22.
//  Copyright © 2022 MEGA. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI

    // MARK: - CoreData数据管理类
class CoreDataManager: ObservableObject {
   
    let persistentContainer: NSPersistentContainer
   
    static let shared = CoreDataManager()
    
    @Published var savedEntities: [HDWallet] = []
    
   // MARK: - 增加钱包
    func addHDWallet(name: String, privateKey: String, address: String, mnemonic: String, password: String) {
        
        let newHDWallet = HDWallet(context: persistentContainer.viewContext)
        newHDWallet.name = name
        newHDWallet.privateKey = privateKey
        newHDWallet.address = address
        newHDWallet.mnemonic = mnemonic
        newHDWallet.password = password
        save()
    }
    // MARK: - 获取钱包
    func fetchHDWallet() {
        let request = NSFetchRequest<HDWallet>(entityName: "HDWallet")
        
        do {
            savedEntities = try persistentContainer.viewContext.fetch(request)
        } catch let error {
            print("Error fetching. \(error)")
        }
    }
    
   // MARK: - 删除钱包
    func deleteHDWallet(HDWallet: HDWallet) {
        persistentContainer.viewContext.delete(HDWallet)
        save()
    }

   // MARK: - 通过name删除钱包
    func deleteHDWalletByName(name: String) {
        let fetchRequest = NSFetchRequest<HDWallet>(entityName: "HDWallet")
        let predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedObjects = try persistentContainer.viewContext.fetch(fetchRequest)
            
            for info in fetchedObjects {
                deleteHDWallet(HDWallet: info)
            }
        } catch let error {
            print("Error saving deleting HDWallet by name. \(error)")
        }
        
    }
    
   // MARK: - 通过钱包地址获取助记词
    func fetchHDWalletMnemonicByAddress(address: String) -> String{
        let fetchRequest = NSFetchRequest<HDWallet>(entityName: "HDWallet")
        let predicate = NSPredicate(format: "address == %@", address)
        fetchRequest.predicate = predicate
        var mnemonic:String?
        do {
            let fetchedObjects = try persistentContainer.viewContext.fetch(fetchRequest)
            
            for info in fetchedObjects {
                mnemonic = info.address
            }
        } catch let error {
            print("Error saving deleting HDWallet by name. \(error)")
        }
        return address
    }
    
   // MARK: - 通过index删除钱包
    func deleteHDWalletByIndex(at offsets: IndexSet) {
        let fetchRequest = NSFetchRequest<HDWallet>(entityName: "HDWallet")
        do {
            let fetchedObjects = try persistentContainer.viewContext.fetch(fetchRequest)
            for index in offsets {
                persistentContainer.viewContext.delete(fetchedObjects[index])
                save()
            }
        } catch let error {
            print("Error saving deleting HDWallet by index. \(error)")
        }
    }
    
   // MARK: - 存储
   func save() {
       do {
           try persistentContainer.viewContext.save()
           fetchHDWallet()
       } catch {
           persistentContainer.viewContext.rollback()
           print(error.localizedDescription)
       }
   }
   
    private init() {
       // MARK: - 初始化Core Data容器
       persistentContainer = NSPersistentContainer(name: "HDWalletCoreData")
       // MARK: - 容器加载持久化存储
       persistentContainer.loadPersistentStores { (description, error) in
           if let error = error {
               fatalError("Unable to initialize Core Data Stack \(error)")
           }
       }
       fetchHDWallet()
   }
}

