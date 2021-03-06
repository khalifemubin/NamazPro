//  CustomCollectionViewLayout.swift
//  Source https://github.com/brightec/CustomCollectionViewLayout

import UIKit

class CustomCollectionViewLayout: UICollectionViewLayout {
    
    var itemAttributes: [[UICollectionViewLayoutAttributes]]? // 2D Array of Attributes
    var itemsSize : [CGSize]?
    var contentSize : CGSize!
    
    // MARK: - UICollectionViewLayout Override Functions
    override func prepare() {
        if self.collectionView?.numberOfSections == 0 {
            return
        }
        
        // This is the case where itemAttributes is already setup previously
        if (self.itemAttributes != nil && (self.itemAttributes?.count)! > 0) {
            // Loop through all sections (50 sections or rows)
            for section in 0..<self.collectionView!.numberOfSections {
                
                // number of items (8 items or columns)
                let numberOfItems : Int = self.collectionView!.numberOfItems(inSection: section)
                
                // Loop through all items
                for index in 0..<numberOfItems {
                    // If we're NOT in the first column AND NOT in first row, do nothing
                    // These are all the non-header cells (i.e. the content cells)
                    if section != 0 && index != 0 {
                        // https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/ControlFlow.html#//apple_ref/doc/uid/TP40014097-CH9-ID141
                        // The continue statement tells a loop to stop what it is doing and start again at the beginning of the next iteration through the loop.
                        continue
                    }
                    
                    if let attributes = self.layoutAttributesForItem(at: IndexPath(item: index, section: section)) {
                        // get the attributes for this particular cell
                        let attributes : UICollectionViewLayoutAttributes = attributes//self.layoutAttributesForItem(at: IndexPath(item: index, section: section))!
                        
                        if section == 0 {
                            // if the cell is a section header (row header) then offset its y (Idk why we do this)
                            // Will need to study the xOffset yOffset vars below
                            var frame = attributes.frame
                            frame.origin.y = self.collectionView!.contentOffset.y
                            attributes.frame = frame
                        }
                        
                        if index == 0 {
                            // if cell is a index header (column header) then offset its x (idk why)
                            // Will need to study the xOffset yOffset vars below
                            var frame = attributes.frame
                            frame.origin.x = self.collectionView!.contentOffset.x
                            attributes.frame = frame
                        }
                        
                    }
                    
                } // end of inner for-loop: for index in 0..<numberOfItems
            } // end of outer for-loop: for section in 0..<self.collectionView!.numberOfSections
            // all done
            return
        }
        
        // ** STARTING FROM SCRATCH **
        // If we got to this point then itemAttributes is nil
        // Starting here is where itemAttributes is setup from scratch.
        
        // ITEM SIZE: First check if itemSize is setup. If not, calculateItemSize
        if (self.itemsSize == nil || self.itemsSize?.count != self.collectionView!.numberOfItems(inSection: 1)) {
            // This calculateItemsSize is where the MAGIC happens..
            self.calculateItemsSize()
        }
        
        var column = 0
        // Note that both x and y offsets are driven by the width and height of var itemSize
        var xOffset : CGFloat = 0 // xOffset set's the cell's x position
        var yOffset : CGFloat = 0 // yOffset set's the cell's y position
        var contentWidth : CGFloat = 0
        var contentHeight : CGFloat = 0
        
        // (Double Loop) Loop through all of the sections (50 sections or rows in this case)
        for section in 0..<self.collectionView!.numberOfSections {
            // create a new sectionAttributes array
            var sectionAttributes: [UICollectionViewLayoutAttributes] = []
            
            // get the number of columns from the collectionView
            let numberOfColumns = self.collectionView!.numberOfItems(inSection: section)
            
            // (Inner Loop) Loop through all columns (8 columns in this case)
            for index in 0..<numberOfColumns {
                // Note that at this point, itemsSize should be set. See ITEM SIZE comment above.
                // Note that both x and y offsets are driven by the width and height of itemSize
                let itemSize = self.itemsSize![index]
                let indexPath = IndexPath(item: index, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height).integral
                
                if section == 0 && index == 0 {
                    // this sets the top-left cell to be on top of all others
                    attributes.zIndex = 1024;
                } else  if section == 0 || index == 0 {
                    // this sets the first row and first column to be just under the top-left cell so that it scrolls underneath
                    attributes.zIndex = 1023
                }
                
                if section == 0 {
                    // offset column headers
                    var frame = attributes.frame
                    frame.origin.y = self.collectionView!.contentOffset.y
                    attributes.frame = frame
                }
                if index == 0 {
                    // offset row headers
                    var frame = attributes.frame
                    frame.origin.x = self.collectionView!.contentOffset.x
                    attributes.frame = frame
                }
                
                // section attributes complete. add them to the array!
                sectionAttributes.append(attributes)
                
                xOffset += itemSize.width
                column += 1
                
                // This is a little curious...
                // Coder checks if column == numberOfColumns
                // The for loop looks like this: for index in 0..<numberOfColumns
                // So when index is at (numberOfColumns-1), column will be at (numberOfColumns)
                // Basically this triggers when index is at numCols-1, which is the very last loop
                // The var 'column' isn't used anywhere else except as a counter to trigger this if statement.
                // Why not just do this outside of the inner loop? Hmm..
                // TODO: probably need to fix this confusing 'column' var and if statement
                if column == numberOfColumns {
                    // if the current xOffset is greater than the contentWidth then set the width
                    if xOffset > contentWidth {
                        // contentWidth is used outside of this double for loop
                        contentWidth = xOffset
                    }
                    
                    column = 0
                    xOffset = 0
                    yOffset += itemSize.height
                } // end of if statement: if column == numberOfColumns
            } // end of inner for-loop: for index in 0..<numberOfColumns
            
            // if it's the first time calling prepare() then itemAttributes will be nil
            if (self.itemAttributes == nil) {
                self.itemAttributes = [[UICollectionViewLayoutAttributes]]()
            }
            // sectionAttributes (row attributes) complete. Add it to the itemAttributes global var!
            self.itemAttributes!.append(sectionAttributes)
        } // end of double for-loop: for section in 0..<self.collectionView!.numberOfSections
        
        // Calculate the final table width and height (contentWidth and contentHeight)
        if let attributes : UICollectionViewLayoutAttributes = self.itemAttributes?.last?.last {
            // Get the very last item attribute, which should be at the very bottom (or top?) and get its origin.
            // Its origin + the cell height will give us the table's height
            contentHeight = attributes.frame.origin.y + attributes.frame.size.height
            // contentWidth was already calculated within the double for-loop
            self.contentSize = CGSize(width: contentWidth, height: contentHeight)
        }
    }
    
