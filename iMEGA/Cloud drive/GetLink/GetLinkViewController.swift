import UIKit

enum GetLinkTableViewSection: Int {
    case info
    case decryptKeySeparate
    case expiryDate
    case passwordProtection
    case link
    case key
}

enum ExpiryDateSectionRow {
    case activateExpiryDate
    case configureExpiryDate
    case pickExpiryDate
}

enum PasswordProtectionSectionRow {
    case configurePasword
}

enum LinkSectionRow {
    case link
    case password
    case removePassword
}

enum KeySectionRow {
    case key
}

struct GetLinkViewModel {
    var link: String = ""
    var separateKey: Bool = false
    var linkWithoutKey: String {
        if link.contains("file") || link.contains("folder") {
            return link.components(separatedBy: "#")[0]
        } else {
            return link.components(separatedBy: "!")[0] + "!" + link.components(separatedBy: "!")[1]
        }
    }
    var key: String {
        get {
            if link.contains("file") || link.contains("folder") {
                return link.components(separatedBy: "#")[1]
            } else {
                return link.components(separatedBy: "!")[2]
            }
        }
    }
    var expiryDate: Bool = false
    var date: Date?
    var selectDate: Bool = false
    var passwordProtect: Bool = false
    var password: String?
    var multilink: Bool = false
}

class GetLinkViewController: UIViewController {
    
    private lazy var dateFormatter = DateFormatter.dateMedium()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var multilinkDescriptionLabel: UILabel!
    @IBOutlet weak var multilinkDescriptionView: UIView!
    @IBOutlet weak var multilinkDescriptionStackView: UIStackView!
    @IBOutlet private var shareBarButton: UIBarButtonItem!
    @IBOutlet private var copyLinkBarButton: UIBarButtonItem!
    @IBOutlet private var copyKeyBarButton: UIBarButtonItem!
    
    let flexibleBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    private var nodes = [MEGANode]()
    private var getLinkVM = GetLinkViewModel()
    private var nodesToExportCount = 0
    private var justUpgradedToProAccount = false
    
    @objc class func instantiate(withNodes nodes: [MEGANode]) -> MEGANavigationController {
        guard let getLinkVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "GetLinksViewControllerID") as? GetLinkViewController else {
            fatalError("Could not instantiate GetLinkViewController")
        }
        
        getLinkVC.nodes = nodes
        getLinkVC.getLinkVM.multilink = nodes.count > 1
        
        return MEGANavigationController.init(rootViewController: getLinkVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !MEGASdkManager.sharedMEGASdk().mnz_isProAccount {
            MEGASdkManager.sharedMEGASdk().add(self as MEGARequestDelegate)
            
            MEGAPurchase.sharedInstance()?.purchaseDelegateMutableArray.add(self)
            MEGAPurchase.sharedInstance()?.restoreDelegateMutableArray.add(self)
        }
        
        configureNavigation()
        
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        
        if getLinkVM.multilink {
            multilinkDescriptionLabel.text = Strings.Localizable.optionsSuchAsSendDecryptionKeySeparatelySetExpiryDateOrPasswordsAreOnlyAvailableForSingleItems
            multilinkDescriptionView.isHidden = false
        } else {
            tableView.isUserInteractionEnabled = false
        }
        
        processNodes()
        
        shareBarButton.title = Strings.Localizable.share
        copyLinkBarButton.title = getLinkVM.multilink ? Strings.Localizable.copyAll : Strings.Localizable.copyLink
        copyKeyBarButton.title = Strings.Localizable.copyKey
        
        updateAppearance()
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        
        if isMovingFromParent && !MEGASdkManager.sharedMEGASdk().mnz_isProAccount {
            removeDelegates()
        }
        
        NotificationCenter.default.post(name: Notification.Name.MEGAShareCreated, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
            tableView.reloadData()
        }
    }
    
    //MARK: - Private
    
