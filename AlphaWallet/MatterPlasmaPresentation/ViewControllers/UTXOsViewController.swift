//
//  UTXOsViewController.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import UIKit
import web3swift
import BigInt

class UTXOsViewController: UIViewController {
    
    @IBOutlet weak var walletTableView: UITableView!
    
    var session: WalletSession?
    var keystore: Keystore?
    
    var wallet: Wallet?
    
//    var keysService = WalletsService()
//    var wallets: [WalletModel]?
    var UTXOsArray: [TableUTXO] = []
    var chosenUTXOs: [TableUTXO] = []
    
    convenience init(session: WalletSession,
                     keystore: Keystore) {
        self.init()
        self.session = session
        self.keystore = keystore
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.blue
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.selectedItem?.title = nil
        self.setupTableView()
    }
    
    private func setupTableView() {
        let nibUTXO = UINib.init(nibName: "UTXOCell", bundle: nil)
        self.walletTableView.delegate = self
        self.walletTableView.dataSource = self
        self.walletTableView.tableFooterView = UIView()
        self.walletTableView.addSubview(self.refreshControl)
        self.walletTableView.register(nibUTXO, forCellReuseIdentifier: "UTXOCell")
    }
    
    func initDatabase() {
        guard let wallet = session?.account else {return}
        self.wallet = wallet
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = "Plasma UTXOs"
        self.tabBarController?.tabBar.selectedItem?.title = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UTXOsArray.removeAll()
        updateTable()
    }
    
    func unselectAllUTXOs() {
        var indexPath = IndexPath(row: 0, section: 0)
        for utxo in UTXOsArray {
            self.UTXOsArray[indexPath.row].isSelected = false
            guard let cell = walletTableView.cellForRow(at: indexPath) as? UTXOCell else {return}
            cell.changeSelectButton(isSelected: false)
            indexPath.row += 1
        }
    }
    
    func selectUTXO(cell: UITableViewCell) {
        //        unselectAllUTXOs()
        guard let cell = cell as? UTXOCell else {return}
        guard let indexPathTapped = walletTableView.indexPath(for: cell) else {return}
        let utxo = UTXOsArray[indexPathTapped.row]
        print(utxo)
        let selected = UTXOsArray[indexPathTapped.row].isSelected
        if selected {
            for i in 0..<chosenUTXOs.count where chosenUTXOs[i] == utxo {
                chosenUTXOs.remove(at: i)
                break
            }
        } else {
            guard chosenUTXOs.count < 2 else {return}
            chosenUTXOs.append(utxo)
        }
        print(chosenUTXOs.count)
        UTXOsArray[indexPathTapped.row].isSelected = !selected
        cell.changeSelectButton(isSelected: !selected)
        if chosenUTXOs.count == 2 {
            Alerts().showAccessAlert(for: self, with: "Merge UTXOs?") { [weak self] (result) in
                if result {
                    self?.formMergeUTXOsTransaction(forWallet: utxo.inWallet)
                }
            }
        }
    }
    
    func formMergeUTXOsTransaction(forWallet: Wallet) {
        var inputs = [PlasmaTransactionInput]()
        var mergedAmount: BigUInt = 0
        do {
            for utxo in chosenUTXOs {
                let input = try? utxo.utxo.toTransactionInput()
                if let i = input {
                    inputs.append(i)
                    mergedAmount += i.amount
                }
            }
            guard let address = EthereumAddress(forWallet.address.description) else {return}
            let output = try PlasmaTransactionOutput(outputNumberInTx: 0,
                                                     receiverEthereumAddress: address,
                                                     amount: mergedAmount)
            let outputs = [output]
            let transaction = try PlasmaTransaction(txType: .merge,
                                              inputs: inputs,
                                              outputs: outputs)
            print(transaction)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        UTXOsArray.removeAll()
        reloadDataInTable()
        updateTable()
    }
    
    func reloadDataInTable() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.walletTableView.reloadData()
        }
    }
    
    func updateTable() {
        DispatchQueue.global().async { [weak self] in
            self?.updatePlasmaBlockchain()
        }
    }
    
    func updatePlasmaBlockchain() {
        initDatabase()
        //        twoDimensionalUTXOsArray.removeAll()
        let chainID = self.session?.config.chainID
        guard let address = self.wallet?.address.description else {
            self.reloadDataInTable()
            return
        }
        guard let wallet = self.wallet else {
            self.reloadDataInTable()
            return
        }
        guard let ethAddress = EthereumAddress(address) else {
            self.reloadDataInTable()
            return
        }
        let mainnet = chainID == 1
        let testnet = !mainnet && chainID == 4
        if !testnet && !mainnet {
            self.reloadDataInTable()
            return
        }
        guard let utxos = try? PlasmaService().getUTXOs(for: ethAddress, onTestnet: testnet) else {
            self.reloadDataInTable()
            return
        }
        let tableUTXOs = utxos.map{
            TableUTXO(utxo: $0,
                      inWallet: wallet,
                      isSelected: false)
        }
        self.UTXOsArray = tableUTXOs
        self.reloadDataInTable()
    }
    
}

extension UTXOsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UTXOsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UTXOCell",
                                                       for: indexPath) as? UTXOCell else {
                                                        return UITableViewCell()
        }
        cell.link = self
        let utxo = UTXOsArray[indexPath.row]
        cell.configure(utxo: utxo.utxo, forWallet: utxo.inWallet)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else {
            return
        }
        let cell = tableView.cellForRow(at: indexPathForSelectedRow) as? UTXOCell
        
        guard let selectedCell = cell else {
            return
        }
        
        guard let indexPathTapped = walletTableView.indexPath(for: selectedCell) else {
            return
        }
        
        let utxo = UTXOsArray[indexPathTapped.row]
        print(utxo)
        
//        let utxoViewController = UTXOViewController(
//            wallet: utxo.inWallet,
//            utxo: utxo.utxo,
//            value: selectedCell.balance.text ?? "0")
//        self.navigationController?.pushViewController(utxoViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