    // This returns the size of the entire collection view
    override var collectionViewContentSize : CGSize {
        return self.contentSize
    }
    
    // This returns the itemAttributes for each cell. itemAttributes was set in the prepare() func
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        //if (self.itemAttributes?[indexPath.section].indices.contains(indexPath.row))!{
        if (self.itemAttributes?.indices.contains(indexPath.section))!{
            return self.itemAttributes?[indexPath.section][indexPath.row]
            
        }else{
            return nil
        }
    }
    
    // This returns only the attributes for the cells that exist in (or intersect) the rectangle parameter
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        if let itemAttributes = self.itemAttributes {
            for section in itemAttributes {
                let filteredArray = section.filter({ (evaluatedObject) -> Bool in
                    return rect.intersects(evaluatedObject.frame)
                })
                attributes.append(contentsOf: filteredArray)
            }
        }
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: - Helper Functions
    private func sizeForItemWithColumnIndex(_ columnIndex: Int) -> CGSize {
        var text : String = ""
        switch (columnIndex) {
        case 0:
            text = "2017-06-20"
        case 1:
            text = "2017-06-20"
        case 2:
            text = "2017-06-20"
        case 3:
            text = "2017-06-20"
        case 4:
            text = "2017-06-20"
        case 5:
            text = "2017-06-20"
        case 6:
            text = "2017-06-20"
        default:
            text = "2017-06-20"
        }
        
        let size : CGSize = (text as NSString).size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17.0)])
        let width : CGFloat = round(size.width)// + 25)
        return CGSize(width: width, height: 30)
    }
    
    private func calculateItemsSize() {
        // This is just the size for each column
        self.itemsSize = []
        for index in 0..<self.collectionView!.numberOfItems(inSection: 1) {
            self.itemsSize!.append(self.sizeForItemWithColumnIndex(index))
        }
    }
}