    private func configureNavigation() {
        navigationController?.setToolbarHidden(false, animated: true)
        
        if getLinkVM.multilink {
            title = nodes.filter { !$0.isExported() }.count == 0 ? Strings.Localizable.manageLinks : Strings.Localizable.getLinks
        } else {
            title = nodes[0].isExported() ? Strings.Localizable.manageLink : Strings.Localizable.getLink
        }
        
        setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        let doneBarButtonItem = UIBarButtonItem(title: Strings.Localizable.done, style: .done, target: self, action: #selector(doneBarButtonTapped))
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        multilinkDescriptionStackView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
    }
    
    private func configureDecryptKeySeparate(isOn: Bool) {
        getLinkVM.separateKey = isOn
        tableView.reloadData()
        if getLinkVM.separateKey {
            setToolbarItems([shareBarButton, flexibleBarButton, copyKeyBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        } else {
            setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        }
    }
    
    private func configureExpiryDate(isOn: Bool) {
        getLinkVM.expiryDate = isOn
        if !getLinkVM.expiryDate && getLinkVM.date != nil {
            nodesToExportCount = 1
            exportNode(node: nodes[0])
        }
        getLinkVM.date = nil
        getLinkVM.selectDate = false
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate), let linkSection = sections().firstIndex(of: .link) else { return }
        tableView.reloadSections([expiryDateSection, linkSection], with: .automatic)
    }
    
    private func copyKeyToPasteBoard() {
        UIPasteboard.general.string = getLinkVM.key
        SVProgressHUD.show(Asset.Images.NodeActions.copy.image, status: Strings.Localizable.keyCopiedToClipboard)
    }
    
    private func copyLinkToPasteboard(atIndex index: Int?) {
        if getLinkVM.multilink {
            if let index = index, let link = nodes[safe: index]?.publicLink {
                UIPasteboard.general.string = link
                SVProgressHUD.show(Asset.Images.NodeActions.copy.image, status: Strings.Localizable.linkCopiedToClipboard)
            } else {
                UIPasteboard.general.string = nodes.compactMap { $0.publicLink }.joined(separator: " ")
                SVProgressHUD.show(Asset.Images.NodeActions.copy.image, status: Strings.Localizable.linksCopiedToClipboard)
            }
        } else {
            if getLinkVM.separateKey {
                UIPasteboard.general.string = getLinkVM.linkWithoutKey
            } else {
                UIPasteboard.general.string = getLinkVM.link
            }
            SVProgressHUD.show(Asset.Images.NodeActions.copy.image, status: Strings.Localizable.linkCopiedToClipboard)
        }
    }
    
    private func copyPasswordToPasteboard() {
        UIPasteboard.general.string = getLinkVM.password
        SVProgressHUD.show(Asset.Images.NodeActions.copy.image, status: Strings.Localizable.passwordCopiedToClipboard)
    }
    
    private func updateModel(forNode node: MEGANode) {
        guard let index = nodes.firstIndex(where: { $0.handle == node.handle } ) else { return }
        nodes[index] = node
        if getLinkVM.multilink {
            tableView.reloadSections([index], with: .automatic)
        } else {
            var sectionsToReload = IndexSet()
            
            if getLinkVM.link.isEmpty {
                getLinkVM.link = node.publicLink ?? ""
                guard let linkSection = sections().firstIndex(of: .link) else {
                    return
                }
                sectionsToReload.insert(linkSection)
            }
            
            if node.expirationTime > 0 {
                getLinkVM.expiryDate = true
                getLinkVM.date = Date(timeIntervalSince1970: TimeInterval(node.expirationTime))
            }
            
            if !getLinkVM.link.isEmpty {
                tableView.isUserInteractionEnabled = true
            }
            
            guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else {
                return
            }
            sectionsToReload.insert(expiryDateSection)
            
            tableView.reloadSections(sectionsToReload, with: .automatic)
        }
    }
    
    private func processNodes() {
        nodesToExportCount = nodes.filter { !$0.isExported() }.count
        nodes.forEach { (node) in
            if node.isExported() {
                updateModel(forNode: node)
            } else {
                exportNode(node: node)
            }
        }
    }
    
    private func exportNode(node: MEGANode) {
        MEGASdkManager.sharedMEGASdk().export(node, delegate: MEGAExportRequestDelegate.init(completion: { [weak self] (request) in
            (self?.nodesToExportCount -= 1)
            if self?.nodesToExportCount == 0 {
//                print("测试获取：\(self?.nodesToExportCount)")
                SVProgressHUD.dismiss()
            }
            guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: node.handle) else {
                return
            }
            self?.updateModel(forNode: nodeUpdated)
            }, multipleLinks: nodesToExportCount > 1))
    }
    
    @objc private func learnMoreTapped() {
        guard let decryptionKeyVC = storyboard?.instantiateViewController(withIdentifier: "DecryptionKeysViewControllerID") else {
            return
        }
        let decryptionKeyNavigation = MEGANavigationController.init(rootViewController: decryptionKeyVC)
        present(decryptionKeyNavigation, animated: true, completion: nil)
    }
    
    @objc private func doneBarButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func sections() -> [GetLinkTableViewSection] {
        var sections = [GetLinkTableViewSection]()
        
        sections.append(.info)
        sections.append(.decryptKeySeparate)
        sections.append(.expiryDate)
        sections.append(.passwordProtection)
        sections.append(.link)
        if getLinkVM.separateKey {
            sections.append(.key)
        }
        
        return sections
    }
    
    private func expireDateRows() -> [ExpiryDateSectionRow] {
        var expireDateRows = [ExpiryDateSectionRow]()
        expireDateRows.append(.activateExpiryDate)
        if getLinkVM.expiryDate {
            expireDateRows.append(.configureExpiryDate)
        }
        if getLinkVM.selectDate {
            expireDateRows.append(.pickExpiryDate)
        }
        return expireDateRows
    }
    
    private func passwordProtectionRows() -> [PasswordProtectionSectionRow] {
        return [.configurePasword]
    }
    
    private func linkRows() -> [LinkSectionRow] {
        var linkRows = [LinkSectionRow]()
        linkRows.append(.link)
        if getLinkVM.passwordProtect && getLinkVM.password != nil {
            linkRows.append(.password)
            linkRows.append(.removePassword)
        }
        return linkRows
    }
    
    private func keyRows() -> [KeySectionRow] {
        var keyRows = [KeySectionRow]()
        keyRows.append(.key)
        return keyRows
    }
    
    private func encrypt(link: String, with password: String) {
        MEGASdkManager.sharedMEGASdk().encryptLink(withPassword: link, password: password, delegate: MEGAPasswordLinkRequestDelegate.init(completion: {(request) in
            SVProgressHUD.dismiss()
            guard let encryptedLink = request?.text else {
                return
            }
            self.getLinkVM.link = encryptedLink
            self.getLinkVM.password = password
            self.getLinkVM.passwordProtect = true
            self.configureDecryptKeySeparate(isOn: false)
            
            guard let linkSection = self.sections().firstIndex(of: .link), let expiryDateSection = self.sections().firstIndex(of: .expiryDate) else {
                return
            }
            self.tableView.reloadSections([linkSection, expiryDateSection], with: .automatic)
        }, multipleLinks: false))
    }
    
    private func setExpiryDate() {
        MEGASdkManager.sharedMEGASdk().export(nodes[0], expireTime: getLinkVM.date ?? Date(timeInterval: 24*60*60, since: Date()), delegate: MEGAExportRequestDelegate.init(completion: { [weak self] (request) in
            guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: self?.nodes[0].handle ?? MEGAInvalidHandle) else {
                return
            }
            
            if self?.getLinkVM.passwordProtect ?? false, let password = self?.getLinkVM.password, let publicLink = nodeUpdated.publicLink {
                self?.encrypt(link: publicLink, with: password)
            } else {
                SVProgressHUD.dismiss()
                self?.updateModel(forNode: nodeUpdated)
            }
        }, multipleLinks: false))
    }
    
