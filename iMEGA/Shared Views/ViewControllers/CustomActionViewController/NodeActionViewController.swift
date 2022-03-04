import UIKit

@objc protocol NodeActionViewControllerDelegate {
    @objc optional func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) ->  ()
}

class NodeActionViewController: ActionSheetViewController {
    
    private var node: MEGANode
    private var displayMode: DisplayMode
    var delegate: NodeActionViewControllerDelegate
    var sender: Any
    private var viewMode: ViewModePreference?

    let nodeImageView = UIImageView.newAutoLayout()
    let titleLabel = UILabel.newAutoLayout()
    let subtitleLabel = UILabel.newAutoLayout()
    let downloadImageView = UIImageView.newAutoLayout()
    let separatorLineView = UIView.newAutoLayout()

    // MARK: - NodeActionViewController initializers

    convenience init?(
        node: MEGAHandle,
        delegate: NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        isIncoming: Bool = false,
        sender: Any) {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: node) else { return nil }
        self.init(node: node, delegate: delegate, displayMode: displayMode, isIncoming: isIncoming, sender: sender)
    }
    
    init?(
        nodeHandle: MEGAHandle,
        delegate: NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        sender: Any) {
        
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else { return nil }
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .build()
    }

    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, sender: Any) {
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isIncoming: isIncoming)
    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isInVersionsView: Bool, sender: Any) {
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isInVersionsView: isInVersionsView)
    }

    
    private func setupActions(node: MEGANode, displayMode: DisplayMode, isIncoming: Bool = false, isInVersionsView: Bool = false) {
        let isImageOrVideoFile = node.name?.mnz_isImagePathExtension == true || node.name?.mnz_isVideoPathExtension == true
        let isMediaFile = node.isFile() && isImageOrVideoFile && node.mnz_isPlayable()
        let isEditableTextFile = node.isFile() && node.name?.mnz_isEditableTextFilePathExtension == true
        self.actions = NodeActionBuilder()
            //mint设置
            .setMintLabel(node.label)
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .setIsMediaFile(isMediaFile)
            .setIsEditableTextFile(isEditableTextFile)
            .setIsFile(node.isFile())
            .setVersionCount(node.mnz_numberOfVersions())
            .setIsFavourite(node.isFavourite)
            .setLabel(node.label)
            .setIsRestorable(node.mnz_isRestorable())
            .setIsPdf(NSString(string: node.name ?? "").pathExtension.lowercased() == "pdf")
            .setisIncomingShareChildView(isIncoming)
            .setIsExported(node.isExported())
            .setIsOutshare(node.isOutShare())
            .setIsChildVersion(MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle)?.isFile())
            .setIsBackupFolder(node.isBackupNode() || node.isBackupRootNode())
            .setIsInVersionsView(isInVersionsView)
            .build()
    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, viewMode: ViewModePreference, sender: Any) {
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.viewMode = viewMode
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setViewMode(viewMode)
            .build()
    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, isLink: Bool = false, isPageView: Bool = true, displayMode: DisplayMode = .previewDocument, isInVersionsView: Bool = false, sender: Any) {
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(self.displayMode)
            .setIsPdf(NSString(string: node.name ?? "").pathExtension.lowercased() == "pdf")
            .setIsLink(isLink)
            .setIsPageView(isPageView)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .setIsRestorable(node.mnz_isRestorable())
            .setVersionCount(node.mnz_numberOfVersions())
            .setIsChildVersion(MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle)?.isFile())
            .setIsInVersionsView(isInVersionsView)
            .build()
    }
    
    @objc func addAction(_ action: BaseAction) {
        self.actions.append(action)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNodeHeaderView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        headerView?.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        titleLabel.textColor = UIColor.mnz_label()
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if node.isBackupRootNode() || node.isBackupNode(),
           let action = actions[indexPath.row] as? NodeAction,
           (action.type == .move || action.type == .moveToRubbishBin) {
            let cell: WarningActionSheetCell = tableView.dequeueReusableCell(withIdentifier:"ActionSheetCell") as? WarningActionSheetCell ?? WarningActionSheetCell(style: .value1, reuseIdentifier: "WarningActionSheetCell")
            cell.configureCell(action: action)

            return cell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: {
            self.delegate.nodeAction?(self, didSelect: action.type, for: self.node, from: self.sender)
        })
    }
    
    // MARK: - Private

    private func configureNodeHeaderView() {
        
        headerView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)

        headerView?.addSubview(nodeImageView)
        nodeImageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        nodeImageView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 8)
        nodeImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        nodeImageView.mnz_setThumbnail(by: node)

        headerView?.addSubview(titleLabel)
        titleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -10)
        titleLabel.text = node.name
        titleLabel.font = .preferredFont(style: .subheadline, weight: .medium)
        titleLabel.adjustsFontForContentSizeCategory = true
        
        headerView?.addSubview(subtitleLabel)
        subtitleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        
        if node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil {
            headerView?.addSubview(downloadImageView)
            downloadImageView.autoSetDimensions(to: CGSize(width: 12, height: 12))
            downloadImageView.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
            downloadImageView.autoPinEdge(.leading, to: .trailing, of: subtitleLabel, withOffset: 4)
            downloadImageView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 10, relation: .greaterThanOrEqual)
            downloadImageView.image = Asset.Images.Generic.downloaded.image
        } else {
            subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        }
        
        subtitleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        
        let sharedMEGASdk = displayMode == .folderLink || displayMode == .nodeInsideFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk()
        if node.isFile() {
            subtitleLabel.text = Helper.sizeAndModicationDate(for: node, api: sharedMEGASdk)
        } else {
            subtitleLabel.text = node.isBackupRootNode() ? node.numberOfDevices(sdk: sharedMEGASdk) : Helper.filesAndFolders(inFolderNode: node, api: sharedMEGASdk)
        }
    
        headerView?.addSubview(separatorLineView)
        separatorLineView.autoPinEdge(toSuperviewEdge: .leading)
        separatorLineView.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLineView.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLineView.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
        separatorLineView.backgroundColor = tableView.separatorColor
    }
}
