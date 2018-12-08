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
    
    private let alerts = Alerts()
    
    private var session: WalletSession?
    private var keystore: Keystore?
    
    private var wallet: Wallet?
    
    private var UTXOsArray: [TableUTXO] = []
    private var chosenUTXOs: [TableUTXO] = []
    
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
    
    private func initDatabase() {
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
    
    private func unselectAllUTXOs() {
        var indexPath = IndexPath(row: 0, section: 0)
        for _ in UTXOsArray {
            self.UTXOsArray[indexPath.row].isSelected = false
            guard let cell = walletTableView.cellForRow(at: indexPath) as? UTXOCell else {return}
            cell.changeSelectButton(isSelected: false)
            indexPath.row += 1
        }
    }
    
    func selectUTXO(cell: UITableViewCell) {
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
            alerts.showAccessAlert(for: self, with: "Merge UTXOs?") { [weak self] (result) in
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
            self.signAndSend(transaction: transaction)
        } catch let error {
            alerts.showErrorAlert(for: self, error: error, completion: {})
        }
    }
    
    private func formSplitUTXOsTransaction(utxo: PlasmaUTXOs, address: String, amount: String) -> PlasmaTransaction? {
        do {
            let input = try utxo.toTransactionInput()
            let inputs = [input]
            let destinationAddress = address.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard let floatAmount = Float(amount) else {
                return nil
            }
            let uintAmount = BigUInt( floatAmount * 1000000 )
            let amountSendInETH = uintAmount * BigUInt(1000000000000)
            let amountStayInETH = input.amount - amountSendInETH
            
            guard let ethDestinationAddress = EthereumAddress(destinationAddress) else {
                return nil
            }
            guard let wallet = self.wallet else {
                return nil
            }
            guard let ethCurrentAddress = EthereumAddress(wallet.address.description) else {
                return nil
            }
            
            let output1 = try PlasmaTransactionOutput(outputNumberInTx: 0,
                                                      receiverEthereumAddress: ethDestinationAddress,
                                                      amount: amountSendInETH)
            let output2 = try PlasmaTransactionOutput(outputNumberInTx: 1,
                                                 receiverEthereumAddress: ethCurrentAddress,
                                                 amount: amountStayInETH)
            
            let outputs = [output1, output2]
            
            let transaction = try PlasmaTransaction(txType: .split, inputs: inputs, outputs: outputs)
            return transaction
            
        } catch {
            return nil
        }
    }
    
    private func sendTx(utxo: PlasmaUTXOs) {
        alerts.sendTxDialog(for: self,
                            title: "Send transaction",
                            subtitle: nil,
                            actionTitle: "Send",
                            cancelTitle: "Cancel",
                            addressInputPlaceholder: "Enter address",
                            amountInputPlaceholder: "Enter amount") { [weak self] (address, amount) in
                                if address != nil && amount != nil {
                                    if let transaction = self?.formSplitUTXOsTransaction(utxo: utxo, address: address!, amount: amount!) {
                                        self?.signAndSend(transaction: transaction)
                                    } else {
                                        self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.StructureErrors.wrongData, completion: {})
                                    }
                                } else {
                                    self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.StructureErrors.wrongData, completion: {})
                                }
        }
    }
    
    private func signAndSend(transaction: PlasmaTransaction) {
        do {
            guard let privKey = getPrivKey() else {
                return
            }
            let signedTransaction = try transaction.sign(privateKey: privKey)
            guard let chainID = self.session?.config.chainID else {return}
            let mainnet = chainID == 1
            let testnet = !mainnet && chainID == 4
            if !testnet && !mainnet {return}
            let result = try PlasmaService().sendRawTX(transaction: signedTransaction, onTestnet: testnet)
            switch result {
            case true:
                alerts.showSuccessAlert(for: self) { [weak self] in
                    self?.updateTable()
                }
            default:
                alerts.showErrorAlert(for: self, error: PlasmaErrors.NetErrors.badResponse, completion: {})
            }
        } catch let error {
            alerts.showErrorAlert(for: self, error: error, completion: {})
        }
        
    }
    
    private func getPrivKey() -> Data? {
//        guard let address = wallet?.address else {return nil}
//        // TODO: - It's not secure
//        guard let keys: EtherKeystore = self.keystore as? EtherKeystore else {return nil}
//        guard let account = keys.getAccount(for: address) else {return nil}
////        guard let password = keystore?.getPassword(for: account) else {return nil}
//        let result = keys.exportPrivateKey(account: account)
//        switch result {
//        case .success(let privKey):
//            return privKey
//        default:
//            return nil
//        }
        return Data(hex: "BDBA6C3D375A8454993C247E2A11D3E81C9A2CE9911FF05AC7FF0FCCBAC554B5")
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
        sendTx(utxo: utxo.utxo)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