    private func showIncompleteShareLinkAlert(title: String, message: String, completion: @escaping (() -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Localizable.dismiss, style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: Strings.Localizable.share, style: .default, handler: { _ in
            completion()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func showShareActivity(_ sender: UIBarButtonItem, textToShare: String, completion: (() -> Void)?) {
        let shareActivity = UIActivityViewController(activityItems: [textToShare], applicationActivities: [SendToChatActivity(text: textToShare)])
        shareActivity.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll, .addToReadingList, .airDrop]
        shareActivity.popoverPresentationController?.barButtonItem = sender
        shareActivity.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                guard let completion = completion else { return }
                completion()
            }
        }
        present(shareActivity, animated: true, completion: nil)
    }
    
    private func showUpgradeToProCustomModalAlert() {
        let upgradeToProCustomModalAlert = CustomModalAlertViewController()
        upgradeToProCustomModalAlert.configureUpgradeToPro()

        UIApplication.mnz_presentingViewController().present(upgradeToProCustomModalAlert, animated: true, completion: nil)
    }
    
    private func reloadProSections() {
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate), let passwordSection = sections().firstIndex(of: .passwordProtection) else {
            return
        }
        tableView.reloadSections([expiryDateSection, passwordSection], with: .automatic)
    }
    
    private func removeDelegates() {
        MEGASdkManager.sharedMEGASdk().remove(self as MEGARequestDelegate)
        
        MEGAPurchase.sharedInstance()?.purchaseDelegateMutableArray.remove(self)
        MEGAPurchase.sharedInstance()?.restoreDelegateMutableArray.remove(self)
    }
    
    //MARK: - IBActions
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        guard let point = sender.superview?.convert(sender.center, to: tableView), let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        switch sections()[indexPath.section] {
        case .decryptKeySeparate:
            configureDecryptKeySeparate(isOn: sender.isOn)
        case .expiryDate:
            if justUpgradedToProAccount {
                //Activity indicators are shown until the updated account details are received
                return
            }
            
            if MEGASdkManager.sharedMEGASdk().mnz_isProAccount {
                configureExpiryDate(isOn: sender.isOn)
            } else {
                showUpgradeToProCustomModalAlert()
                sender.isOn = false
            }
        default:
            break
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        getLinkVM.date = sender.date
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
        tableView.reloadSections([expiryDateSection], with: .automatic)
    }
    
    @IBAction func shareBarButtonTapped(_ sender: UIBarButtonItem) {
        let textToShare = getLinkVM.multilink ? nodes.compactMap { $0.publicLink }.joined(separator: "\n") : getLinkVM.separateKey ? getLinkVM.linkWithoutKey : getLinkVM.link
        
        showShareActivity(sender, textToShare: textToShare) { [weak self] in
            if self?.getLinkVM.separateKey ?? false {
                self?.showIncompleteShareLinkAlert(title: Strings.Localizable.decryptionKey, message: Strings.Localizable.ThisLinkWasSharedWithoutADecryptionKey.doYouWantToShareItsKey.localizedCapitalized) {
                    guard let key = self?.getLinkVM.key else {
                        return
                    }
                    self?.showShareActivity(sender, textToShare: key, completion: nil)
                }
            }
            
            if self?.getLinkVM.passwordProtect ?? false {
                self?.showIncompleteShareLinkAlert(title: Strings.Localizable.linkPassword, message: Strings.Localizable.doYouWantToShareThePasswordForThisLink) {
                    guard let password = self?.getLinkVM.password else {
                        return
                    }
                    self?.showShareActivity(sender, textToShare: password, completion: nil)
                }
            }
        }
    }
    
    @IBAction func copyKeyBarButtonTapped(_ sender: UIBarButtonItem) {
        copyKeyToPasteBoard()
    }
    
    @IBAction func copyLinkBarButtonTapped(_ sender: UIBarButtonItem) {
        copyLinkToPasteboard(atIndex: nil)
    }
    
    //MARK: - TableView cells
    
    private func infoCell(forIndexPath indexPath: IndexPath) -> GetLinkInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkInfoTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkInfoTableViewCell else {
            fatalError("Could not get GetLinkInfoTableViewCell")
        }
        
        cell.configure(forNode: nodes[indexPath.section])
        
        return cell
    }
    
    private func decryptKeySeparateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureDecryptKeySeparatedCell(isOn: getLinkVM.separateKey, enabled: !getLinkVM.passwordProtect)
        
        return cell
    }
    
    private func activateExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureActivateExpiryDateCell(isOn: getLinkVM.expiryDate, isPro:MEGASdkManager.sharedMEGASdk().mnz_isProAccount, justUpgraded:justUpgradedToProAccount)
        
        return cell
    }
    
    private func configureExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureExpiryDateCell(date: getLinkVM.date, dateSelected: getLinkVM.selectDate)
        
        return cell
    }
    
    private func pickExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkDatePickerTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDatePickerTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDatePickerTableViewCell else {
            fatalError("Could not get GetLinkDatePickerTableViewCell")
        }
        
        cell.configureDatePickerCell(date: getLinkVM.date)
        
        return cell
    }
    
    private func configurePasswordCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configurePasswordCell(passwordActive: getLinkVM.passwordProtect, isPro:MEGASdkManager.sharedMEGASdk().mnz_isProAccount, justUpgraded:justUpgradedToProAccount)
        
        return cell
    }
    
    private func linkCell(forIndexPath indexPath: IndexPath) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        if getLinkVM.multilink {
            let node = nodes[indexPath.section]
            let publicLink = node.publicLink ?? ""
            cell.configureLinkCell(link: node.isExported() ? publicLink : "")
        } else {
            if getLinkVM.separateKey {
                cell.configureLinkCell(link: getLinkVM.linkWithoutKey)
            } else {
                cell.configureLinkCell(link: getLinkVM.link)
            }
        }
        
        return cell
    }
    
    private func passwordCell(forIndexPath indexPath: IndexPath) -> GetLinkPasswordTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkPasswordTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkPasswordTableViewCell else {
            fatalError("Could not get GetLinkPasswordTableViewCell")
        }
        
        cell.configurePasswordCell(password: getLinkVM.password ?? "")
        
        return cell
    }
    
    private func keyCell(forIndexPath indexPath: IndexPath) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        cell.configureKeyCell(key: getLinkVM.key)
        
        return cell
    }
    
    private func removePasswordCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureRemovePasswordCell()
        
        return cell
    }
    
}

