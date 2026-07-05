#import "VolumeTrigger.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static void *VolumeTriggerContext = &VolumeTriggerContext;
#define RESTING_VOLUME 0.5f

@implementation VolumeTrigger
{
    MPVolumeView *volumeView;
    UISlider *volumeSlider;
    BOOL observing;
    BOOL resetting;
}

-(instancetype)initWithView:(UIView*)view{
    self=[super init];
    if(self){
        volumeView=[[MPVolumeView alloc] initWithFrame:CGRectMake(-2000, -2000, 1, 1)];
        volumeView.clipsToBounds=YES;
        [view addSubview:volumeView];
        volumeSlider=[self findSliderIn:volumeView];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(start)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stop)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
    return self;
}

//MPVolumeView's slider is private structure; fall back gracefully if absent
-(UISlider*)findSliderIn:(UIView*)view{
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[UISlider class]]) return (UISlider*)v;
        UISlider *s=[self findSliderIn:v];
        if(s) return s;
    }
    return nil;
}

-(void)start{
    if(observing) return;
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient
             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                   error:nil];
    [session setActive:YES error:nil];
    [session addObserver:self
              forKeyPath:@"outputVolume"
                 options:NSKeyValueObservingOptionNew
                 context:VolumeTriggerContext];
    observing=YES;
    [self resetVolume];
}

-(void)stop{
    if(!observing) return;
    [[AVAudioSession sharedInstance] removeObserver:self
                                         forKeyPath:@"outputVolume"
                                            context:VolumeTriggerContext];
    observing=NO;
}

-(void)resetVolume{
    if(volumeSlider==nil) return;//presses still fire except at min/max
    resetting=YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->volumeSlider.value=RESTING_VOLUME;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->resetting=NO;
        });
    });
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(context!=VolumeTriggerContext){
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(resetting) return;
    float newVolume=[change[NSKeyValueChangeNewKey] floatValue];
    if(fabsf(newVolume-RESTING_VOLUME)<0.001) return;//our own reset landing
    if(self.pressBlock) self.pressBlock();
    [self resetVolume];
}

-(void)dealloc{
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
