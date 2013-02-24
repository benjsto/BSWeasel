#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"

@interface BSWeaselViewController : UIViewController {
    UIWindow *window;
}

//@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (retain) CaptureSessionManager *captureManager;
//@property (nonatomic, retain) UILabel *scanningLabel;
//@property (retain) NSMutableArray *images;

@end
