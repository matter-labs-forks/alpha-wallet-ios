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
    @IBOutlet weak var balanceLabel: UILabel!
    
    private let alerts = Alerts()
    private let plasmaTxService = PlasmaTransactionsService()
    
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
        self.setBalance()
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
    
    private func setBalance() {
        guard let balance = session?.balance?.amountShort else {
            return
        }
        self.balanceLabel.text = "Balance: " + balance + " ETH"
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
            mergeTx()
        }
    }
    
    private func mergeTx() {
        guard let session = self.session else {
            alerts.showErrorAlert(for: self, error: PlasmaErrors.NetErrors.noData, completion: {})
            return
        }
        guard let wallet = self.wallet else {
            alerts.showErrorAlert(for: self, error: PlasmaErrors.NetErrors.noData, completion: {})
            return
        }
        alerts.showAccessAlert(for: self, with: "Merge UTXOs?") { [weak self] (result) in
            if result {
                guard let transaction = self?.plasmaTxService.formMergeUTXOsTransaction(chosenUTXOs: (self?.chosenUTXOs)!, wallet: wallet) else {
                    self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.StructureErrors.wrongData, completion: {})
                    return
                }
                let result = self?.plasmaTxService.signAndSend(transaction: transaction, inSession: session)
                switch result {
                case true:
                    self?.alerts.showSuccessAlert(for: self!, completion: {
                        self?.updateTable()
                    })
                default:
                    self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.NetErrors.badResponse, completion: {})
                }
            }
        }
        
    }
    
    private func sendTx(utxo: PlasmaUTXOs) {
        guard let session = self.session else {
            alerts.showErrorAlert(for: self, error: PlasmaErrors.NetErrors.noData, completion: {})
            return
        }
        guard let wallet = self.wallet else {
            alerts.showErrorAlert(for: self, error: PlasmaErrors.NetErrors.noData, completion: {})
            return
        }
        alerts.sendTxDialog(for: self,
                            title: "Send transaction",
                            subtitle: nil,
                            actionTitle: "Send",
                            cancelTitle: "Cancel",
                            addressInputPlaceholder: "Enter address",
                            amountInputPlaceholder: "Enter amount") { [weak self] (address, amount) in
            if address != nil && amount != nil {
                guard let transaction = self?.plasmaTxService.formSplitUTXOsTransaction(utxo: utxo, address: address!, amount: amount!, wallet: wallet) else {
                    self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.StructureErrors.wrongData, completion: {})
                    return
                }
                let result = self?.plasmaTxService.signAndSend(transaction: transaction, inSession: session)
                switch result {
                case true:
                    self?.alerts.showSuccessAlert(for: self!, completion: {
                        self?.updateTable()
                    })
                default:
                    self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.NetErrors.badResponse, completion: {})
                }
            } else {
                self?.alerts.showErrorAlert(for: self!, error: PlasmaErrors.StructureErrors.wrongData, completion: {})
            }
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "UTXOs list"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
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
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let utxo = UTXOsArray[indexPath.row]
        let exit = UITableViewRowAction(style: .destructive, title: "Exit") { [weak self] (action, indexPath) in
            self?.updateTable()
        }
        exit.backgroundColor = UIColor.blue
        return [exit]
    }
    
}