//MARK: - UITableViewDataSource

extension GetLinkViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if getLinkVM.multilink {
            return nodes.count
        } else {
            return sections().count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if getLinkVM.multilink {
            return 2
        } else {
            switch sections()[section] {
            case .info, .decryptKeySeparate:
                return 1
            case .expiryDate:
                return expireDateRows().count
            case .passwordProtection:
                return passwordProtectionRows().count
            case .link:
                return linkRows().count
            case .key:
                return keyRows().count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if getLinkVM.multilink {
            if indexPath.row == 0 {
                return infoCell(forIndexPath: indexPath)
            } else {
                return linkCell(forIndexPath: indexPath)
            }
        } else {
            switch sections()[indexPath.section] {
            case .info:
                return infoCell(forIndexPath: indexPath)
            case .decryptKeySeparate:
                return decryptKeySeparateCell(forIndexPath: indexPath)
            case .expiryDate:
                switch expireDateRows()[indexPath.row] {
                case .activateExpiryDate:
                    return activateExpiryDateCell(forIndexPath: indexPath)
                case .configureExpiryDate:
                    return configureExpiryDateCell(forIndexPath: indexPath)
                case .pickExpiryDate:
                    return pickExpiryDateCell(forIndexPath: indexPath)
                }
            case .passwordProtection:
                switch passwordProtectionRows()[indexPath.row] {
                case .configurePasword:
                    return configurePasswordCell(forIndexPath: indexPath)
                }
            case .link:
                switch linkRows()[indexPath.row] {
                case .link:
                    return linkCell(forIndexPath: indexPath)
                case .password:
                    return passwordCell(forIndexPath: indexPath)
                case .removePassword:
                    return removePasswordCell(forIndexPath: indexPath)
                }
            case .key:
                return keyCell(forIndexPath: indexPath)
            }
        }
    }
}

//MARK: - UITableViewDelegate

extension GetLinkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        header.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        
        if getLinkVM.multilink {
            header.titleLabel.textAlignment = .left
            header.configure(title: Strings.Localizable.link, topDistance: section == 0 ? 17.0 : 25.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        } else {
            switch sections()[section] {
            case .link:
                header.configure(title: Strings.Localizable.link, topDistance: 17.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            case .key:
                header.configure(title: Strings.Localizable.key, topDistance: 17.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            case .decryptKeySeparate:
                header.configure(title: nil, topDistance: 10.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            case .expiryDate:
                header.configure(title: nil, topDistance: 17.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            case .passwordProtection:
                header.configure(title: nil, topDistance: 10.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            default:
                header.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
            }
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        footer.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)

        if getLinkVM.multilink {
            footer.titleLabel.textAlignment = .center
            footer.configure(title: Strings.Localizable.tapToCopy, topDistance: 4, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
        } else {
            switch sections()[section] {
            case .decryptKeySeparate:
                let attributedString = NSMutableAttributedString(string: Strings.Localizable.exportTheLinkAndDecryptionKeySeparately)
                let learnMoreString = NSAttributedString(string: " " + Strings.Localizable.learnMore, attributes: [NSAttributedString.Key.foregroundColor: UIColor.mnz_turquoise(for: traitCollection) as Any])
                attributedString.append(learnMoreString)
                footer.titleLabel.numberOfLines = 0
                footer.titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped)))
                footer.titleLabel.isUserInteractionEnabled = true
                
                footer.configure(attributedTitle: attributedString, topDistance: 4.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)

            case .expiryDate:
                if getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil) {
                    footer.configure(title: Strings.Localizable.linkExpires(dateFormatter.localisedString(from: getLinkVM.date ?? Date())), topDistance: 4.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
                } else {
                    footer.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
                }
            case .link, .key, .info, .passwordProtection:
                footer.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
            }
        }
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if getLinkVM.multilink {
            if indexPath.row == 1 {
                copyLinkToPasteboard(atIndex: indexPath.section)
            }
        } else {
            switch sections()[indexPath.section] {
            case .info, .decryptKeySeparate:
                break
            case .expiryDate:
                switch expireDateRows()[indexPath.row] {
                case .activateExpiryDate, .pickExpiryDate:
                    break
                case .configureExpiryDate:
                    if getLinkVM.selectDate {
                        setExpiryDate()
                    }
                    getLinkVM.selectDate = !getLinkVM.selectDate
                    guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
                    tableView.reloadSections([expiryDateSection], with: .automatic)
                }
            case .passwordProtection:
                switch passwordProtectionRows()[indexPath.row] {
                case .configurePasword:
                    if justUpgradedToProAccount {
                        //Activity indicators are shown until the updated account details are received
                        return
                    }
                    
                    if MEGASdkManager.sharedMEGASdk().mnz_isProAccount {
                        present(SetLinkPasswordViewController.instantiate(withDelegate: self), animated: true, completion: nil)
                    } else {
                        showUpgradeToProCustomModalAlert()
                    }
                }
            case .link:
                switch linkRows()[indexPath.row] {
                case .link:
                    copyLinkToPasteboard(atIndex: nil)
                case .password:
                    copyPasswordToPasteboard()
                case .removePassword:
                    getLinkVM.passwordProtect = false
                    getLinkVM.password = nil
                    getLinkVM.link = nodes[0].publicLink ?? ""
                    tableView.reloadData()
                }
                break
            case .key:
                copyKeyToPasteBoard()
            }
        
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - MEGARequestDelegate

extension GetLinkViewController: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if request.type == .MEGARequestTypeAccountDetails {
            if error.type == .apiOk {
                if justUpgradedToProAccount {
                    //Reset temporal flag when the account details are received to allow using the PRO features
                    justUpgradedToProAccount = false
                    reloadProSections()
                    
                    removeDelegates()
                }
            }
        }
    }
}

//MARK: - SetLinkPasswordViewControllerDelegate

extension GetLinkViewController: SetLinkPasswordViewControllerDelegate {
    func setLinkPassword(_ setLinkPassword: SetLinkPasswordViewController, password: String) {
        setLinkPassword.dismissView()
        if let publicLink = nodes[0].publicLink {
            encrypt(link: publicLink, with: password)
        }
    }
    
    func setLinkPasswordCanceled(_ setLinkPassword: SetLinkPasswordViewController) {
        setLinkPassword.dismissView()
    }
}

//MARK: - MEGAPurchaseDelegate

extension GetLinkViewController: MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase!) {
        justUpgradedToProAccount = true
        reloadProSections()
    }
}

//MARK: - MEGARestoreDelegate

extension GetLinkViewController: MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase!) {
        justUpgradedToProAccount = true
        reloadProSections()
    }
}
