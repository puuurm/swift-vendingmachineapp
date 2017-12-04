//
//  VendingMachineViewController.swift
//  VendingMachineApp
//
//  Created by yangpc on 2017. 11. 30..
//  Copyright © 2017년 yang hee jung. All rights reserved.
//

import UIKit

class VendingMachineViewController: UIViewController {
    // 음료 추가 컨트롤러 -> Manager Mode
    @IBOutlet var imageViews: [UIImageView]!
    @IBOutlet var inventoryLable: [UILabel]!
    var vendingMachine: VendingMachine!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageViews.forEach { (imageView: UIImageView) in
            let tap = UITapGestureRecognizer(target: self, action: #selector(VendingMachineViewController.drinkViewDidTap))
            imageView.addGestureRecognizer(tap)
            imageView.isUserInteractionEnabled = true
        }
        updateInventory()
    }

    // 음료 이미지를 클릭했을 경우
    @objc func drinkViewDidTap(_ recognizer: UITapGestureRecognizer) {
        initManagerMode()
        if let imageView = recognizer.view as? UIImageView {
            vendingMachine.action(action: Action(option: 1, detail: imageView.tag)!)
        }
        updateInventory()
    }

    // Manager Mode로 초기화
    func initManagerMode() {
        if vendingMachine.hasMode {
            vendingMachine.action(action: Action(option: 3, detail: -1)!)
        }
        do {
            try vendingMachine.assignMode(mode: 1)
        } catch let error {
            print(error)
        }
    }

    // 재고 업데이트
    func updateInventory() {
        let menuContents = vendingMachine.makeMenu()
        for lable in inventoryLable.enumerated() {
            guard let drink = menuContents?.menu[lable.offset] else {
                continue
            }
            lable.element.text = "\(menuContents?.inventory[drink] ?? 0 )"
        }
    }


}
