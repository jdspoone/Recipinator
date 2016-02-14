/*

  Written by Jeff Spooner

*/

import Foundation


class Observation: NSObject
  {

    let source: NSObject
    let keypaths: [String]
    let block: ([String : AnyObject]?) -> Void


    init(source: NSObject, keypaths: [String], options: NSKeyValueObservingOptions, block: ([String : AnyObject]?) -> Void)
      {
        self.source = source
        self.keypaths = keypaths
        self.block = block

        super.init()

        // Register to observe every given keypath
        for keypath in keypaths {
          source.addObserver(self, forKeyPath: keypath, options: options, context: nil)
        }
      }


    deinit
      {
        // Un-register to observe every keypath
        for keypath in keypaths {
          source.removeObserver(self, forKeyPath: keypath)
        }
      }


    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
      {
        self.block(change)
      }

  }
