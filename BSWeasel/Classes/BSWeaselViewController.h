//
//  BSWeaselViewController.h
//  BSWeasel
//
//  Created by Benjamin Stockwell on 2/13/13.
//
//

#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"

@interface BSWeaselViewController : UIViewController {
    UIWindow *window;
}

@property (retain) CaptureSessionManager *captureManager;

@end
