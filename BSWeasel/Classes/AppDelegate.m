#import "AppDelegate.h"
#import "BSWeaselViewController.h"

@implementation AppDelegate

//@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

  [[self window] setRootViewController:[self viewController]];
    //[[self viewController] setWindow:window];
  [[self window] makeKeyAndVisible];
  return YES;
}

- (void)dealloc
{
  //[window release], window = nil;
  [viewController release], viewController = nil;
  [super dealloc];
}

@end
