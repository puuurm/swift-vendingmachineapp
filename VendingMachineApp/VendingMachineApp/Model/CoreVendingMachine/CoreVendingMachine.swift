//
//  CoreVendingMachine.swift
//  VendingMachine
//
//  Created by yangpc on 2017. 11. 17..
//  Copyright © 2017년 JK. All rights reserved.
//

import Foundation

typealias Count = Int
typealias Price = Int

final class CoreVendingMachine {
    private var inventory: [Drink]
    private var purchases: [Drink]
    private var inputMoney: Price
    private var income: Price
    private var menu: Menu

    init() {
        inventory = [Drink]()
        purchases = [Drink]()
        menu = Menu()
        inputMoney = 0
        income = 0
        setUnarchivedProperties()
    }

}

extension CoreVendingMachine {
    private enum CodingKeys: String {
        case inventory, inputMoney
    }

    private func makeURLForKey(key: CodingKeys) -> URL {
        let archiveFileName = key.rawValue
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(archiveFileName)
    }

    private func setUnarchivedProperties() {
        inventory = unarchive(key: .inventory) as? [Drink] ?? []
        inputMoney = unarchive(key: .inputMoney) as? Int ?? 0
    }

    private func unarchive(key: CodingKeys) -> Any? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: makeURLForKey(key: key).path)
    }

    private func archive<T>(_ objects: inout T, key: CodingKeys) -> Bool {
        return NSKeyedArchiver.archiveRootObject(objects,
                                                 toFile: makeURLForKey(key: key).path)
    }

    func saveChanges() -> Bool {
        return archive(&inventory, key: .inventory) && archive(&inputMoney, key: .inputMoney)
    }

}


extension CoreVendingMachine: ManagerModeDelegate {

    // 음료수 인덱스를 넘겨서 재고를 추가하는 메소드
    func add(productIndex: Int) throws {
        let listOfDrink = AllDrinkList()
        guard productIndex >= 0 && productIndex < listOfDrink.count else {
            throw stockError.invalidProductNumber
        }
        inventory.append(listOfDrink[productIndex])
        NotificationCenter.default.post(name: .didAddInventoryNotification,
                                        object: nil,
                                        userInfo: ["productIndex": productIndex])
    }

    // 음료수 인덱스를 넘겨서 재고의 음료수를 삭제하는 메소드
    @discardableResult func delete(productIndex: Int) throws -> Drink {
        let listOfDrink = AllDrinkList()
        guard productIndex >= 0 && productIndex < listOfDrink.count else {
            throw stockError.invalidProductNumber
        }
        let deleteDrink = listOfDrink[productIndex]
        for drink in inventory.enumerated() {
            if drink.element === deleteDrink {
                inventory.remove(at: drink.offset)
                return drink.element
            }
        }
        throw stockError.empty
    }

    func howMuchIncome() -> Price {
        return income
    }

    // 전체 상품 재고를 (사전으로 표현하는) 종류별로 리턴하는 메소드
    func listOfInventory() -> [Drink: Count] {
        var countDictionary = [ Drink: Count ]()
        for drink in inventory {
            let count = countDictionary[drink] ?? 0
            countDictionary[drink] = count + 1
        }
        return countDictionary
    }

    // 유통기한이 지난 재고만 리턴하는 메소드
    func listOfOverExpirationDate() -> [Drink] {
        return inventory.filter { drink in
            return !drink.valid(with: Date())
        }
    }

    func AllDrinkList() -> [Drink] {
        return menu.drinkList
    }

}

extension CoreVendingMachine: UserModeDelegate {

    // 자판기 금액을 원하는 금액만큼 올리는 메소드
    func add(money: Int) {
        inputMoney += money
    }

    // 현재 금액으로 구매가능한 음료수 목록을 리턴하는 메소드
    func listOfCanBuy() -> [Drink] {
        let setInventory = Set(inventory)
        let listOfCanBuy = setInventory.filter { inventory in
            return inventory.price <= inputMoney
        }
        return Array(listOfCanBuy)
    }

    @discardableResult func buy(productIndex: Int) throws -> Drink {
        let listOfDrink = AllDrinkList()
        guard productIndex >= 0 && productIndex < listOfDrink.count else {
            throw stockError.invalidProductNumber
        }
        let buyDrink = listOfDrink[productIndex]

        guard inventory.contains(buyDrink) else {
            throw stockError.soldOut
        }
        inputMoney -= buyDrink.price
        income += buyDrink.price
        let indexOfBuyDrink = inventory.index(of: buyDrink) ?? inventory.startIndex
        inventory.remove(at: indexOfBuyDrink)
        purchases.append(buyDrink)
        NotificationCenter.default.post(name: .didBuyDrinkNotifiacation,
                                        object: self,
                                        userInfo: ["buyDrinkImageName": buyDrink.className,
                                                   "count": purchases.count])
        return buyDrink
    }

    // 잔액을 확인하는 메소드
    func howMuchRemainMoney() -> Price {
        return inputMoney
    }

    // 따뜻한 음료만 리턴하는 메소드
    func listOfHotDrink() -> [Drink] {
        return inventory.filter { drink in
            guard let coffee = drink as? Coffee else {
                return false
            }
            return coffee.isHot
        }
    }

    // 시작이후 구매 상품 이력을 배열로 리턴하는 메소드
    func listOfPurchase() -> [Drink] {
        return purchases
    }

    func extractAllMoney() -> Int {
        let change = inputMoney
        inputMoney = 0
        return change
    }

}

extension CoreVendingMachine {
    enum stockError: String, Error {
        case soldOut = "해당 음료수는 품절되었습니다."
        case invalidProductNumber = "유효하지 않은 음료수 번호 입니다."
        case empty = "재고가 하나도 없습니다."
    }

}

extension Notification.Name {
    static let didAddInventoryNotification = Notification.Name(rawValue: "DidAddInventory")
    static let didBuyDrinkNotifiacation = Notification.Name(rawValue: "DidBuyDrink")
}
