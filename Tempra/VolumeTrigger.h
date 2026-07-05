#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//detects hardware volume-button presses and fires pressBlock for each.
//uses an ambient audio session + outputVolume KVO; an offscreen
//MPVolumeView suppresses the system volume HUD and lets us reset the
//volume so presses keep registering at min/max.
@interface VolumeTrigger : NSObject

@property (nonatomic, copy) void (^pressBlock)(void);

-(instancetype)initWithView:(UIView*)view;
-(void)start;
-(void)stop;

@end
