 //
 //  LTSimpleManager.swift
 //  LTScrollView
 //
 //  Created by 高刘通 on 2018/2/3.
 //  Copyright © 2018年 LT. All rights reserved.
 //
 
 import UIKit
 
 @objc public protocol LTSimpleScrollViewDelegate: class {
    @objc optional func glt_scrollViewDidScroll(_ scrollView: UIScrollView)
    @objc optional func glt_scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    @objc optional func glt_scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    @objc optional func glt_scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    @objc optional func glt_scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    @objc optional func glt_scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    //刷新tableView的代理方法
    @objc optional func glt_refreshScrollView(_ scrollView: UIScrollView, _ index: Int);
 }
 
 public class LTSimpleManager: UIView {
    
    /* headerView配置 */
    @objc public func configHeaderView(_ handle: (() -> UIView?)?) {
        guard let handle = handle else { return }
        guard let headerView = handle() else { return }
        kHeaderHeight = CGFloat(Int(headerView.bounds.height))
        if layout.isHovered == false {
            hoverY = 0.0
            kHeaderHeight += self.layout.sliderHeight
        }
        headerView.frame.size.height = kHeaderHeight
        self.headerView = headerView
        tableView.tableHeaderView = headerView
        DispatchQueue.main.after(0.001) {
            if self.layout.isHovered == false {
                self.titleView.frame.origin.y = self.kHeaderHeight - self.layout.sliderHeight
                headerView.addSubview(self.titleView)
            }
        }
    }
    
    /* 动态改变header的高度 */
    @objc public var glt_headerHeight: CGFloat = 0.0 {
        didSet {
            kHeaderHeight = CGFloat(Int(glt_headerHeight))
            if layout.isHovered == false {
                hoverY = 0.0
                kHeaderHeight += self.layout.sliderHeight
                titleView.frame.origin.y = kHeaderHeight - layout.sliderHeight
            }
            headerView?.frame.size.height = kHeaderHeight
            tableView.tableHeaderView = headerView
        }
    }
    
    public typealias LTSimpleDidSelectIndexHandle = (Int) -> Void
    @objc public var sampleDidSelectIndexHandle: LTSimpleDidSelectIndexHandle?
    @objc public func didSelectIndexHandle(_ handle: LTSimpleDidSelectIndexHandle?) {
        sampleDidSelectIndexHandle = handle
    }
    
    public typealias LTSimpleRefreshTableViewHandle = (UIScrollView, Int) -> Void
    @objc public var simpleRefreshTableViewHandle: LTSimpleRefreshTableViewHandle?
    @objc public func refreshTableViewHandle(_ handle: LTSimpleRefreshTableViewHandle?) {
        simpleRefreshTableViewHandle = handle
    }
    
    /* 代码设置滚动到第几个位置 */
    @objc public func scrollToIndex(index: Int)  {
        titleView.scrollToIndex(index: index)
    }
    
    /* 点击切换滚动过程动画  */
    @objc public var isClickScrollAnimation = false {
        didSet {
            titleView.isClickScrollAnimation = isClickScrollAnimation
        }
    }
    
    //设置悬停位置Y值
    @objc public var hoverY: CGFloat = 0
    
    /* LTSimple的scrollView上下滑动监听 */
    @objc public weak var delegate: LTSimpleScrollViewDelegate?
    
    private var contentTableView: UIScrollView?
    private var kHeaderHeight: CGFloat = 0.0
    private var headerView: UIView?
    private var viewControllers: [UIViewController]
    private var titles: [String]
    private var layout: LTLayout
    private weak var currentViewController: UIViewController?
    private var pageView: LTPageView!
    private var currentSelectIndex: Int = 0
    var isCustomTitleView: Bool = false
    
    private var titleView: LTPageTitleView!
    
    private lazy var tableView: LTTableView = {
        let tableView = LTTableView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height), style:.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        registerCell(tableView, UITableViewCell.self)
        return tableView
    }()
    
    @objc public init(frame: CGRect, viewControllers: [UIViewController], titles: [String], currentViewController:UIViewController, layout: LTLayout, titleView: LTPageTitleView? = nil) {
        UIScrollView.initializeOnce()
        self.viewControllers = viewControllers
        self.titles = titles
        self.currentViewController = currentViewController
        self.layout = layout
        super.init(frame: frame)
        layout.isSinglePageView = true
        if titleView != nil {
            isCustomTitleView = true
            self.titleView = titleView!
        }else {
            self.titleView = setupTitleView()
        }
        self.titleView.isCustomTitleView = isCustomTitleView
        self.titleView.delegate = self
        pageView = createPageViewConfig(currentViewController: currentViewController, layout: layout, titleView: titleView)
        createSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc public func scrollToTOP() -> () {
        for viewController in self.viewControllers {
            viewController.glt_scrollView?.contentOffset = .zero
        }
        UIView.animate(withDuration: 0.1, animations: {
            self.tableView.contentOffset = .zero
        })
    }
    
    
    deinit {
        deallocConfig()
    }
 }
 
 extension LTSimpleManager {
    private func setupTitleView() -> LTPageTitleView {
        let titleView = LTPageTitleView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: layout.sliderHeight), titles: titles, layout: layout)
        return titleView
    }
 }
 
 extension LTSimpleManager {
    
    private func createPageViewConfig(currentViewController:UIViewController, layout: LTLayout, titleView: LTPageTitleView?) -> LTPageView {
        let pageView = LTPageView(frame: self.bounds, currentViewController: currentViewController, viewControllers: viewControllers, titles: titles, layout:layout, titleView: titleView)
        if titles.count != 0 {
            pageView.glt_createViewController(0)
        }
        return pageView
    }
 }
 
 extension LTSimpleManager: LTPageViewDelegate {
    
    public func glt_scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        tableView.isScrollEnabled = false
    }
    
    public func glt_scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        tableView.isScrollEnabled = true
    }
    
 }
 
 extension LTSimpleManager {
    
    private func createSubViews() {
        backgroundColor = UIColor.white
        addSubview(tableView)
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        refreshData()
        pageViewDidSelectConfig()
        guard let viewController = viewControllers.first else { return }
        viewController.beginAppearanceTransition(true, animated: true)
        contentScrollViewScrollConfig(viewController)
        pageView.setupGetPageViewScrollView(pageView, titleView)
    }
    
    /*
     * 当滑动底部tableView的时候，当tableView的contentOffset.y 小于 header的高的时候，将内容ScrollView的contentOffset设置为.zero
     */
    private func contentScrollViewScrollConfig(_ viewController: UIViewController) {
        viewController.glt_scrollView?.scrollHandle = {[weak self] scrollView in
            guard let `self` = self else { return }
            self.contentTableView = scrollView
            if self.tableView.contentOffset.y  < self.kHeaderHeight - self.hoverY {
                scrollView.contentOffset = CGPoint(x: 0, y: 0)
                scrollView.showsVerticalScrollIndicator = false
            }else{
                scrollView.showsVerticalScrollIndicator = true
            }
        }
    }
    
 }
 
 extension LTSimpleManager {
    private func refreshData()  {
        DispatchQueue.main.after(0.001) {
            UIView.animate(withDuration: 0.34, animations: {
                self.tableView.contentInset = .zero
            })
            self.simpleRefreshTableViewHandle?(self.tableView, self.currentSelectIndex)
            self.delegate?.glt_refreshScrollView?(self.tableView, self.currentSelectIndex)
        }
        
    }
 }
 
 extension LTSimpleManager {
    private func pageViewDidSelectConfig()  {
        pageView.didSelectIndexBlock = {[weak self] in
            guard let `self` = self else { return }
            self.currentSelectIndex = $1
            self.refreshData()
            self.sampleDidSelectIndexHandle?($1)
        }
        pageView.addChildVcBlock = {[weak self] in
            guard let `self` = self else { return }
            self.contentScrollViewScrollConfig($1)
        }
        
    }
 }
 
 extension LTSimpleManager: UITableViewDelegate {
    
    /*
     * 当滑动内容ScrollView的时候， 当内容contentOffset.y 大于 0（说明滑动的是内容ScrollView） 或者 当底部tableview的contentOffset.y大于 header的高度的时候，将底部tableView的偏移量设置为kHeaderHeight， 并将其他的scrollView的contentOffset置为.zero
     */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.glt_scrollViewDidScroll?(scrollView)
        guard scrollView == tableView, let contentTableView = contentTableView else { return }
        let offsetY = scrollView.contentOffset.y
        if contentTableView.contentOffset.y > 0 || offsetY > kHeaderHeight - hoverY {
            tableView.contentOffset = CGPoint(x: 0.0, y: kHeaderHeight - hoverY  )
        }
        if scrollView.contentOffset.y < kHeaderHeight - hoverY  {
            for viewController in viewControllers {
                guard viewController.glt_scrollView != scrollView else { continue }
                viewController.glt_scrollView?.contentOffset = .zero
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.glt_scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.glt_scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.glt_scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.glt_scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.glt_scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
 }
 
 extension LTSimpleManager: UITableViewDataSource, LTTableViewProtocal {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cellWithTableView(tableView)
        cell.selectionStyle = .none
        if layout.isHovered {
            pageView.addSubview(titleView)
        }
        cell.contentView.addSubview(pageView)
        return cell
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height
    }
 }
 
 extension LTSimpleManager {
    private func deallocConfig() {
        for viewController in viewControllers {
            viewController.glt_scrollView?.delegate = nil
        }
    }
 }
 
 
 
