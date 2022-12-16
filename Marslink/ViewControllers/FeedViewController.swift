/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import IGListKit

class FeedViewController: UIViewController {
    
    let loader = JournalEntryLoader()
    let pathfinder = Pathfinder()
    let wxScanner = WxScanner()
    
//    updater is an object conforming to ListUpdatingDelegate, which handles row and section updates. ListAdapterUpdater is a default implementation that’s suitable for your usage
    
//    viewController is a UIViewController that houses the adapter. IGListKit uses this view controller later for navigating to other view controllers
    
//    workingRangeSize is the size of the working range, which allows you to prepare content for sections just outside of the visible frame
    
    lazy var adapter: ListAdapter = {
      return ListAdapter(
      updater: ListAdapterUpdater(),
      viewController: self,
      workingRangeSize: 0)
    }()

    
    // 1 GListKit uses a regular UICollectionView and adds its own functionality on top of it
    let collectionView: UICollectionView = {
      // 2 Start with a zero-sized rect, since the view isn’t created yet. It uses a UICollectionViewFlowLayout just as the ClassicFeedViewController did.
      let view = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout())
      // 3
      view.backgroundColor = .black
      return view
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        loader.loadLatest()
        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        pathfinder.delegate = self
        pathfinder.connect()
    }
    
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      collectionView.frame = view.bounds
    }

}

// MARK: - ListAdapterDataSource
extension FeedViewController: ListAdapterDataSource {
  
    // 1 objects(for:) returns an array of data objects that should show up in the collection view. You provide loader.entries here as it contains the journal entries.
  func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
      // 1
      var items: [ListDiffable] = [wxScanner.currentWeather]
      items += loader.entries as [ListDiffable]
      items += pathfinder.messages as [ListDiffable]
      
      
      // 2 All the data conforms to the DataSortable protocol, so this sorts the data using that protocol. This ensures data appears chronologically.
      return items.sorted { (left: Any, right: Any) -> Bool in
        guard let
          left = left as? DateSortable,
          let right = right as? DateSortable
          else {
            return false
        }
        return left.date > right.date
      }

  }
  
  // 2 For each data object, listAdapter(_:sectionControllerFor:) must return a new instance of a section controller. For now you’re returning a plain ListSectionController to appease the compiler. In a moment, you’ll modify this to return a custom journal section controller.
  func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any)
  -> ListSectionController {
    
      if object is Message {
        return MessageSectionController()
      } else if object is Weather {
        return WeatherSectionController()
      } else {
        return JournalSectionController()
      }
      
  }
  
  // 3 emptyView(for:) returns a view to display when the list is empty. NASA is in a bit of a time crunch, so they didn’t budget for this feature.
  func emptyView(for listAdapter: ListAdapter) -> UIView? {
    return nil
  }
}

// MARK: - PathfinderDelegate
extension FeedViewController: PathfinderDelegate {
    
//    FeedViewController now conforms to PathfinderDelegate. The single method performUpdates(animated:) tells the ListAdapter to ask its data source for new objects and then update the UI. This handles objects that are deleted, updated, moved or inserted.
  func pathfinderDidUpdateMessages(pathfinder: Pathfinder) {
    adapter.performUpdates(animated: true)
  }
}

