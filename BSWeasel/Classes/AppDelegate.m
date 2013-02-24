#import "AppDelegate.h"
#import "BSWeaselViewController.h"

@implementation AppDelegate

@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[self window] setRootViewController:[self viewController]];
  [[self window] makeKeyAndVisible];
  return YES;
}

- (void)dealloc
{
  [viewController release], viewController = nil;
  [super dealloc];
}

@end
