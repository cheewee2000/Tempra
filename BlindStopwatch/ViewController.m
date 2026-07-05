#import "ViewController.h"
//#import <AudioToolbox/AudioToolbox.h>
//#import <AVFoundation/AVFoundation.h>
//#import <MediaPlayer/MediaPlayer.h>
#define CGRectSetPos( r, x, y ) CGRectMake( x, y, r.size.width, r.size.height )
//#import "RBVolumeButtons.h"

//#include <assert.h>
//#include <mach/mach.h>
//#include <mach/mach_time.h>
//#include <unistd.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 480.0)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0)
#define IS_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0)

#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

#define NUMLEVELARROWS 5

#define TRIALSINSTAGE 5
#define NUMHEARTS 3
#define SHOWNEXTRASTAGES 3


@interface ViewController () {
    
}
@end

@implementation ViewController


//@synthesize screenLabel,indexNumber;

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
   [super viewDidLoad];
    
    trialSequence=-1;

    int vbuttonY=137;//5s
    if(IS_IPAD)vbuttonY=237;
    else if(IS_IPHONE_6)vbuttonY=145;
    else if(IS_IPHONE_6_PLUS)vbuttonY=155;
    else if(IS_IPHONE_5)vbuttonY=128;
    else if(IS_IPHONE_4)vbuttonY=95;

    screenHeight=self.view.frame.size.height;
    screenWidth=self.view.frame.size.width;

    
    aTimer = [MachTimer timer];

#pragma mark - instructions

    //instructions
    instructions=[[TextArrow alloc ] initWithFrame:CGRectMake(screenWidth, vbuttonY, screenWidth-8, 44)];
    [self.view addSubview:instructions];
    [self loadLevelProgress];

#pragma mark - Counter Labels

    labelContainer=[[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:labelContainer];
    [self.view bringSubviewToFront:instructions];
    
    int m=8;
    //set position relative to instruction arrow
    counterLabel=[[UILabel alloc]init];
    counterLabel.font = [UIFont fontWithName:@"DIN Condensed" size:screenWidth*.33];
    counterLabel.adjustsFontSizeToFitWidth = YES;
    counterLabel.textColor=[UIColor whiteColor];
    counterLabel.textAlignment=NSTextAlignmentCenter;
    counterLabel.frame=CGRectMake(0,0, screenWidth-m*2, screenWidth*.35);
    counterLabel.clipsToBounds=NO;
    [labelContainer addSubview:counterLabel];
    
    counterGoalLabel=[[UILabel alloc]init];
    counterGoalLabel.font = [UIFont fontWithName:@"DIN Condensed" size:screenWidth*.33];
    counterGoalLabel.adjustsFontSizeToFitWidth = YES;
    counterGoalLabel.textColor=[UIColor whiteColor];
    counterGoalLabel.textAlignment=NSTextAlignmentCenter;
    counterGoalLabel.frame=CGRectMake(0,0, screenWidth-m*2, screenWidth*.35);
    counterGoalLabel.clipsToBounds=NO;
    [self.view addSubview:counterGoalLabel];
    
    counterGoalLabel.center=CGPointMake(screenWidth*.5, instructions.frame.origin.y-counterLabel.frame.size.height*.30);
    counterLabel.center=CGPointMake(screenWidth*.5, instructions.frame.origin.y+instructions.frame.size.height+counterGoalLabel.frame.size.height*.50);


    goalPrecision=[[UILabel alloc] initWithFrame:CGRectMake(counterGoalLabel.frame.size.width*.5, -screenWidth*.05/2.0, counterGoalLabel.frame.size.width*.5-m, screenWidth*.05)];
    goalPrecision.font = [UIFont fontWithName:@"DIN Condensed" size:screenWidth*.05];
    goalPrecision.textAlignment=NSTextAlignmentRight;
    goalPrecision.textColor = [UIColor whiteColor];
    goalPrecision.text = @"";
    if(!IS_IPHONE_4 && !IS_IPAD)[counterGoalLabel addSubview:goalPrecision];
    
    
#pragma mark - Level Arrow
    levelArrows=[[NSMutableArray alloc] init];
    for (int i=0; i<NUMLEVELARROWS; i++) {
        TextArrow *arrow;
        if(i==0)arrow=[[TextArrow alloc ] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*.065)];
        else if(i==1)arrow=[[TextArrow alloc ] initWithFrame:CGRectMake(0,0, screenWidth, screenHeight*.065)];
        else if(i==2)arrow=[[TextArrow alloc ] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*.055)];
        else arrow=[[TextArrow alloc ] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*.045)];

        arrow.drawArrow=false;
        arrow.rightLabel.textColor=[UIColor blackColor];
        [levelArrows addObject:arrow];
        [self.view addSubview:arrow];
        [self.view sendSubviewToBack:arrow];
        [arrow slideDown:0];
    }
    
    levelAlert=[[TextArrow alloc ] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight*.125)];
    [levelAlert slideDown:0];
    levelAlert.drawArrow=false;
    [self.view addSubview:levelAlert];
    [self.view sendSubviewToBack:levelAlert];
    levelAlert.userInteractionEnabled=YES;

    nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * next=[UIImage imageNamed:@"next"];
    next = [next imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [nextButton setBackgroundImage:next forState:UIControlStateNormal];
    [nextButton adjustsImageWhenHighlighted];
    [nextButton setFrame:CGRectMake(0,0,levelAlert.frame.size.height*.85,levelAlert.frame.size.height*.85)];
    nextButton.center=CGPointMake( levelAlert.frame.size.width-nextButton.frame.size.width*.5-10,levelAlert.frame.size.height/2.0);
    [nextButton addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    nextButton.userInteractionEnabled=YES;
    [levelAlert addSubview:nextButton];
    
    shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * share=[UIImage imageNamed:@"share"];
    share = [share imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [shareButton setBackgroundImage:share forState:UIControlStateNormal];
    [shareButton adjustsImageWhenHighlighted];
    [shareButton setFrame:CGRectMake(0,0,levelAlert.frame.size.height*.85,levelAlert.frame.size.height*.85)];
    shareButton.center=CGPointMake(shareButton.frame.size.width*.5+10,levelAlert.frame.size.height/2.0);
    [shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    shareButton.userInteractionEnabled=YES;
    [levelAlert addSubview:shareButton];
    

#pragma mark - Persistent Variables

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"currentLevel"] == nil) currentLevel=0;
    else currentLevel = (int)[defaults integerForKey:@"currentLevel"];
    
    if([defaults objectForKey:@"best"] == nil) best=0;
    else best = (int)[defaults integerForKey:@"best"];
    
    if([defaults objectForKey:@"experiencepoints"] == nil) experiencePoints=0;
    else experiencePoints = (int)[defaults integerForKey:@"experiencepoints"];
    
    if([defaults objectForKey:@"starBank"] == nil) starBank=0;
    else starBank = (int)[defaults integerForKey:@"starBank"];
    
    if([defaults objectForKey:@"practicing"] == nil) practicing=false;
    else practicing = (int)[defaults integerForKey:@"practicing"];
    
    if([defaults objectForKey:@"showIntro"] == nil) showIntro=true;
    else showIntro = (int)[defaults integerForKey:@"showIntro"];
    
    if([defaults objectForKey:@"allTimeTotalTrials"] == nil) allTimeTotalTrials=0;
    else allTimeTotalTrials = (int)[defaults integerForKey:@"allTimeTotalTrials"];

    if([defaults objectForKey:@"currentStreak"] == nil) currentStreak=0;
    else currentStreak = (int)[defaults integerForKey:@"currentStreak"];

    //currentLevel=22;
    
    //[self loadData:currentLevel];
    
#pragma mark - Button Stealer
//    id progressDelegate = self;
//    self.buttonStealer = [[RBVolumeButtons alloc] init];
//    self.buttonStealer.upBlock = ^{
//        [progressDelegate buttonPressed];
//    };
//    self.buttonStealer.downBlock = ^{
//        [progressDelegate buttonPressed];
//    };
//    [self.buttonStealer startStealingVolumeButtonEvents];

    
#pragma mark - progressView

    //dot array for level progress
    progressView=[[LevelProgressView alloc] initWithFrame:CGRectMake(0, screenHeight, self.view.frame.size.width, self.view.frame.size.height*2.5)];
    progressView.clipsToBounds=YES;
    [self.view addSubview:progressView];
    progressView.backgroundColor=[self getForegroundColor:currentLevel];
    
    UIBlurEffect *blurEffect= [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    gameOverBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    gameOverBlur.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*2.5);
    gameOverBlur.alpha=0;
    [progressView addSubview:gameOverBlur];
    
    
    buttonYPos=screenHeight-66;
    
    trophyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * trophy=[UIImage imageNamed:@"trophy"];
    trophy = [trophy imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [trophyButton setBackgroundImage:trophy forState:UIControlStateNormal];
    [trophyButton adjustsImageWhenHighlighted];
    [trophyButton setFrame:CGRectMake(0,0,44,44)];
    trophyButton.center=CGPointMake(screenWidth/2.0, buttonYPos);
    [trophyButton addTarget:self action:@selector(showGlobalLeaderboard) forControlEvents:UIControlEventTouchUpInside];
    [progressView addSubview:trophyButton];
//    trophyButton.layer.shadowOpacity = progressView.shadowO;
//    trophyButton.layer.shadowRadius = progressView.shadowR;
//    trophyButton.layer.shadowColor = [UIColor blackColor].CGColor;
//    trophyButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    
    medalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * medal=[UIImage imageNamed:@"star"];
    medal = [medal imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [medalButton setBackgroundImage:medal forState:UIControlStateNormal];
    [medalButton adjustsImageWhenHighlighted];
    [medalButton setFrame:CGRectMake(0,0,44,44)];
    medalButton.center=CGPointMake(screenWidth*1.0/5.0, buttonYPos);
    [medalButton addTarget:self action:@selector(showSBLeaderboard) forControlEvents:UIControlEventTouchUpInside];
    [progressView addSubview:medalButton];
//    medalButton.layer.shadowOpacity = progressView.shadowO;
//    medalButton.layer.shadowRadius = progressView.shadowR;
//    medalButton.layer.shadowColor = [UIColor blackColor].CGColor;
//    medalButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    

    bestLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0,screenWidth,26)];
    bestLabel.center=CGPointMake(screenWidth*.5, trophyButton.frame.origin.y+trophyButton.frame.size.height+15);
    bestLabel.textAlignment=NSTextAlignmentCenter;
    bestLabel.font=[UIFont fontWithName:@"DIN Condensed" size:22.0];
    [progressView addSubview:bestLabel];
//    bestLabel.layer.shadowOpacity = progressView.shadowO;
//    bestLabel.layer.shadowRadius = progressView.shadowR;
//    bestLabel.layer.shadowColor = [UIColor blackColor].CGColor;
//    bestLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);

    
    highScoreLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0,screenWidth,26)];
    highScoreLabel.center=CGPointMake(screenWidth/5.0, medalButton.frame.origin.y+medalButton.frame.size.height+15);
    highScoreLabel.textAlignment=NSTextAlignmentCenter;
    highScoreLabel.font=[UIFont fontWithName:@"DIN Condensed" size:22.0];
    [progressView addSubview:highScoreLabel];
    [self updateHighscore];
//    highScoreLabel.layer.shadowOpacity = progressView.shadowO;
//    highScoreLabel.layer.shadowRadius = progressView.shadowR;
//    highScoreLabel.layer.shadowColor = [UIColor blackColor].CGColor;
//    highScoreLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    

    restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * restart=[UIImage imageNamed:@"restart"];
    restart = [restart imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [restartButton setBackgroundImage:restart forState:UIControlStateNormal];
    [restartButton adjustsImageWhenHighlighted];
    [restartButton setFrame:CGRectMake(0,0,44,44)];
    restartButton.center=CGPointMake(screenWidth*4/5.0, buttonYPos);
    [restartButton addTarget:self action:@selector(restart) forControlEvents:UIControlEventTouchUpInside];
    [progressView addSubview:restartButton];
//    restartButton.layer.shadowOpacity = progressView.shadowO;
//    restartButton.layer.shadowRadius = progressView.shadowR;
//    restartButton.layer.shadowColor = [UIColor blackColor].CGColor;
//    restartButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    
    
   restartExpandButton = [[BFPaperButton alloc] initWithFrame:CGRectMake(0, 0, 44,44) raised:NO];
    restartExpandButton.center=restartButton.center;
    [restartExpandButton addTarget:self action:@selector(restartButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    restartExpandButton.cornerRadius = restartExpandButton.frame.size.width / 2;
    restartExpandButton.tapCircleDiameter = screenHeight*2.05;
    restartExpandButton.rippleFromTapLocation=NO;
    restartExpandButton.rippleBeyondBounds=YES;
    restartExpandButton.usesSmartColor=NO;
    [progressView addSubview:restartExpandButton];
    
    
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * play=[UIImage imageNamed:@"next"];
    play = [play imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [playButton setBackgroundImage:play forState:UIControlStateNormal];
    [playButton adjustsImageWhenHighlighted];
    [playButton setFrame:CGRectMake(0,0,44,44)];
    [playButton addTarget:self action:@selector(restartFromLastStage) forControlEvents:UIControlEventTouchUpInside];
    [progressView addSubview:playButton];
    [progressView bringSubviewToFront:playButton];
    playButton.alpha=0;
//    playButton.layer.shadowOpacity = progressView.shadowO;
//    playButton.layer.shadowRadius = progressView.shadowR;
//    playButton.layer.shadowColor = [UIColor blackColor].CGColor;
//    playButton.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    

#pragma mark - Dots

    //Dots
    dots=[NSMutableArray array];
    stageLabels=[NSMutableArray array];

    bestLevelDot=[[Dots alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    bestLevelDot.backgroundColor = [UIColor clearColor];
    bestLevelDot.alpha=0;
    [progressView.dotsContainer addSubview:bestLevelDot];

    //[self updateDots];
    //[self updateTimeDisplay:0];
    
    
#pragma mark - Graphs

    ///*
    nPointsVisible=20;
    self.myGraph = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, screenHeight, screenWidth-22, screenHeight*.5-55)];
    self.myGraph.delegate = self;
    self.myGraph.dataSource = self;
    self.myGraph.colorTop =[UIColor clearColor];
    self.myGraph.colorBottom =[UIColor clearColor];
    self.myGraph.colorLine = [UIColor blackColor];
    self.myGraph.colorPoint=[UIColor clearColor];
    self.myGraph.widthLine = 2.0;
    self.myGraph.animationGraphStyle = BEMLineAnimationDraw;
    self.myGraph.enableTouchReport = YES;
    self.myGraph.enablePopUpReport = YES;
    self.myGraph.autoScaleYAxis = NO;
    self.myGraph.yAxisScale=100.0;
    if(IS_IPHONE_4)self.myGraph.yAxisScale=50.0;
    self.myGraph.animationGraphEntranceTime = .8;
    self.myGraph.tag=0;
    [progressView addSubview:self.myGraph];

    self.allGraph = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, screenHeight*1.5, screenWidth-22, screenHeight*.5-55)];
    self.allGraph.delegate = self;
    self.allGraph.dataSource = self;
    self.allGraph.colorTop =[UIColor clearColor];
    self.allGraph.colorBottom =[UIColor clearColor];
    self.allGraph.colorLine = [UIColor blackColor];
    self.allGraph.colorPoint=[UIColor clearColor];
    self.allGraph.widthLine = 2.0;
    self.allGraph.animationGraphStyle = BEMLineAnimationDraw;
    self.allGraph.enableTouchReport = YES;
    self.allGraph.enablePopUpReport = YES;
    self.allGraph.autoScaleYAxis = NO;
    self.allGraph.yAxisScale=100.0;
    if(IS_IPHONE_4)self.allGraph.yAxisScale=50.0;
    self.allGraph.animationGraphEntranceTime = .8;
    self.allGraph.tag=1;
    [progressView addSubview:self.allGraph];
    

#pragma mark - Stats

    
    //stats
    stats = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight*1.5-55, screenWidth, 55)];
     UIFont * LF=[UIFont fontWithName:@"DIN Condensed" size:34];
    int h=40;

    myGraphLabel=[[UILabel alloc] initWithFrame:CGRectMake(10, -34, 85, h)];
    myGraphLabel.font = [UIFont fontWithName:@"DIN Condensed" size:16];
    myGraphLabel.textAlignment=NSTextAlignmentLeft;
    myGraphLabel.text=@"STAGE 0";
    [stats addSubview:myGraphLabel];
    
    
    averageTime=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 85, h)];
    averageTime.center=CGPointMake(stats.frame.size.width*1/5.0, averageTime.center.y);
    averageTime.font = LF;
    averageTime.textAlignment=NSTextAlignmentCenter;
    [stats addSubview:averageTime];

    accuracy=[[UILabel alloc] initWithFrame:CGRectMake(stats.frame.size.width*.5, 0, 45, h)];
    accuracy.center=CGPointMake(stats.frame.size.width*4/5.0, accuracy.center.y);
    accuracy.font = LF;
    accuracy.textAlignment=NSTextAlignmentCenter;
    [stats addSubview:accuracy];

    precision=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 85, h)];
    precision.center=CGPointMake(stats.frame.size.width*2.5/5.0, precision.center.y);
    precision.font = LF;
    precision.textAlignment=NSTextAlignmentCenter;
    precision.adjustsFontSizeToFitWidth=YES;
    [stats addSubview:precision];

    
     //UNITS
    UIFont * SMF=[UIFont fontWithName:@"HelveticaNeue" size:10];
    precisionUnit=[[UILabel alloc] initWithFrame:CGRectMake(precision.frame.origin.x+precision.frame.size.width, -5, 80, 20)];
    precisionUnit.text=@"SEC";
    precisionUnit.font = SMF;
    [stats addSubview:precisionUnit];

    averageUnit=[[UILabel alloc] initWithFrame:CGRectMake(averageTime.frame.origin.x+averageTime.frame.size.width, -5, 80, 20)];
    averageUnit.text=@"SEC";
    averageUnit.font = SMF;
    [stats addSubview:averageUnit];
    
    accuracyUnit=[[UILabel alloc] initWithFrame:CGRectMake(accuracy.frame.origin.x+accuracy.frame.size.width, -5, 80, 20)];
    accuracyUnit.text=@"%";
    accuracyUnit.font = SMF;
    [stats addSubview:accuracyUnit];

    //LABELS
    float y=precision.frame.size.height-10;
    averageLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, stats.frame.size.width*.33-12, 20)];
    averageLabel.center=CGPointMake(stats.frame.size.width*1/5.0, averageLabel.center.y);
    averageLabel.text=@"AVERAGE";
    averageLabel.textAlignment=NSTextAlignmentCenter;
    averageLabel.font = SMF;
    [stats addSubview:averageLabel];

    accuracyLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, stats.frame.size.width*.33-12, 20)];
    accuracyLabel.center=CGPointMake(stats.frame.size.width*4/5.0, accuracyLabel.center.y);
    accuracyLabel.text=@"ACCURACY";
    accuracyLabel.textAlignment=NSTextAlignmentCenter;
    accuracyLabel.font = SMF;
    [stats addSubview:accuracyLabel];

    precisionLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, stats.frame.size.width*.33-12, 20)];
    precisionLabel.center=CGPointMake(stats.frame.size.width*2.5/5.0, precisionLabel.center.y);
    precisionLabel.text=@"PRECISION";
    precisionLabel.textAlignment=NSTextAlignmentCenter;
    precisionLabel.font = SMF;
    [stats addSubview:precisionLabel];

    [progressView addSubview:stats];
    
    
    //stats
    allStats = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight*2-55, screenWidth, 100)];
    
    allGraphLabel=[[UILabel alloc] initWithFrame:CGRectMake(10, -34, 85, h)];
    allGraphLabel.font = [UIFont fontWithName:@"DIN Condensed" size:16];
    allGraphLabel.textAlignment=NSTextAlignmentLeft;
    allGraphLabel.text=@"LAST 0 TRIALS";
    [allStats addSubview:allGraphLabel];
    
    
    allAverageTime=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 85, h)];
    allAverageTime.center=CGPointMake(allStats.frame.size.width*1/5.0, allAverageTime.center.y);
    allAverageTime.font = LF;
    allAverageTime.textAlignment=NSTextAlignmentCenter;
    [allStats addSubview:allAverageTime];
    
    allAccuracy=[[UILabel alloc] initWithFrame:CGRectMake(allStats.frame.size.width*.5, 0, 45, h)];
    allAccuracy.center=CGPointMake(allStats.frame.size.width*4/5.0, allAccuracy.center.y);
    allAccuracy.font = LF;
    allAccuracy.textAlignment=NSTextAlignmentCenter;
    [allStats addSubview:allAccuracy];
    
    allPrecision=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 85, h)];
    allPrecision.center=CGPointMake(allStats.frame.size.width*2.5/5.0, allPrecision.center.y);
    allPrecision.font = LF;
    allPrecision.textAlignment=NSTextAlignmentCenter;
    allPrecision.adjustsFontSizeToFitWidth=YES;
    [allStats addSubview:allPrecision];
    
    
    //UNITS
    allPrecisionUnit=[[UILabel alloc] initWithFrame:CGRectMake(allPrecision.frame.origin.x+allPrecision.frame.size.width, -5, 80, 20)];
    allPrecisionUnit.text=@"SEC";
    allPrecisionUnit.font = SMF;
    [allStats addSubview:allPrecisionUnit];
    
    allAverageUnit=[[UILabel alloc] initWithFrame:CGRectMake(allAverageTime.frame.origin.x+allAverageTime.frame.size.width, -5, 80, 20)];
    allAverageUnit.text=@"SEC";
    allAverageUnit.font = SMF;
    [allStats addSubview:allAverageUnit];
    
    allAccuracyUnit=[[UILabel alloc] initWithFrame:CGRectMake(allAccuracy.frame.origin.x+allAccuracy.frame.size.width, -5, 80, 20)];
    allAccuracyUnit.text=@"%";
    allAccuracyUnit.font = SMF;
    [allStats addSubview:allAccuracyUnit];
    
    //LABELS
    y=allPrecision.frame.size.height-10;
    allAverageLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, allStats.frame.size.width*.33-12, 20)];
    allAverageLabel.center=CGPointMake(allStats.frame.size.width*1/5.0, allAverageLabel.center.y);
    allAverageLabel.text=@"AVERAGE";
    allAverageLabel.textAlignment=NSTextAlignmentCenter;
    allAverageLabel.font = SMF;
    [allStats addSubview:allAverageLabel];
    
    allAccuracyLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, allStats.frame.size.width*.33-12, 20)];
    allAccuracyLabel.center=CGPointMake(allStats.frame.size.width*4/5.0, allAccuracyLabel.center.y);
    allAccuracyLabel.text=@"ACCURACY";
    allAccuracyLabel.textAlignment=NSTextAlignmentCenter;
    allAccuracyLabel.font = SMF;
    [allStats addSubview:allAccuracyLabel];
    
    allPrecisionLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, y, allStats.frame.size.width*.33-12, 20)];
    allPrecisionLabel.center=CGPointMake(allStats.frame.size.width*2.5/5.0, allPrecisionLabel.center.y);
    allPrecisionLabel.text=@"PRECISION";
    allPrecisionLabel.textAlignment=NSTextAlignmentCenter;
    allPrecisionLabel.font = SMF;
    [allStats addSubview:allPrecisionLabel];
    
    [progressView addSubview:allStats];
    
    questionMark=[[UILabel alloc] initWithFrame:CGRectMake(0, allStats.frame.origin.y+allStats.frame.size.height, screenWidth, screenHeight*.4)];
    questionMark.text=@"?";
    questionMark.font = [UIFont fontWithName:@"DIN Condensed" size:screenHeight*.35];
    questionMark.textAlignment=NSTextAlignmentCenter;
    
    [progressView addSubview:questionMark];
    
    
#pragma mark - life

    //life hearsts
    if([defaults objectForKey:@"life"] == nil) life=NUMHEARTS;
    else life = (int)[defaults integerForKey:@"life"];
    hearts=[[NSMutableArray alloc]init];

    
#pragma mark - blob
    //big dot
    
//    blob=[[UIView alloc] init];
//    [self.view addSubview:blob];
//    
//    //set blob frame
//    blob.frame=self.view.frame;
//    [self resetMainDot];
    
//    mainDot = [[Dots alloc] init];
//    mainDot.alpha = 1;
//    mainDot.backgroundColor = [UIColor clearColor];
//    [mainDot setFill:YES];
//    [mainDot setClipsToBounds:NO];
//    [self resetMainDot];
    //[blob addSubview:mainDot];
    
    
    //satellites
//    satellites=[NSArray array];
//    for (int i=0;i<10;i++){
//        Dots *sat = [[Dots alloc] init];
//        sat.alpha = 1;
//        sat.backgroundColor = [UIColor clearColor];
//        [sat setFill:YES];
//        [sat setClipsToBounds:NO];
//        satellites = [satellites arrayByAddingObject:sat];
//        [blob addSubview:satellites[i]];
//    }
//[self setupSatellites];
    
    
//    UIBlurEffect *blurEffect= [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    blobBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//    blobBlur.frame = self.view.bounds;
//    blobBlur.alpha=1;
//    [blob addSubview:blobBlur];

    
#pragma mark - XO

    
    xView=[[UIImageView alloc] init];
    [xView setImage:[[UIImage imageNamed: @"x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.view addSubview:xView];
    [self.view bringSubviewToFront:xView];
    xView.userInteractionEnabled=NO;
    xView.alpha=0;

    oView=[[UIImageView alloc] init];
    [oView setImage:[[UIImage imageNamed: @"o"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.view addSubview:oView];
    [self.view bringSubviewToFront:oView];
    oView.alpha=0;
    oView.userInteractionEnabled=NO;
    [self xoViewOffScreen];

    
    [self.view sendSubviewToBack:progressView];
    [self.view sendSubviewToBack:blob];

    //game center
    [self authenticateLocalPlayer];
    
    if(life<=0)[self restart];
    
#pragma mark - intro
    intro=[[UIView alloc] initWithFrame:self.view.frame];
    intro.backgroundColor=[self getBackgroundColor:0];
    [self.view addSubview:intro];
    
    m=15;
    int w=screenWidth-m*2.0;
    //instructions
    introArrow=[[TextArrow alloc ] initWithFrame:CGRectMake(screenWidth, vbuttonY, screenWidth-8, 44)];
    introArrow.instructionText.textColor=intro.backgroundColor;
    introArrow.rightLabel.textColor=intro.backgroundColor;
    [introArrow update:@"OK LET'S GO!" rightLabel:@"" color:[self getForegroundColor:0] animate:NO];
    [introArrow slideOut:0];
    [intro addSubview:introArrow];

    
    introTitle=[[UILabel alloc] initWithFrame:CGRectMake(m, introArrow.frame.origin.y-screenWidth*.22, w, screenWidth*.20)];
    introTitle.font = [UIFont fontWithName:@"DIN Condensed" size:screenWidth*.22];
    introTitle.adjustsFontSizeToFitWidth=YES;
    introTitle.text=@"THIS IS TEMPRA";
    introTitle.textColor=[self getForegroundColor:0];
    [intro addSubview:introTitle];

    
    introSubtitle=[[UILabel alloc] initWithFrame:CGRectMake(m, introArrow.frame.origin.y+introArrow.frame.size.height+15, w, 90)];
    introSubtitle.font = [UIFont fontWithName:@"DIN Condensed" size:32];
    introSubtitle.numberOfLines=3;
    introSubtitle.text=@"TEST AND INCREASE YOUR TIME PERCEPTION";
    introSubtitle.textColor=[self getForegroundColor:0];
    [intro addSubview:introSubtitle];
    
    
    introParagraph=[[UILabel alloc] initWithFrame:CGRectMake(m, introSubtitle.frame.origin.y+introSubtitle.frame.size.height+10, w, 200)];
    introParagraph.font = [UIFont fontWithName:@"DIN Condensed" size:20];
    introParagraph.numberOfLines=14;
    introParagraph.textAlignment=NSTextAlignmentJustified;
    introParagraph.text=@"For each trial, your goal is to get as close as possible to the displayed target time. Tap the screen or press the volume button to start the counter, then press stop when you think the right amount of time has elapsed. \n\nBreathe... relax, and focus on your internal sense of time.\n\nThis app periodically collects anonymous statistics for us to study and potentially reveal how humans produce time internally.";
    introParagraph.textColor=[self getForegroundColor:0];
    [intro addSubview:introParagraph];
    
    credits=[[UILabel alloc] initWithFrame:CGRectMake(m, screenHeight-55, w, 40)];
    credits.font = [UIFont fontWithName:@"HelveticaNeue" size:9];
    credits.numberOfLines=3;
    credits.textAlignment=NSTextAlignmentCenter;
    credits.text=@"TEMPRA, 2014\nDesigned and built by Che-Wei Wang\nMIT Media Lab, Playful Systems";
    credits.textColor=[self getForegroundColor:0];
    [intro addSubview:credits];
    
    intro.alpha=0;
    
//    UITapGestureRecognizer *tapGestureRecognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPressed)];
//    tapGestureRecognizer3.numberOfTouchesRequired = 1;
//    tapGestureRecognizer3.numberOfTapsRequired = 1;
//    [self.view addGestureRecognizer:tapGestureRecognizer3];
//    self.view.userInteractionEnabled=YES;
    
    //currentLevel=11;
}


#pragma mark - restart

-(void)restartButtonPressed{
    
    if(!restartExpandButton.growthFinished)return;
    [self restart];
}

-(void) restart{
    
    //set life asap so countdown timer stops
    life=NUMHEARTS;

    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         progressView.centerMessage.alpha=0;
                         progressView.subMessage.alpha=0;
                         progressView.lowerMessage.alpha=0;
                         playButton.alpha=0.0;
                         gameOverBlur.alpha=0;

                         
                     }
                     completion:^(BOOL finished){
                     }];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         restartButton.center=CGPointMake(screenWidth*4/5.0, buttonYPos);
                     }
                     completion:^(BOOL finished){
                     }];
    

    
    
    for (int i=0; i<dots.count; i++){
        Dots* d=[dots objectAtIndex:i];
        
        [UIView animateWithDuration:0.6
                              delay:(arc4random()%1000)*.001
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             d.frame=CGRectOffset(d.frame, 0, screenHeight*1.5);
                         }
                         completion:^(BOOL finished){
                             
                         }];
    }
    
    for (int i=0; i<stageLabels.count; i++){
        TextArrow* sl=[stageLabels objectAtIndex:i];
        
        [UIView animateWithDuration:0.6
                              delay:(arc4random()%1000)*.001
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             sl.frame=CGRectOffset(sl.frame, 0, screenHeight*1.5);
                         }
                         completion:^(BOOL finished){
                             
                         }];
    }
    
    [UIView animateWithDuration:.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         bestLevelDot.frame=CGRectOffset(bestLevelDot.frame, 0, screenHeight*1.5);
                     }
                     completion:^(BOOL finished){
                         
                     }];

    
    
    
    [self performSelector:@selector(setupGame) withObject:self afterDelay:1.5];

}

-(void)setupGame{
    [self removeDots];
    
    currentLevel=0;
    trialSequence=-1;
    progressView.centerMessage.text=@"";
    progressView.subMessage.text=@"";
    practicing=false;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:practicing forKey:@"practicing"];
    [defaults synchronize];

    //setup new dots
    life=NUMHEARTS;
    
    [self clearTrialData];

    [self setupDots];
    [self updateLife];
    
}

-(void) restartFromLastStage{
    
    [UIView animateWithDuration:0.8
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         progressView.centerMessage.alpha=0;
                         progressView.subMessage.alpha=0;
                         progressView.lowerMessage.alpha=0;
                         playButton.alpha=0.0;
                         gameOverBlur.alpha=0;

                     }
                     completion:^(BOOL finished){
                     }];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         restartButton.center=CGPointMake(screenWidth*4/5.0, buttonYPos);
                     }
                     completion:^(BOOL finished){
                     }];
    

    [self removeDots];

    //experiencePoints-=lastStage*10.0;
    starBank-=lastStage;
    
    
    life=NUMHEARTS;
    currentLevel=lastStage*TRIALSINSTAGE;
    trialSequence=-1;
    progressView.centerMessage.text=@"";
    progressView.subMessage.text=@"";
    //practicing=true;
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //[defaults setInteger:practicing forKey:@"practicing"];
    //[defaults synchronize];
    
    //setup new dots
    [self setupDots];
    [self updateLife];

}

-(void)addHeart:(int)i{
    UIImageView * heart=[[UIImageView alloc] init];
    [heart setImage:[[UIImage imageNamed: @"heart"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    heart.alpha=0.0;
    heart.frame=CGRectMake(16+(screenWidth-16)/10.0*(i%10), screenHeight+100,15,15);
    [hearts addObject:heart];
    [labelContainer addSubview:hearts[i]];
    [labelContainer sendSubviewToBack:hearts[i]];
}
-(void)updateHighscore{
    if(best>0) bestLabel.text=[NSString stringWithFormat:@"BEST %.01f",best];
//    if(experiencePoints>0) {
//        if (experiencePoints<10000) highScoreLabel.text=[NSString stringWithFormat:@"$%.02f",experiencePoints];
//        else highScoreLabel.text=[NSString stringWithFormat:@"%i",(int)experiencePoints];
//    }
    
    if(starBank>0) {
     highScoreLabel.text=[NSString stringWithFormat:@"%i",starBank];
    }
    
}

-(int)getCurrentStage{
    return floorf(currentLevel/TRIALSINSTAGE);
}

-(void)removeDots{
    
    for (int i = 0; i < [dots count];i++){
        
        Dots *d=[dots objectAtIndex:i ];
        [d setFill:NO];
        [d setText:@"" level:@""];
        [d setStars:0];
        [d removeFromSuperview];
        
        
        //remove stagelabels
        if(i%TRIALSINSTAGE==0){
            int stage=floorf(i/TRIALSINSTAGE);
            TextArrow *sLabel=[stageLabels objectAtIndex:stage];
            sLabel.alpha=0;
            [sLabel removeFromSuperview];
        }
    }
    bestLevelDot.alpha=0;
    [dots removeAllObjects];
    [stageLabels removeAllObjects];
}

-(void)setupDots{
    int rowHeight=55;

    [self.view bringSubviewToFront:progressView];
    float d=.5;
    if(progressView.frame.origin.y==0)d=0.0;//progressview is already showing. don't animate

    [UIView animateWithDuration:.4
                          delay:d
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         if(currentLevel==0)progressView.frame=CGRectMake(0, -screenHeight, screenWidth, progressView.frame.size.height);
                         else progressView.frame=CGRectMake(0, -screenHeight*.5, screenWidth, progressView.frame.size.height);
                         progressView.dotsContainer.frame=CGRectMake(0, 22, screenWidth, progressView.dotsContainer.frame.size.height);
                     }
                    completion:^(BOOL finished){
                        float d=1.0;

                        //so graph animation doesn't repeat
                        if(viewLoaded){
                            [self.myGraph reloadGraph];
                            [self.allGraph reloadGraph];
                            d=1.5;//wait for graph to finish loading
                        }
                        
                        viewLoaded=true;
                        
                        
                        [UIView animateWithDuration:.4
                                              delay:d
                             usingSpringWithDamping:.8
                              initialSpringVelocity:1.0
                                            options:UIViewAnimationOptionCurveLinear
                                         animations:^{
                                             progressView.frame=CGRectMake(0, 0, screenWidth, progressView.frame.size.height);
                                             progressView.dotsContainer.frame=CGRectMake(0, 22, screenWidth, progressView.dotsContainer.frame.size.height);
                                             
                                         }
                                         completion:^(BOOL finished){

                                             int nDotsToShow=TRIALSINSTAGE+[self getCurrentStage]*TRIALSINSTAGE;

                                             if(nDotsToShow<TRIALSINSTAGE*SHOWNEXTRASTAGES)nDotsToShow=TRIALSINSTAGE*SHOWNEXTRASTAGES;

                                             for (int i = 0; i < nDotsToShow; i++){
                                            float dotDia=15;
                                            float margin=screenWidth/TRIALSINSTAGE/2.0+dotDia+40;
                                            float y=15-rowHeight*floor(i/TRIALSINSTAGE)+rowHeight*floor(nDotsToShow/TRIALSINSTAGE-1);

                                            //update existing dots
                                            if(i<[dots count]){
                                                
                                                Dots *dot=[dots objectAtIndex:i];
                                                [self updateDot:i];
                                                
                                                //shift dots down
                                                [UIView animateWithDuration:.4
                                                                      delay:0.4
                                                     usingSpringWithDamping:.5
                                                      initialSpringVelocity:1.0
                                                                    options:UIViewAnimationOptionCurveLinear
                                                                 animations:^{
                                                                     dot.frame=CGRectMake(margin+(screenWidth-margin)/TRIALSINSTAGE*(i%TRIALSINSTAGE),y,dotDia,dotDia);
                                                                 }
                                                                 completion:^(BOOL finished){
                                                                     
                                                                 }];
                  

                                                
                                                //update stage label
                                                if(i%TRIALSINSTAGE==0){
                                                    int stage=floorf(i/TRIALSINSTAGE);
                                                    TextArrow *sLabel=[stageLabels objectAtIndex:stage];
                                                    sLabel.alpha=1;
                                                    
                                                    //shift label down
                                                    [UIView animateWithDuration:.4
                                                                          delay:0.4
                                                         usingSpringWithDamping:.5
                                                          initialSpringVelocity:1.0
                                                                        options:UIViewAnimationOptionCurveLinear
                                                                     animations:^{
                                                                         sLabel.frame=CGRectMake(0, y, 70, 15);
                                                                     }
                                                                     completion:^(BOOL finished){
                                                                     }];
                                                }


                                            }
                                            //add new stagelabel
                                            else{

                                                if(i%TRIALSINSTAGE==0){
                                                    int stage=floorf(i/TRIALSINSTAGE);

                                                    //add stage label
                                                    TextArrow *sLabel = [[TextArrow alloc] initWithFrame:CGRectMake(0, -60, 70, 16)];
                                                    sLabel.instructionText.textColor = [UIColor blackColor];
                                                    sLabel.drawArrowRight=true;
                                                    sLabel.alpha=1;

                                                    [stageLabels addObject:sLabel];
                                                    [progressView.dotsContainer addSubview:sLabel];
                                                    
                                                    //color isn't really set here
                                                    CGFloat hue, saturation, brightness, alpha ;
                                                    [[self getBackgroundColor:currentLevel] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                                                    if(y>=screenHeight*.5) alpha=fabs(screenHeight-y-88)/(float)(screenHeight*.1);
                                                    else alpha=1.0;
                                                    UIColor * sColor= [ UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
                                                    
                                                    [sLabel update:[NSString stringWithFormat:@"STAGE %i",stage+1] rightLabel:@"" color:sColor animate:NO];
                                                    sLabel.instructionText.textColor=[self getForegroundColor:currentLevel];

                                                    [UIView animateWithDuration:.4
                                                                          delay:0.4+stage*.1
                                                         usingSpringWithDamping:.5
                                                          initialSpringVelocity:1.0
                                                                        options:UIViewAnimationOptionCurveLinear
                                                                     animations:^{
                                                                         sLabel.frame=CGRectMake(0, y, 70, 15);
                                                                     }
                                                                     completion:^(BOOL finished){
                                                                     }];
                                                    
                                                }
                                                
                                                //add dot
                                                Dots *dot = [[Dots alloc] initWithFrame:CGRectMake(margin+(screenWidth-margin)/TRIALSINSTAGE*(i%TRIALSINSTAGE),y,dotDia,dotDia)];
                                                dot.alpha = 1;
                                                dot.backgroundColor = [UIColor clearColor];
                                                
                                                CGFloat hue, saturation, brightness, alpha ;
                                                [[self getBackgroundColor:currentLevel] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                                                if(y>=screenHeight*.5) alpha=fabs(screenHeight-y-88)/(float)(screenHeight*.5);
                                                

                                                UIColor * sColor= [ UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
                                                
                                                [dot setColor:sColor];
                                                
                                                [dots addObject:dot];
                                                [progressView.dotsContainer addSubview:dots[i]];
                                                
                                                dot.transform = CGAffineTransformScale(CGAffineTransformIdentity, .001, .001);
                                                //add level label
                                                [self updateDot:i];
                    

                                            //animate dot appearance
                                            [UIView animateWithDuration:.2
                                                                  delay:.4+(i-currentLevel)*.05
                                                 usingSpringWithDamping:.5
                                                  initialSpringVelocity:1.0
                                                                options:UIViewAnimationOptionCurveLinear
                                                             animations:^{
                                                                 dot.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);

                                                             }
                                                             completion:^(BOOL finished){
                                                  }];
                                            }
                                        }
                                             
                                int stage=floorf(currentLevel/TRIALSINSTAGE);
                                if(stage<SHOWNEXTRASTAGES) [self performSelector:@selector(loadLevel) withObject:self afterDelay:0.4];
                                else [self performSelector:@selector(loadLevel) withObject:self afterDelay:1.0];
                        }];
            }];
}

-(void)updateDotColors{
    
    CGFloat hue, saturation, brightness, alpha ;
    [[self getBackgroundColor:currentLevel] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    for (int i=0; i<[dots count]; i++){
        Dots *dot=[dots objectAtIndex:i];
        //if(dot.frame.origin.y>=screenHeight*.25){
            alpha=(float)(screenHeight-dot.frame.origin.y+88)/(float)(screenHeight);
        //}
        //else alpha=1.0;
        UIColor * sColor= [ UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];

        [UIView animateWithDuration:.4
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             dot.color=sColor;
                             [dot setNeedsDisplay];
                         }
                         completion:^(BOOL finished){
                         }];
        
        if(i%TRIALSINSTAGE==0){
            int stage=floorf(i/TRIALSINSTAGE);
            TextArrow *sLabel=[stageLabels objectAtIndex:stage];
            sLabel.alpha=1;

            CGFloat hue, saturation, brightness, alpha ;
            [[self getBackgroundColor:currentLevel] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
            //if(sLabel.frame.origin.y>=screenHeight*.5)
                alpha=(screenHeight-sLabel.frame.origin.y)/(float)(screenHeight);
            //else alpha=1.0;
            UIColor * sColor= [ UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
            
            
            [UIView animateWithDuration:.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 [sLabel setColor:sColor];
                                 sLabel.instructionText.textColor=[self getForegroundColor:currentLevel];
                                 [sLabel setNeedsDisplay];
                                 
                             }
                             completion:^(BOOL finished){
                                 
                             }];
        }
        
        
    }
    
    [UIView animateWithDuration:.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [bestLevelDot setColor:[self getBackgroundColor:currentLevel]];
                         [bestLevelDot setNeedsDisplay];
                     }
                     completion:^(BOOL finished){
                         
                     }];



}

-(void) updateDot:(int)i{
    
    Dots *dot=[dots objectAtIndex:i];

    //goal String
    NSTimeInterval level=[self getLevel:i];
    NSDate* nDate = [NSDate dateWithTimeIntervalSince1970: level];
    NSDateFormatter* ngf = [[NSDateFormatter alloc] init];
    if(level<60)[ngf setDateFormat:@"s.S"];
    else [ngf setDateFormat:@"mm:ss.S"];
    NSString* nGoalString = [ngf stringFromDate:nDate];
    
    [dot setText:@"" level:nGoalString];
    
    if(i<currentLevel){
        [dot setFill:YES];
        if(i<[self.levelData count]){
            float trialAccuracy=fabs([[[self.levelData objectAtIndex:i] objectForKey:@"accuracy"] floatValue]);
            //float trialGoal=fabs([[[self.ArrayOfValues objectAtIndex:i] objectForKey:@"goal"] floatValue]);
            //float accuracyPercent=100.0-trialAccuracy/trialGoal*100.0;
            int nStarsEarned=0;
            
            if(trialAccuracy<=[self getLevelAccuracy:i]*1.0/5.0)nStarsEarned=3;
            else if(trialAccuracy<=[self getLevelAccuracy:i]*2.0/5.0) nStarsEarned=2;
            else if(trialAccuracy<=[self getLevelAccuracy:i]*3.0/5.0)nStarsEarned=1;
            
            [dot setStars:nStarsEarned];
            

            
        }
    }
    else {
        [dot setFill:NO];
    }
    


    
    
   
}

-(void) updateBestDot{
    
    for (int i=0; i<[dots count]; i++){
        
        if([self getLevel:i]==best){
            Dots *dot=[dots objectAtIndex:i];
            
            [bestLevelDot setFill:NO];
            [bestLevelDot setColor:dot.dotColor];
            bestLevelDot.center=dot.center;
            [UIView animateWithDuration:.4
                                  delay:0
                 usingSpringWithDamping:.5
                  initialSpringVelocity:1.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 bestLevelDot.alpha=1.0;
                             }
                             completion:^(BOOL finished){
                                 
                             }];
        }
    }

    
}
-(void) updateDots{
    for (int i=0; i<[dots count]; i++){
        [self updateDot:i];
    }
    //hide xo view`
    [UIView animateWithDuration:.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         xView.alpha=0.0;
                         oView.alpha=0.0;
                     }
                     completion:^(BOOL finished){
                     }];
}



-(void) updateLife{
    //add hearts to be the same as life
    if([hearts count]<life){
        for(int i=(int)[hearts count]; i<life; i++) [self addHeart:i];
    }
    
    for (int i=0;i<[hearts count];i++){

        UIImageView* heart=[hearts objectAtIndex:i];
        
        if(i<life) {
            [self.view bringSubviewToFront:heart];
            
            //update color
            [UIView animateWithDuration:.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 heart.tintColor=counterGoalLabel.textColor;
                                 if(life>10) heart.alpha=.7;
                                 else heart.alpha=1;
                             }
                             completion:^(BOOL finished){
                             }];

        
            if(heart.frame.origin.y>screenHeight){
                if(life>10) heart.alpha=.7;
                else heart.alpha=1;
                //heart.transform = CGAffineTransformScale(CGAffineTransformIdentity, .01, .01);

                    //heart in
                [UIView animateWithDuration:.6
                                      delay:0.1 * i
                     usingSpringWithDamping:0.5
                      initialSpringVelocity:1.0
                                    options:UIViewAnimationOptionCurveLinear
                                         animations:^{
                                             heart.frame=CGRectMake(16+(screenWidth-16)/10.0*(i%10)+floor(i/10.0)*2, screenHeight-70-floor(i/10.0)*2,15,15);
                                             //heart.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
                                         }
                                         completion:^(BOOL finished){
                                         }];
            }
        }
        else{
            //drop heart
            
            //[self.view sendSubviewToBack:heart];
            //[self.view sendSubviewToBack:blob];
            [self.view bringSubviewToFront:progressView];
            
            [UIView animateWithDuration:.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 heart.frame=CGRectOffset(heart.frame, 0, 100);
                             }
                             completion:^(BOOL finished){
                                 
                             }];
        }
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:life forKey:@"life"];
    [defaults synchronize];

}


#pragma mark - Setup

-(void)setupSatellites{
    
    if(IS_OS_7_OR_LATER){
        for (int i=0;i<[satellites count];i++){
            
            float satD=50+arc4random()%100;
            Dots *sat= [satellites objectAtIndex:i];
            sat.frame=CGRectMake(16+(self.view.frame.size.width-16)/10.0*i,260,satD,satD);
            int dir=(arc4random() % 2 ? 1 : -1);
            float h=mainDot.frame.size.height*(arc4random()%8/10.0);
            
            CGRect orbit=CGRectMake(mainDot.frame.origin.x+satD*.15, mainDot.center.y-h/2.0, mainDot.frame.size.width-satD*.5, h);
            [sat animateAlongPath:orbit rotate:i/10.0*M_PI_2*2.0 speed:dir*((.01+arc4random()%1000)/4000.0)];

        }
    }
}

-(void)resetMainDot{
    int d=screenWidth*.8;
    mainDot.frame=CGRectMake(0,0,d,d);
    mainDot.center=CGPointMake(screenWidth/2.0, (screenHeight-88)*.75);
    //blob.frame=CGRectMake(0,screenHeight*.5,screenWidth,screenHeight*.5);
}


#pragma mark - Action
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [progressView convertPoint:locationPoint fromView:self.view];
    if (![progressView pointInside:viewPoint withEvent:event]) {
        [self buttonPressed];
        
        touchStartTime=[aTimer elapsedSeconds];
        
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint touchPoint = [touch locationInView:self.view];
        //NSLog(@"Touch x : %f y : %f", touchPoint.x, touchPoint.y);
        touchX=touchPoint.x;
        touchY=touchPoint.y;
        
    }
}



-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(progressView.frame.origin.y<-screenHeight*1.4){
        showIntro=true;
        [self showIntroView];
        return;
    }
    if([progressView.subMessage.text isEqual:@"GAME OVER"] || life<=0)return;
    UITouch *aTouch = [touches anyObject];
    CGPoint location = [aTouch locationInView:self.view];
    CGPoint previousLocation = [aTouch previousLocationInView:self.view];

    if ([progressView pointInside: [self.view convertPoint:location toView: progressView] withEvent:event]) {
        [self.view bringSubviewToFront:progressView];
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                                progressView.frame=CGRectOffset(progressView.frame, 0,location.y - previousLocation.y);
                         }
                         completion:^(BOOL finished){
                         }];
    }
    
    
    
}


-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    touchLength=[aTimer elapsedSeconds]-touchStartTime;

    
    
    if([progressView.subMessage.text isEqual:@"GAME OVER"] || life<=0)return;
    //if([[event allTouches]count]>1)return;
    //if ([touches count] == [[event touchesForView:self.view] count])


    UITouch *aTouch = [touches anyObject];
    CGPoint location = [aTouch locationInView:self.view];
    CGPoint previousLocation = [aTouch previousLocationInView:self.view];


        [UIView animateWithDuration:0.4
                              delay:0.0
             usingSpringWithDamping:.8
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             if(progressView.frame.origin.y>=0)
                             {
                                 if( (progressView.frame.origin.y<screenHeight-44 && location.y<previousLocation.y) || progressView.frame.origin.y<screenHeight*.125)
                                 {
                                    progressView.frame=CGRectMake(0, 0, screenWidth, progressView.frame.size.height);
                                     progressView.dotsContainer.frame=CGRectMake(0, 22, screenWidth, progressView.dotsContainer.frame.size.height);
                                     [self.view bringSubviewToFront:progressView];
                                 }
                                else {
                                    progressView.frame=CGRectMake(0, screenHeight-44, screenWidth, progressView.frame.size.height);
                                    if([stageLabels count]>0){
                                        TextArrow *sLabel=[stageLabels objectAtIndex:[self getCurrentStage]];
                                        float y=sLabel.frame.origin.y;
                                        progressView.dotsContainer.frame=CGRectMake(0,-y+15, screenWidth, progressView.dotsContainer.frame.size.height);
                                    }
                                    [self.view sendSubviewToBack:progressView];
                                    [self.view sendSubviewToBack:blob];
                                }
                                 
                             }
                             //scrolling towards graph view
                             else{
                                 //constrain to bottom of graph
                                 if(progressView.frame.origin.y<-screenHeight){
                                     progressView.frame=CGRectMake(0, -screenHeight, screenWidth, progressView.frame.size.height);
                                 }
                                 
                                 else if(progressView.frame.origin.y<0){
                                     if(location.y<previousLocation.y)progressView.frame=CGRectMake(0, -screenHeight*.5, screenWidth, progressView.frame.size.height);
                                     else if(location.y>previousLocation.y)progressView.frame=CGRectMake(0, 0, screenWidth, progressView.frame.size.height);

                                 }
                                 

                             }
                         }
                         completion:^(BOOL finished){
                             
                         }];
    
}



//- (IBAction)scalePiece:(UIPinchGestureRecognizer *)gestureRecognizer
//{
//    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
//        
//        nPointsVisible*=1.0/([gestureRecognizer scale]*[gestureRecognizer scale]);
//        
//        [gestureRecognizer setScale:1.0];
//        
//        if(nPointsVisible>=[self.trialData count]-1){
//            nPointsVisible=[self.trialData count]-1;
//            return;
//        }
//        else if(nPointsVisible<=10){
//            nPointsVisible=10;
//            return;
//        }
//        //self.myGraph.animationGraphEntranceTime = 0.0;
//        //[self.myGraph reloadGraph];
//    }
//}



//volume buttons
-(void)buttonPressed{
    if(showIntro){
        showIntro=false;
        [introArrow slideOut:0.0];
        [instructions slideOut:0.0];

        [UIView animateWithDuration:0.4
                              delay:0.6
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             intro.alpha=0;
                         }
                         completion:^(BOOL finished){
                             NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                             [defaults setInteger:showIntro forKey:@"showIntro"];
                             [defaults synchronize];
                             [instructions slideIn:0.2];

                         }];
        return;
    }
    
    if(progressView.frame.origin.y<=screenHeight*.25)return;
    //START
    if(trialSequence==0){
        [aTimer start];

        //startTime=[NSDate timeIntervalSinceReferenceDate];
        trialSequence=1;

        //[self updateTime];
        [instructions update:@"STOP" rightLabel:@"" color:[self getForegroundColor:currentLevel] animate:YES];
        
        //[self setTimerGoalMarginDisplay];
        
        
//        [UIView animateWithDuration:0.05
//                              delay:0.0
//                            options:UIViewAnimationOptionCurveEaseIn
//                         animations:^{
//                             mainDot.transform = CGAffineTransformScale(CGAffineTransformIdentity, .15, .15);
//                             for (int i=0;i<[satellites count];i++){
//                                 Dots *sat= [satellites objectAtIndex:i];
//                                 sat.transform = CGAffineTransformScale(CGAffineTransformIdentity, .5, .5);
//                             }
//                         }
//                         completion:^(BOOL finished){
//                             
//                         }];

            //[self.view bringSubviewToFront:blobBlur];
            [UIView animateWithDuration:0.6
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 //labelContainerBlur.alpha=1.0;
                                 progressView.frame=CGRectMake(0, screenHeight-44, screenWidth, progressView.frame.size.height);
                                 TextArrow *sLabel=[stageLabels objectAtIndex:[self getCurrentStage]];
                                 float y=sLabel.frame.origin.y;
                                 progressView.dotsContainer.frame=CGRectMake(0,-y+15, screenWidth, progressView.dotsContainer.frame.size.height);
                                 //blobBlur.alpha=0;

                             }
                             completion:^(BOOL finished){

                             }];

            
    }
    //STOP
    else if(trialSequence==1){
        //NSTimeInterval currentTime=[NSDate timeIntervalSinceReferenceDate];
        //elapsed = currentTime-startTime;
        elapsed=[aTimer elapsedSeconds];

        trialSequence=2;
        [self updateTimeDisplay:elapsed];
        [self trialStopped];
        counterLabel.alpha=1.0;
        
//        mainDot.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
//        for (int i=0;i<[satellites count];i++){
//            Dots *sat= [satellites objectAtIndex:i];
//            sat.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
//        }

    }
    //NEXT
    else if(trialSequence==2 && levelAlert.frame.origin.y<screenHeight){
        [self nextButtonPressed];
    }

}



-(void)setTimerGoalMarginDisplay{
    NSString * stop;
    NSDate* aDate = [NSDate dateWithTimeIntervalSince1970: [self getLevelAccuracy:currentLevel]];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"±s.SSS"];
    stop =[NSString stringWithFormat:@"%@ SEC", [df stringFromDate:aDate]];
    goalPrecision.text=stop;
    goalPrecision.alpha=1.0;
}

-(void)saveTrialData{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate* localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];

    
    //save to disk
    NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
    float diff=elapsed-timerGoal;
    [myDictionary setObject:[NSNumber numberWithFloat:diff] forKey:@"accuracy"];
    [myDictionary setObject:[NSNumber numberWithFloat:timerGoal] forKey:@"goal"];
    [myDictionary setObject:localDateTime forKey:@"date"];
    //[self.ArrayOfValues  insertObject:myDictionary atIndex:currentLevel];
    //dave data into continuous array
    [self.trialData addObject:myDictionary];
    //[self.trialData removeObjectAtIndex:0];
    
    //save into history
    [self.lastNTrialsData addObject:myDictionary];
    if([self.lastNTrialsData count]>100){
        [self.lastNTrialsData removeObjectAtIndex:0];
    }
    
    //[self.lastNTrialsData addObject:myDictionary];
    //[self.allTrialData addObject:myDictionary];

    
    //save data into clean array
    [self.levelData  insertObject:myDictionary atIndex:currentLevel];
    [self saveLevelProgress];

    //update graph
    //self.myGraph.animationGraphEntranceTime = 0.8;
    //[self.myGraph reloadGraph];
    //[self.allGraph reloadGraph];

    [self saveValues];
    
    [defaults synchronize];
}

//- (void)shareText:(NSString *)text andImage:(UIImage *)image andUrl:(NSURL *)url
- (void)share
{
    NSMutableArray *sharingItems = [NSMutableArray new];
    //NSURL * url;
    //NSString *text=[NSString stringWithFormat:@"",];
    //NSString *text=@"BOOM!";

    UIImage *image =[self screenshot];
    
//    if (text) {
//        [sharingItems addObject:text];
//    }
    if (image) {
        [sharingItems addObject:image];
    }
//    if (url) {
//        [sharingItems addObject:url];
//    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:^{
    }];
}

-(void)showIntroView{
    [self.view bringSubviewToFront:intro];
    [introArrow slideOut:0];
    
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         intro.alpha=1.0;
                     }
                     completion:^(BOOL finished){
                         [introArrow slideIn:0.8];
                         progressView.frame=CGRectMake(0, screenHeight-44, screenWidth, progressView.frame.size.height);
                         if([stageLabels count]>0){
                             TextArrow *sLabel=[stageLabels objectAtIndex:[self getCurrentStage]];
                             float y=sLabel.frame.origin.y;
                             progressView.dotsContainer.frame=CGRectMake(0,-y+15, screenWidth, progressView.dotsContainer.frame.size.height);
                         }
                     }];
    
}

- (UIImage *)screenshot
{
    CGSize imageSize = CGSizeZero;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        imageSize = [UIScreen mainScreen].bounds.size;
    } else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark DATA
//-(void)loadData:(float) level{
-(void)loadTrialData{
    
    //load values
    self.trialData = [[NSMutableArray alloc] init];
    
    //Creating a file path under iOS:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    //timeValuesFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"timeData%i.dat",(int)level]];
    timeValuesFile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"trialData4.dat"];

    //Load the array
    self.trialData = [[NSMutableArray alloc] initWithContentsOfFile: timeValuesFile];
    
    
//    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

//    self.allTrialData = [[NSMutableArray alloc] init];
//    allTrialDataFile = [[docPath objectAtIndex:0] stringByAppendingPathComponent:@"allTrialData.dat"];
//    self.allTrialData = [[NSMutableArray alloc] initWithContentsOfFile: allTrialDataFile];
//    if(self.allTrialData == nil){
//        
//        self.allTrialData = [[NSMutableArray alloc] init];
//        NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
//        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"accuracy"];
//        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"goal"];
//        [myDictionary setObject:[NSDate date] forKey:@"date"];
//        [self.allTrialData addObject:myDictionary];
//        [self saveValues];
//    }
    
    
    
    self.lastNTrialsData = [[NSMutableArray alloc] init];
    lastNTrialDataFile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"lastNTrialsData.dat"];
    self.lastNTrialsData = [[NSMutableArray alloc] initWithContentsOfFile: lastNTrialDataFile];
    if(self.lastNTrialsData == nil){
        
        self.lastNTrialsData = [[NSMutableArray alloc] init];
        for (int i = 0; i <2 ; i++) {
            NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
            [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"accuracy"];
            [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"goal"];
            [myDictionary setObject:[NSDate date] forKey:@"date"];
            [self.lastNTrialsData addObject:myDictionary];
        }
        [self saveValues];
    }
    

    if(self.trialData == nil)
    {
        [self clearTrialData];
    }
}

-(void)clearTrialData{
    //Array file didn't exist... create a new one
    self.trialData = [[NSMutableArray alloc] init];
    for (int i = 0; i <2 ; i++) {
        NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"accuracy"];
        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"goal"];
        [myDictionary setObject:[NSDate date] forKey:@"date"];
        [self.trialData addObject:myDictionary];
    }
    
    
    [self saveValues];
    
}

-(void)saveValues{
    [self.trialData writeToFile:timeValuesFile atomically:YES];
    //[self.allTrialData writeToFile:allTrialDataFile atomically:YES];
    [self.lastNTrialsData writeToFile:lastNTrialDataFile atomically:YES];

}

#pragma mark - GameCenter
-(void)reportScore{
    if(_leaderboardIdentifier){
        //GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:_leaderboardIdentifier];
        GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:@"global"];
        score.value = best*10.0;
        
        [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
        
//        GKScore *xp = [[GKScore alloc] initWithLeaderboardIdentifier:@"experiencepoints"];
//        xp.value = experiencePoints*100.0;
//        
//        [GKScore reportScores:@[xp] withCompletionHandler:^(NSError *error) {
//            if (error != nil) {
//                NSLog(@"%@", [error localizedDescription]);
//            }
//        }];
        
        GKScore *sp = [[GKScore alloc] initWithLeaderboardIdentifier:@"starBank"];
        sp.value = starBank;
        
        [GKScore reportScores:@[sp] withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
        
    }
}

//-(void)updateAchievements{
//    
//    GKAchievement *trialAchievement = nil;
//
//    trialAchievement = [[GKAchievement alloc] initWithIdentifier:@"1000Trials"];
//    //trialAchievement.percentComplete = allTimeTotalTrials/1000*100;
//    trialAchievement.percentComplete = allTimeTotalTrials*10;
//
//    GKAchievement *perfectHealthStreak = nil;
//    perfectHealthStreak = [[GKAchievement alloc] initWithIdentifier:@"perfectHealthStreak"];
//    perfectHealthStreak.percentComplete=0;
//    
//    GKAchievement *perfectAccuracyStreak = nil;
//    perfectAccuracyStreak = [[GKAchievement alloc] initWithIdentifier:@"perfectAccuracyStreak"];
//    perfectAccuracyStreak.percentComplete=0;
//
//    NSArray *achievements =@[trialAchievement,perfectHealthStreak,perfectAccuracyStreak] ;
//    
//    [GKAchievement reportAchievements:achievements withCompletionHandler:^(NSError *error) {
//        if (error != nil) {
//            //NSLog(@&quot;%@&quot;, [error localizedDescription]);
//        }
//    }];
//}


-(void)showGlobalLeaderboard{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    gcViewController.leaderboardIdentifier = @"global";
    [self presentViewController:gcViewController animated:YES completion:nil];
}

-(void)showSBLeaderboard{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    gcViewController.leaderboardIdentifier = @"starBank";
    [self presentViewController:gcViewController animated:YES completion:nil];
}
-(void)showAchievements{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateAchievements;
    [self presentViewController:gcViewController animated:YES completion:nil];
}
-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark LEVELS
-(void)loadLevelProgress{
    //load values
    self.levelData = [[NSMutableArray alloc] init];
    
    //Creating a file path under iOS:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *File = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"levelData.dat"];
    
    //Load the array
    self.levelData = [[NSMutableArray alloc] initWithContentsOfFile: File];
    
    if(self.levelData == nil)
    {
        //Array file didn't exist... create a new one
        self.levelData = [[NSMutableArray alloc] init];
        for (int i = 0; i < 2; i++) {
            
            NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
            [myDictionary  setObject:[NSNumber numberWithInt:0] forKey:@"accuracy"];
            [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"goal"];
            [myDictionary setObject:[NSDate date] forKey:@"date"];
            [self.levelData addObject:myDictionary];
 
        }
        [self saveLevelProgress];
    }
    
}

-(void)saveLevelProgress{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *File = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"levelData.dat"];
    [self.levelData writeToFile:File atomically:YES];
}


-(void)setLevel:(int)level{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:currentLevel forKey:@"currentLevel"];
    
    if(level>0 && practicing==false){

        float lastSuccessfulGoal=fabs([[[self.levelData objectAtIndex:level-1] objectForKey:@"goal"] floatValue]);
        
        if(lastSuccessfulGoal>=best){
            best=lastSuccessfulGoal;
            [defaults setInteger:best forKey:@"best"];
        }
        [self updateBestDot];

        [self updateHighscore];
    }
     [defaults synchronize];
    
    
    timerGoal=[self getLevel:level];

    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         counterGoalLabel.alpha=0;
                         counterLabel.alpha=0;
                         //goalPrecision.alpha=0;
                     }
                     completion:^(BOOL finished){
                         [self animateLevelReset];

                     }];
    
    
    float backgroundColorDuration=0.0;
    if ( currentLevel%TRIALSINSTAGE==0)backgroundColorDuration=0.4;

     //change background color
     [UIView animateWithDuration:backgroundColorDuration
                           delay:0.0
                         options:UIViewAnimationOptionCurveLinear
                      animations:^{
                          
                          trophyButton.alpha=1;
                          medalButton.alpha=1;
                          highScoreLabel.alpha=1;
                          bestLabel.alpha=1;
                          restartButton.alpha=1;
                          

                          mainDot.dotColor=[self getForegroundColor:currentLevel];
                          [mainDot setNeedsDisplay];

//                          CGFloat hue, saturation, brightness, alpha ;
//                          [[self getBackgroundColor:currentLevel] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha ] ;
//                          UIColor * sColor= [ UIColor colorWithHue:hue saturation:saturation+.05 brightness:brightness+.05 alpha:alpha ];
                          
                          restartButton.tintColor=[self getBackgroundColor:currentLevel];
                          restartExpandButton.tapCircleColor=[self getBackgroundColor:currentLevel];
                          trophyButton.tintColor=[self getBackgroundColor:currentLevel];
                          medalButton.tintColor=[self getBackgroundColor:currentLevel];
                          highScoreLabel.textColor=[self getBackgroundColor:currentLevel];
                          bestLabel.textColor=[self getBackgroundColor:currentLevel];

                          
                          if(practicing) self.view.backgroundColor=[UIColor colorWithWhite:.7 alpha:1.0];
                          else self.view.backgroundColor=[self getBackgroundColor:currentLevel];
                          
                          instructions.instructionText.textColor=self.view.backgroundColor;
                          instructions.rightLabel.textColor=self.view.backgroundColor;

                          [instructions setColor:[self getForegroundColor:currentLevel]];
                          progressView.backgroundColor=[self getForegroundColor:currentLevel];
                          
                          //progressViewLower.backgroundColor=aColor;
                          
                          counterLabel.textColor=[self getForegroundColor:currentLevel];
                          counterGoalLabel.textColor=[self getForegroundColor:currentLevel];
                          goalPrecision.textColor=[self getForegroundColor:currentLevel];
                          

                          //stage data
                          self.myGraph.colorLine = [self getBackgroundColor:currentLevel];
                          self.myGraph.colorXaxisLabel = [self getBackgroundColor:currentLevel];
                          self.myGraph.colorYaxisLabel = [self getBackgroundColor:currentLevel];
                          self.myGraph.colorPoint=[self getBackgroundColor:currentLevel];
                         

                          precision.textColor=[self getBackgroundColor:currentLevel];
                          accuracy.textColor=[self getBackgroundColor:currentLevel];
                          averageTime.textColor=[self getBackgroundColor:currentLevel];
                          precisionUnit.textColor=[self getBackgroundColor:currentLevel];
                          accuracyUnit.textColor=[self getBackgroundColor:currentLevel];
                          averageUnit.textColor=[self getBackgroundColor:currentLevel];
                          precisionLabel.textColor=[self getBackgroundColor:currentLevel];
                          accuracyLabel.textColor=[self getBackgroundColor:currentLevel];
                          averageLabel.textColor=[self getBackgroundColor:currentLevel];
                          myGraphLabel.textColor=[self getBackgroundColor:currentLevel];
                          
                          
                          //all data
                          self.allGraph.colorLine = [self getBackgroundColor:currentLevel];
                          self.allGraph.colorXaxisLabel = [self getBackgroundColor:currentLevel];
                          self.allGraph.colorYaxisLabel = [self getBackgroundColor:currentLevel];
                          self.allGraph.colorPoint=[self getBackgroundColor:currentLevel];
                          
                          allPrecision.textColor=[self getBackgroundColor:currentLevel];
                          allAccuracy.textColor=[self getBackgroundColor:currentLevel];
                          allAverageTime.textColor=[self getBackgroundColor:currentLevel];
                          allPrecisionUnit.textColor=[self getBackgroundColor:currentLevel];
                          allAccuracyUnit.textColor=[self getBackgroundColor:currentLevel];
                          allAverageUnit.textColor=[self getBackgroundColor:currentLevel];
                          allPrecisionLabel.textColor=[self getBackgroundColor:currentLevel];
                          allAccuracyLabel.textColor=[self getBackgroundColor:currentLevel];
                          allAverageLabel.textColor=[self getBackgroundColor:currentLevel];
                          allGraphLabel.textColor=[self getBackgroundColor:currentLevel];
                          
                          questionMark.textColor=[self getBackgroundColor:currentLevel];
                          
                          
                        }
                      completion:^(BOOL finished){
                          [self updateDotColors];
                          [self.myGraph reloadGraph];//to reload color
                          [self.allGraph reloadGraph];//to reload color

                          //[self updateTimeDisplay:0];
                          [self setTimerGoalMarginDisplay];

                          myGraphLabel.text=[NSString stringWithFormat:@"STAGE %i",[self getCurrentStage]+1];

     
          }];
    
}

-(float)getLevel:(int)level{
    float l;
    if(level<TRIALSINSTAGE)l=.5+level*0.1f;
    else if(level<TRIALSINSTAGE*2)l=1.0+level%TRIALSINSTAGE*0.1f;
    //else if(level<TRIALSINSTAGE*3)l=1.5+level%TRIALSINSTAGE*0.2;
    //else if(level<TRIALSINSTAGE*4)l=2.5+level%TRIALSINSTAGE*0.2;
    else l=-.5f+level*0.2f;
    
    if(l>999.0)l=999.0;
    
//    else if(level<TRIALSINSTAGE*5)l=5.0+level%TRIALSINSTAGE*1.0;
//    else l=5.0+level%TRIALSINSTAGE*1.0;
    
    return l;
}

-(float)getLevelAccuracy:(int)level{
//    if([self getLevel:level]<=5) return .1;
//    if([self getLevel:level]<=10) return .15;
//    else if([self getLevel:level]<=20) return .2;
//    else  return 1.0;
    return .1;
}


-(void)checkLevelUp{


    [self.view bringSubviewToFront:oView];
    [self.view bringSubviewToFront:xView];
    
    [UIView animateWithDuration:0.4
                          delay:0.4
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         if([self isAccurate]){
                             Dots *dot=[dots objectAtIndex:currentLevel];
                             CGPoint xy=[dot.superview convertPoint:dot.frame.origin toView:nil];

                             oView.frame = CGRectMake( xy.x,xy.y,dot.frame.size.width,dot.frame.size.height);
                         }
                         else{
                             if(life-1>0){
                                 Dots *heart=[hearts objectAtIndex:life-1];
                                 xView.frame = CGRectMake( heart.frame.origin.x,heart.frame.origin.y,heart.frame.size.width,heart.frame.size.height);
                             }
                         }
                     }
                     completion:^(BOOL finished){
                         
                         nHeartsReplenished=0;

                         [self xoViewOffScreen];
                         
                         //save trial data now
                         [self saveTrialData];

                         if([self isAccurate]){
                             if(life<NUMHEARTS){
                                 nHeartsReplenished=NUMHEARTS-life;
                                 life=NUMHEARTS;
                             }

                            //add heart for triplestar level
                              nLifeEarned=0;

                             float trialAccuracy=fabs(elapsed-timerGoal);
                             if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*1/10.0)nLifeEarned=1;;

//                             if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*1/10.0)life+=4;
//                             else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*2/10.0)life+=3;
//                             else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*3/10.0)life+=2;
//                             else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*4/10.0)life++;
                             
                              nStarsEarned=0;
                             if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*1.0/5.0)nStarsEarned=1;
                             else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*2.0/5.0) nStarsEarned=2;
                             else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*3.0/5.0)nStarsEarned=1;
                             
                             starBank+=nStarsEarned;
                             life+=nLifeEarned;
                             
                             [[NSUserDefaults standardUserDefaults] setInteger:starBank forKey:@"starBank"];
                             [[NSUserDefaults standardUserDefaults] synchronize];
            
                             
                             
                             //save current level now
                             currentLevel++;
                             
                             //streak
                             currentStreak++;
                             
                             if(currentStreak==1)experiencePoints+=elapsed*timerGoal;
                             else if(currentStreak>1) experiencePoints+=elapsed*timerGoal*currentStreak;

                            //add heart for clearing stage
                            //if(currentLevel%TRIALSINSTAGE==0) life++;
                         }
                         else{
                             currentStreak=0;
                             life--;
                         }

                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                         [defaults setInteger:currentLevel forKey:@"currentLevel"];
                         [defaults setInteger:currentStreak forKey:@"currentStreak"];
                         [defaults synchronize];

                         
                         if(life<=0) lastStage=[self getCurrentStage];
                         if(practicing==false) [self reportScore];

                         [self performSelector:@selector(updateLife) withObject:self afterDelay:.01];
                         [self performSelector:@selector(updateDots) withObject:self afterDelay:.01];
                         [self performSelector:@selector(showLevelAlerts) withObject:self afterDelay:.5];


                     }];
    
    

    
}

-(void)showLevelAlerts{

    //arrow delay
    float d=0;
    float inc=.07;
    int arrowN=0;
    int margin=screenHeight-44-37;
    int spacing=-1;
    
    for (int i=0; i<NUMLEVELARROWS; i++){
        TextArrow * t=[levelArrows objectAtIndex:i];
        t.rightLabel.textColor=self.view.backgroundColor;
    }
 
    float diff=elapsed-timerGoal;

    TextArrow *t;//= [levelArrows objectAtIndex:arrowN];
    
    //ARROW1
    float trialAccuracy=fabs(elapsed-timerGoal);
    if(life>0){
        NSString * bonusString=@"";
        if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*1/10.0)      bonusString=@"PERFECT!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*2/10.0) bonusString=@"BOOOOOM!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*3/10.0) bonusString=@"WOOT!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*4/10.0) bonusString=@"MONEY!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*5/10.0) bonusString=@"GREAT!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*6/10.0) bonusString=@"NICE!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*7/10.0) bonusString=@"DONE!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*8/10.0) bonusString=@"SWEET!";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*9/10.0) bonusString=@"CLOSE ENOUGH";
        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel])        bonusString=@"MEH";
        
        else if(diff<-1)  bonusString=@"WAY TOO FAST!";
        else if(diff<-.5) bonusString=@"PATIENCE! GO SLOWER.";
        else if(diff<-.4) bonusString=@"SLOW DOWN";
        else if(diff<-.3) bonusString=@"BREATHE. SLOW DOWN.";
        else if(diff<-.2) bonusString=@"SLOW DOWN A BIT";
        else if(diff<0)   bonusString=@"A BIT TOO EARLY";
        
        else if(diff>1)  bonusString=@"WAY TOO SLOW!";
        else if(diff>.5) bonusString=@"SPEED UP!";
        else if(diff>.4) bonusString=@"GO FASTER!";
        else if(diff>.3) bonusString=@"TOO LATE! FASTER!";
        else if(diff>.2) bonusString=@"A BIT TOO SLOW";
        else if(diff>0)  bonusString=@"GO A BIT FASTER";
        
        
//        int nStarsEarned=0;
//        if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*1.0/5.0)nStarsEarned=3;
//        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*2.0/5.0) nStarsEarned=2;
//        else if(trialAccuracy<=[self getLevelAccuracy:currentLevel]*3.0/5.0)nStarsEarned=1;
        
        t= [levelArrows objectAtIndex:arrowN];
        NSMutableAttributedString *attributedString;
        if(nLifeEarned>0){
            bonusString=[NSString stringWithFormat:@"%@ ❤\U0000FE0E+%i",bonusString, nLifeEarned];
            attributedString = [[NSMutableAttributedString alloc] initWithString:bonusString
                                                                      attributes:@{NSFontAttributeName: [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize]}];
            [attributedString setAttributes:@{NSFontAttributeName : [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize*.4]
                                              , NSBaselineOffsetAttributeName : [NSNumber numberWithFloat:t.rightLabel.font.pointSize*.4]} range:NSMakeRange(bonusString.length-2, 2)];
            
            [t update:@"" rightLabel:@"" color:instructions.color animate:NO];
            t.rightLabel.attributedText=attributedString;
        }else{
            [t update:@"" rightLabel:bonusString color:instructions.color animate:NO];
        }
        margin-=spacing+t.frame.size.height;
        d+=inc;
        [t slideUpTo:margin delay:d];
        [self.view bringSubviewToFront:t];
    }
    arrowN++;
    
    NSString *diffString;
//    if(trialAccuracy>[self getLevelAccuracy:currentLevel]){
//        if(diff<0)diffString=[NSString stringWithFormat:@"%@ SECONDS EARLY",[self getTimeDiffString:diff]];
//        else if(diff>0)diffString=[NSString stringWithFormat:@"%@ SECONDS LATE",[self getTimeDiffString:diff]];
//    }
//    else {
        if(diff<0)diffString=[NSString stringWithFormat:@"-%@ SECONDS",[self getTimeDiffString:diff]];
        else diffString=[NSString stringWithFormat:@"+%@ SECONDS",[self getTimeDiffString:diff]];
    //}
    t= [levelArrows objectAtIndex:arrowN];
    [t update:@"" rightLabel:diffString color:instructions.color animate:NO];
    margin-=spacing+t.frame.size.height;
    d+=inc;
    [t slideUpTo:margin delay:d];
    [self.view bringSubviewToFront:t];
    arrowN++;
    
    
    if(([self isAccurate] && currentLevel%TRIALSINSTAGE==0) || life<=0) {
        NSString * stageClearedString;
        t= [levelArrows objectAtIndex:arrowN];

        if(life<=0) stageClearedString=@"GAME OVER";
        
        else if([self isAccurate] && currentLevel%TRIALSINSTAGE==0){
            //stageClearedString=[NSString stringWithFormat:@"STAGE %i CLEARED! ❤\U0000FE0E⁺¹",[self getCurrentStage]];
            stageClearedString=[NSString stringWithFormat:@"STAGE %i CLEARED!",[self getCurrentStage]];

        }

        [t update:@"" rightLabel:stageClearedString color:instructions.color animate:NO];
        margin-=spacing+t.frame.size.height;
        d+=inc;
        [t slideUpTo:margin delay:d];
        [self.view bringSubviewToFront:t];
        arrowN++;

    }
    else if(nHeartsReplenished>0) {
        NSString * stageClearedString;
        NSMutableAttributedString *attributedString;
        t= [levelArrows objectAtIndex:arrowN];
        if(nHeartsReplenished>1){
            stageClearedString=[NSString stringWithFormat:@"LIFE REPLENISHED ❤\U0000FE0E+%i", nHeartsReplenished];
            attributedString = [[NSMutableAttributedString alloc] initWithString:stageClearedString
                                                                      attributes:@{NSFontAttributeName: [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize]}];
            [attributedString setAttributes:@{NSFontAttributeName : [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize*.4]
                                              , NSBaselineOffsetAttributeName : [NSNumber numberWithFloat:t.rightLabel.font.pointSize*.4]} range:NSMakeRange(stageClearedString.length-2, 2)];
        }
        else stageClearedString=@"LIFE REPLENISHED ❤\U0000FE0E";
        
        if(nHeartsReplenished>1){
            [t update:@"" rightLabel:@"" color:instructions.color animate:NO];
            t.rightLabel.attributedText=attributedString;
        }
        else [t update:@"" rightLabel:stageClearedString color:instructions.color animate:NO];
        margin-=spacing+t.frame.size.height;
        d+=inc;
        [t slideUpTo:margin delay:d];
        [self.view bringSubviewToFront:t];
        arrowN++;
    }
    

    


    
    
    

    
    //ARROW2
    //float accuracyP=100.0-fabs(diff/(float)timerGoal)*100.0;
    float accuracyP=[self getAccuracyPercentage];
    NSString* percentAccuracyString = [NSString stringWithFormat:@"ACCURACY %02i%%", (int)accuracyP];
    t= [levelArrows objectAtIndex:arrowN];
    [t update:@"" rightLabel:percentAccuracyString color:instructions.color animate:NO];
    margin-=spacing+t.frame.size.height;
    d+=inc;
    [t slideUpTo:margin delay:d];
    [self.view bringSubviewToFront:t];
    arrowN++;
    
    
    
    NSString * stageProgressString;
    //if([self isAccurate]) stageProgressString=[NSString stringWithFormat:@"LEVEL %.01f CLEARED %0.1f POINTS",[self getLevel:currentLevel-1], elapsed*timerGoal];
    if([self isAccurate]){
        //if(currentStreak==1) stageProgressString=[NSString stringWithFormat:@"+$%0.2f", elapsed*timerGoal];
        //else if(currentStreak>1) stageProgressString=[NSString stringWithFormat:@"%i LEVEL STREAK! +$%0.2f", currentStreak, elapsed*timerGoal*currentStreak];

        //if(currentStreak==1) stageProgressString=[NSString stringWithFormat:@"+%i★", currentStreak;
        if(currentStreak>1){
        
//    }
//    else if(life>1) stageProgressString=[NSString stringWithFormat:@"%i TRIES LEFT",life];
//    else if(life>0) stageProgressString=@"LAST TRY!";
//    //else stageProgressString=@"GAME OVER";
//    if(life>0){
            t= [levelArrows objectAtIndex:arrowN];
            
            stageProgressString=[NSString stringWithFormat:@"%i LEVEL STREAK! ★+%i", currentStreak, currentStreak];
            int nDigits = floor(log10(abs(currentStreak))) + 2;

            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:stageProgressString
                                                                                attributes:@{NSFontAttributeName: [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize]}];
            [attributedString setAttributes:@{NSFontAttributeName : [t.rightLabel.font fontWithSize:t.rightLabel.font.pointSize*.4]
                                              , NSBaselineOffsetAttributeName : [NSNumber numberWithFloat:t.rightLabel.font.pointSize*.4]} range:NSMakeRange(stageProgressString.length-nDigits, nDigits)];
            
            [t update:@"" rightLabel:@"" color:instructions.color animate:NO];
            t.rightLabel.attributedText=attributedString;
                
            margin-=spacing+t.frame.size.height;
            d+=inc;
            [t slideUpTo:margin delay:d];
            [self.view bringSubviewToFront:t];
        }
    }
    arrowN++;
   

    //[levelAlert update:[NSString stringWithFormat:@"%.1f COOKIES",highScore] rightLabel:@""   color:instructions.color animate:NO];
    [levelAlert update:@"" rightLabel:@""   color:instructions.color animate:NO];

    //next buton
    levelAlert.rightLabel.frame=CGRectMake(levelAlert.rightLabel.frame.origin.x, levelAlert.rightLabel.frame.origin.y, levelAlert.frame.size.width-nextButton.frame.size.width*2.2, levelAlert.rightLabel.frame.size.height);
    levelAlert.rightLabel.textColor=[UIColor blackColor];
    //TextArrow *sl=[stageLabels objectAtIndex:0];

    nextButton.tintColor=self.view.backgroundColor;
    shareButton.tintColor=self.view.backgroundColor;

    margin-=spacing+levelAlert.frame.size.height;
    d+=inc;
    [levelAlert slideUpTo:margin delay:d];
    [self.view bringSubviewToFront:levelAlert];

    

    //blank instruction
    [instructions update:@"" rightLabel:@"" color:counterGoalLabel.textColor animate:NO];
    d+=inc;
    [instructions slideIn:d];
    
    
}

-(void)getExperiencePoints{
    
}

-(void)showGameOverSequence{
    
    //show progressview
    [self.view bringSubviewToFront:progressView];
    [progressView bringSubviewToFront:progressView.subMessage];

    if(lastStage==0) {
        
        progressView.subMessage.alpha=0;
        [UIView animateWithDuration:0.4
                              delay:0.0
             usingSpringWithDamping:.8
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             progressView.frame=CGRectMake(0, 0, screenWidth, progressView.frame.size.height);
                             progressView.dotsContainer.frame=CGRectMake(0, 22, screenWidth, progressView.dotsContainer.frame.size.height);

                         }
                         completion:^(BOOL finished){
                             [self showGameOver];

                         }];
        
        return;
    }
    //progressView.subMessage.text=[NSString stringWithFormat:@"SPEND $%.02f \nTO CONTINUE FROM STAGE %i?",lastStage*10.0,lastStage+1];
    progressView.subMessage.text=[NSString stringWithFormat:@"SPEND %i POINTS\nTO CONTINUE FROM STAGE %i?",lastStage ,lastStage+1];

    progressView.subMessage.alpha=0.0;
    [progressView bringSubviewToFront:progressView.subMessage];
    progressView.subMessage.textColor=trophyButton.tintColor;
    progressView.centerMessage.textColor=trophyButton.tintColor;
    [progressView bringSubviewToFront:progressView.centerMessage];

    playButton.alpha=0.0;
    playButton.tintColor=trophyButton.tintColor;
    playButton.center=CGPointMake(screenWidth/2.0, progressView.subMessage.frame.origin.y+progressView.subMessage.frame.size.height+10);

    
    progressView.lowerMessage.frame=CGRectMake(0, playButton.frame.origin.y+playButton.frame.size.height+30, progressView.lowerMessage.frame.size.width, progressView.lowerMessage.frame.size.height);
    progressView.lowerMessage.text=@"RESTART";
    progressView.lowerMessage.textColor=trophyButton.tintColor;
    progressView.lowerMessage.textColor=trophyButton.tintColor;
    progressView.lowerMessage.alpha=0.0;
    [progressView bringSubviewToFront:progressView.lowerMessage];

//    [progressView addShadow:progressView.subMessage];
//    [progressView addShadow:progressView.lowerMessage];

    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         progressView.frame=CGRectMake(0, 0, screenWidth, progressView.frame.size.height);
                         progressView.dotsContainer.frame=CGRectMake(0, 22, screenWidth, progressView.dotsContainer.frame.size.height);
                     }
                     completion:^(BOOL finished){
                         //fade in blur
                         [UIView animateWithDuration:0.4
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{
                                              gameOverBlur.alpha=1;
                                          }
                                          completion:^(BOOL finished){
                                              
                                              //move restart button
                                              [UIView animateWithDuration:0.4
                                                                    delay:0.0
                                                   usingSpringWithDamping:.8
                                                    initialSpringVelocity:1.0
                                                                  options:UIViewAnimationOptionCurveLinear
                                                               animations:^{
                                                                   progressView.subMessage.alpha=1.0;
                                                                   progressView.lowerMessage.alpha=1.0;
                                                                   playButton.alpha=1.0;


                                                                   restartButton.center=CGPointMake(screenWidth*.5, progressView.lowerMessage.frame.origin.y+progressView.lowerMessage.frame.size.height+20);
                                                                   
                                                               }
                                                               completion:^(BOOL finished){
                                                                   [self countdown];

                                                               }];
                                          }];

                     }];

    

    
}


-(void)countdown{
    [self.view bringSubviewToFront:progressView];
    [progressView bringSubviewToFront:progressView.subMessage];
    
    if(life<=0){//check if countdown got interrupted by restart
        [progressView displayMessage:[NSString stringWithFormat:@"%i",resetCountdown]];
        resetCountdown--;
        if(resetCountdown>=0)[self performSelector:@selector(countdown) withObject:self afterDelay:1.0];
        else{
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 progressView.subMessage.alpha=0;
                                 progressView.lowerMessage.alpha=0;
                                 playButton.alpha=0.0;
                             }
                             completion:^(BOOL finished){
                                 [self showGameOver];
                                 
                                 
                                 
                                 
                             }];
        }
    }
}

-(void)showGameOver{
    progressView.subMessage.text=@"GAME OVER";
    //[progressView addShadow:progressView.subMessage];
    
    
    progressView.subMessage.textColor=trophyButton.tintColor;


     [UIView animateWithDuration:0.4
                           delay:0.0
                         options:UIViewAnimationOptionCurveLinear
                      animations:^{
                          gameOverBlur.alpha=1;
                      }
                      completion:^(BOOL finished){
                          [UIView animateWithDuration:0.4
                                                delay:0.0
                               usingSpringWithDamping:.8
                                initialSpringVelocity:1.0
                                              options:UIViewAnimationOptionCurveLinear
                                           animations:^{
                                               progressView.subMessage.alpha=1.0;

                                               restartButton.center=CGPointMake(screenWidth*.5, progressView.subMessage.frame.origin.y+progressView.subMessage.frame.size.height);
                                               
                                           }
                                           completion:^(BOOL finished){
                                           }];
                      }];
     

     
    

    

    
}

-(void)nextButtonPressed{
    
    [self.view bringSubviewToFront:progressView];
    for(int i=0; i<NUMLEVELARROWS; i++)[[levelArrows objectAtIndex:i] slideDown:(float)i*.05];
    [levelAlert slideDown:(float)(NUMLEVELARROWS)*.05];
    [instructions slideOut:0];
    
    if(life<=0){
        resetCountdown=20;
        currentLevel=0;
        [self performSelector:@selector(showGameOverSequence) withObject:self afterDelay:.1];
    }
    
    //check for stage up to add dots
    else if ( (currentLevel%TRIALSINSTAGE==0 && [self isAccurate])) {
        bestLevelDot.alpha=0;
        [self performSelector:@selector(setupDots) withObject:self afterDelay:.1];
        [self performSelector:@selector(clearTrialData) withObject:self afterDelay:2.0];

    }
    else [self performSelector:@selector(loadLevel) withObject:self afterDelay:.001];
    //else [self loadLevel];

    
}


-(void)loadLevel{
    if(currentLevel==0 && life<=0){
        life=NUMHEARTS;
        [self updateLife];
    }
    
    [self setLevel:currentLevel];
    [self loadTrialData];
    [self loadLevelProgress];
    [self.myGraph reloadGraph];
    [self.allGraph reloadGraph];
}


# pragma mark LABELS
-(void)updateTimeDisplay: (NSTimeInterval) interval{
    
    //main stopwatch
    NSTimeInterval absoluteTime=fabs(interval);
    [self timerMainDisplay:absoluteTime];
    
    //goal String
    NSTimeInterval goalInterval=timerGoal;
    [self timerGoalDisplay:goalInterval];
    
    //next goal String
    NSTimeInterval nextGoal=[self getLevel:currentLevel+1];
    NSDate* nDate = [NSDate dateWithTimeIntervalSince1970: nextGoal];
    NSDateFormatter* ngf = [[NSDateFormatter alloc] init];
    [ngf setDateFormat:@"sssss.SSS"];
    NSString* nGoalString = [ngf stringFromDate:nDate];
    [nextLevelLabel setText:[NSString stringWithFormat:@"NEXT LEVEL:%@",nGoalString]];
}


-(void)updateTime{
    
    //NSTimeInterval currentTime=[NSDate timeIntervalSinceReferenceDate];
    //elapsed = currentTime-startTime;
    
    if(trialSequence==1){
            //[self updateTimeDisplay:currentTime-startTime];
            [self performSelector:@selector(updateTime) withObject:self afterDelay:0.1];
        if([aTimer elapsedSeconds]-timerGoal>9.9){
            //stop because way off
            [self buttonPressed];
            
        }
    }

}



-(NSString *)getTimeDiffString:(NSTimeInterval)time{
    
    NSDate* aDate = [NSDate dateWithTimeIntervalSince1970: fabs(time)];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    //if(time<60){
    //if(time>=0) [df setDateFormat:@"+s.SSS"];
    //else [df setDateFormat:@"-s.SSS"];
    [df setDateFormat:@"s.SSS"];
//    }else{
//        if(time>=0) [df setDateFormat:@"+s.SSS"];
//        else [df setDateFormat:@"-s.SSS"];
//    }
    NSString* counterString = [df stringFromDate:aDate];
    return counterString;
    
}



-(void)timerDiffDisplay:(NSTimeInterval)time{
    
    NSDate* aDate = [NSDate dateWithTimeIntervalSince1970: fabs(time)];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    if(time>0) [df setDateFormat:@"sss.SSSSSS"];
    else [df setDateFormat:@"sss.SSSSSS"];
    
    NSString* counterString = [df stringFromDate:aDate];
    [differencelLabel setText:counterString];
}



-(void)timerGoalDisplay:(NSTimeInterval)goal{
    NSDate* gDate = [NSDate dateWithTimeIntervalSince1970: goal];
    NSDateFormatter* gf = [[NSDateFormatter alloc] init];
    [gf setDateFormat:@"sss.SSSSSS"];
    NSString* goalString = [gf stringFromDate:gDate];
    [counterGoalLabel setText:goalString];
}

-(void)timerMainDisplay:(NSTimeInterval)time{
//    NSDate* aDate = [NSDate dateWithTimeIntervalSince1970: fabs(time)];
//    NSDateFormatter* df = [[NSDateFormatter alloc] init];
//    if(time>0) [df setDateFormat:@"sss.SSSSSS"];
//    else [df setDateFormat:@"sss.SSSSSS"];
    
    //NSString* counterString = [df stringFromDate:aDate];
    NSString* counterString = [NSString stringWithFormat:@"%010.6f",time];

    [counterLabel setText:counterString];
}

-(void)updateStats{
    
    if([self.trialData count]>0){
     //results
    int nPoints=0;

     //accuracy
    //needs to be this way in case timergoal is 0
    float averageAccuracy=0;
    float averageOffset=0;
    float accuracyOffset=0;
    
     for( int i=0; i<[self.trialData count]; i++){
         //int index=(int)[self.trialData count]-(int)nPointsVisible+i; //show last nPoints
        accuracyOffset=[[[self.trialData objectAtIndex:i] objectForKey:@"accuracy"] floatValue];
        float absResult=fabs(accuracyOffset);
        float goal=[[[self.trialData objectAtIndex:i] objectForKey:@"goal"] floatValue];
         
        if(goal!=0){
            averageOffset+=accuracyOffset;
            float accuracyPercent=100.0-absResult/goal*100.0;
            if(accuracyPercent<0)accuracyPercent=0;
            accuracyPercent=ceilf(accuracyPercent);
             averageAccuracy+=accuracyPercent;
             nPoints++;
         }


     }
     
    if(nPoints>0) averageOffset=averageOffset/(float)nPoints;
    if(averageOffset>=0) averageTime.text=[NSString stringWithFormat:@"+%.03f",(float)averageOffset];
        else averageTime.text=[NSString stringWithFormat:@"%.03f",(float)averageOffset];

        //averageAccuracy=[[self.myGraph calculatePointValueAverage] floatValue];
        //float accuracyP=100.0-fabs(([[self.myGraph calculatePointValueAverage] floatValue]))/(float)goal*100.0;
        averageAccuracy=averageAccuracy/(float)nPoints;
         accuracy.text = [NSString stringWithFormat:@"%02i", (int)averageAccuracy];

         float uncertainty=[[self.myGraph calculateLineGraphStandardDeviation]floatValue];
         precision.text=[NSString stringWithFormat:@"±%.03f",(float)uncertainty];
    }
    
    
    if([self.lastNTrialsData count]>0){
        //results
        int nPoints=0;
        
        //accuracy
        //needs to be this way in case timergoal is 0
        float averageAccuracy=0;
        float averageOffset=0;
        float accuracyOffset=0;
        
        for( int i=0; i<[self.lastNTrialsData count]; i++){
            accuracyOffset=[[[self.lastNTrialsData objectAtIndex:i] objectForKey:@"accuracy"] floatValue];
            float absResult=fabs(accuracyOffset);
            float goal=[[[self.lastNTrialsData objectAtIndex:i] objectForKey:@"goal"] floatValue];
            
            if(goal!=0){
                averageOffset+=accuracyOffset;
                float accuracyPercent=100.0-absResult/goal*100.0;
                if(accuracyPercent<0)accuracyPercent=0;
                accuracyPercent=ceilf(accuracyPercent);
                averageAccuracy+=accuracyPercent;
                nPoints++;
            }
            
            
        }
        
        averageOffset=averageOffset/(float)nPoints;
        if(averageOffset>=0) allAverageTime.text=[NSString stringWithFormat:@"+%.03f",(float)averageOffset];
        else allAverageTime.text=[NSString stringWithFormat:@"%.03f",(float)averageOffset];
        
        averageAccuracy=averageAccuracy/(float)nPoints;
        allAccuracy.text = [NSString stringWithFormat:@"%02i", (int)averageAccuracy];
        
        float uncertainty=[[self.allGraph calculateLineGraphStandardDeviation]floatValue];
        allPrecision.text=[NSString stringWithFormat:@"±%.03f",(float)uncertainty];
        
        allGraphLabel.text=[NSString stringWithFormat:@"LAST %i TRIALS",(int)[self.lastNTrialsData count]];
        

    }
    
    
}


# pragma mark Blob
-(void)addBlob{
    
    //reposition maindot below screen
    [self resetMainDot];

}



# pragma mark 



-(void)trialStopped{

    [self showXO];
    [self performSelector:@selector(morphOrDropDots) withObject:self afterDelay:.1];
    allTimeTotalTrials++;
    [[NSUserDefaults standardUserDefaults] setInteger:allTimeTotalTrials forKey:@"allTimeTotalTrials"];
    
    //[self updateAchievements];

}

//-(void)countdownTimerLabel{
//
//    resetCounter*=1.10;
//
//    
//    //count up
//    [self timerDiffDisplay:resetCounter];
//    
//    if(resetCounter<=fabs(elapsed-timerGoal)){
//        [self performSelector:@selector(countdownTimerLabel) withObject:self afterDelay:0.0];
//    }else{
//        //[self timerGoalDisplay:0];
//        //[self timerMainDisplay:elapsed-timerGoal];
//        [self timerDiffDisplay:elapsed-timerGoal];
//        
//        
//        //show success label
//        //[self performSelector:@selector(showTrialInstruction) withObject:self afterDelay:0.0];
//        //drop dots or morph to levedots
//        //[self performSelector:@selector(morphOrDropDots) withObject:self afterDelay:1.5];
//
//        trialSequence=2;
//        
//        //pause before level reset animation
//        //[NSTimer scheduledTimerWithTimeInterval:.75 target:self selector:@selector(animateLevelReset) userInfo:nil repeats:NO];
//    }
//}


-(void)showXO{
    if([self isAccurate]){
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self displayXorO:YES];
        
    }
    else{
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self displayXorO:NO];
    }
}

-(void)displayXorO:(bool)showO{

    xView.alpha=1.0;
    oView.alpha=1.0;
    xView.tintColor=[self getForegroundColor:currentLevel];
    oView.tintColor=[self getForegroundColor:currentLevel];
    float w=screenWidth*.7;
    float y=(screenHeight-88)*.75-w/2.0;
    float x=screenWidth/2.0-w/2.0;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:.5
          initialSpringVelocity:.5
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         if([self isAccurate])oView.frame=CGRectMake( x, y, w, w);
                         else xView.frame=CGRectMake(x, y, w, w);
                     }
                     completion:^(BOOL finished){

//                         if(![self isAccurate])AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                     }];
    
}
-(void)xoViewOffScreen{
    //reset xoView
    float w=230;
    xView.alpha=1.0;
    oView.alpha=1.0;
    int y=-w;
    
    xView.frame=CGRectMake(screenWidth/2.0-w/2.0, y, w, w);
    oView.frame=CGRectMake(screenWidth/2.0-w/2.0, y, w, w);

}
-(void)morphOrDropDots{
    //[instructions update:@"" rightLabel:@"" color:[self getForegroundColor:currentLevel] animate:YES];
    [instructions slideOut:0];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         labelContainerBlur.alpha=0.0;
                     }
                     completion:^(BOOL finished){

                    }];
    
    
    [self checkLevelUp];
}

-(void)animateLevelReset{
    
    [instructions slideOut:0];

    float slideDownDuration=0.0;
    if(progressView.frame.origin.y==0)slideDownDuration=0.4;
    
    [UIView animateWithDuration:slideDownDuration
                          delay:0
         usingSpringWithDamping:.8
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         //slide progressview down
                         progressView.frame=CGRectMake(0, screenHeight-44, self.view.frame.size.width, progressView.frame.size.height);
                         TextArrow *sLabel=[stageLabels objectAtIndex:[self getCurrentStage]];
                         float y=sLabel.frame.origin.y;
                         progressView.dotsContainer.frame=CGRectMake(0,-y+15, screenWidth, progressView.dotsContainer.frame.size.height);
                         restartButton.center=CGPointMake(screenWidth*4/5.0, buttonYPos);

                     }
                     completion:^(BOOL finished){
                         [self.view sendSubviewToBack:progressView];
                         [self.view sendSubviewToBack:blob];
                         [self updateLife];
                         [self updateTimeDisplay:0];
                         

                          //fade in new counters
                          [UIView animateWithDuration:0.2
                                                delay:0.0
                                              options:UIViewAnimationOptionCurveLinear
                                           animations:^{
                                               counterLabel.alpha=0.0;
                                               instructions.alpha=1.0;
                                               counterGoalLabel.alpha=1.0;
                                           }
                                           completion:^(BOOL finished){
                                               //[instructions resetFrame];

                                               [instructions update:@"START" rightLabel:@"" color:[self getForegroundColor:currentLevel] animate:NO];
                                               [instructions slideIn:0];
                                               [self performSelector:@selector(resetTrialSequence) withObject:self afterDelay:0.1];
                                           }];
                          
                         
                     }];
 
    
}


-(void)setTrialSequence:(int)n{
    trialSequence=n;
}

-(void)resetTrialSequence{
    trialSequence=0;
    [self performSelector:@selector(instructionBounce) withObject:self afterDelay:10.0];
}

-(void)instructionBounce{

    if(trialSequence==0)
    {
        //[instructions update:@"START" rightLabel:@"PRESS VOLUME BUTTON" color:[self getForegroundColor:currentLevel] animate:NO];
        [instructions update:@"START" rightLabel:@"" color:[self getForegroundColor:currentLevel] animate:NO];
        instructions.rightLabel.frame=CGRectMake(-instructions.rightLabel.frame.size.height*.25,-instructions.rightLabel.frame.size.height*.05,
                                                 instructions.rightLabel.frame.size.width,instructions.rightLabel.frame.size.height);
        
        instructions.rightLabel.font=[UIFont fontWithName:@"DIN Condensed" size:screenHeight*.03];
 
        [instructions bounce];
        [self performSelector:@selector(instructionBounce) withObject:self afterDelay:10.0];
    }
    
}


# pragma mark Helpers

-(UIColor*) getBackgroundColor:(int)level {

    NSArray * backgroundColors = [[NSArray alloc] initWithObjects:
                                  [UIColor colorWithRed:255/255.0 green:215/255.0 blue:16/255.0 alpha:1],
                                  [UIColor colorWithRed:255/255.0 green:237/255.0 blue:144/255.0 alpha:1],
                                  [UIColor colorWithRed:255/255.0 green:66/255.0 blue:66/255.0 alpha:1],
                                  [UIColor colorWithRed:151/255.0 green:239/255.0 blue:229/255.0 alpha:1],
                                  
                                  [UIColor colorWithRed:240/255.0 green:255/255.0 blue:245/255.0 alpha:1],
                                  [UIColor colorWithRed:252/255.0 green:73/255.0 blue:108/255.0 alpha:1],//
                                  [UIColor colorWithRed:255/255.0 green:29/255.0 blue:111/255.0 alpha:1],//
                                  [UIColor colorWithRed:130/255.0 green:35/255.0 blue:57/255.0 alpha:1],//

                                  nil];
  
    
    int currentStage=floorf(level/TRIALSINSTAGE);
    int cl=currentStage%[backgroundColors count];
    UIColor *c=backgroundColors[cl];

    if(currentStage>=[backgroundColors count]){
        double hue = (level%10+level%6/2.0)/13.0;
        c=[UIColor colorWithHue:hue saturation:1.0 brightness:.4 alpha:1];
    }
    return c;
}

-(UIColor*) getForegroundColor:(int)level {
    
    NSArray * foregroundColor = [[NSArray alloc] initWithObjects:
                                 [UIColor colorWithRed:91/255.0 green:89/255.0 blue:87/255.0 alpha:1],
                                 [UIColor colorWithRed:53/255.0 green:150/255.0 blue:104/255.0 alpha:1],
                                  [UIColor colorWithRed:244/255.0 green:350/255.0 blue:210/255.0 alpha:1],
                                 [UIColor colorWithRed:237/255.0 green:21/255.0 blue:21/255.0 alpha:1],

                                 [UIColor colorWithRed:108/255.0 green:189/255.0 blue:181/255.0 alpha:1],
                                  [UIColor colorWithRed:107/255.0 green:45/255.0 blue:81/255.0 alpha:1],//
                                 [UIColor colorWithRed:61/255.0 green:222/255.0 blue:237/255.0 alpha:1],//
                                 [UIColor colorWithRed:247/255.0 green:62/255.0 blue:62/255.0 alpha:1],//

                                  nil];
    
    int currentStage=floorf(level/TRIALSINSTAGE);
    int cl=currentStage%[foregroundColor count];
    UIColor *c=foregroundColor[cl];
    
    if(currentStage>=[foregroundColor count]){
        double hue = (level%10+level%6/2.0)/13.0;
        c=[UIColor colorWithHue:hue saturation:.8 brightness:.7 alpha:1];
    }
    return c;
    
}





-(UIColor*) inverseColor:(UIColor*) color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r-.2 green:1.-g-.2 blue:1.-b-.2 alpha:a];
}



-(bool)isAccurate{
    //float accuracyP=100.0-fabs(elapsed-timerGoal)/(float)timerGoal*100.0;

    float diff=fabs(timerGoal-elapsed);
    
    if( diff<=[self getLevelAccuracy:currentLevel] ) return YES;
    else return NO;
//       
//    
//    if([self getLevel:currentLevel]<10 && diff<=.25) return YES;
//    else if([self getLevel:currentLevel]<30 && diff<=.5) return YES;
//    else if (diff<=1) return YES;
//    else return NO;
}

-(int)getAccuracyPercentage{
    float accuracyPercent;
    accuracyPercent=100.0-fabs(elapsed-timerGoal)/(float)timerGoal*100.0;

    if(accuracyPercent<0)accuracyPercent=0;
    
    return ceilf(accuracyPercent);
}


#pragma mark - SimpleLineGraph Data Source
///*
- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    if(graph.tag==0){
        return [self.trialData count];
    }
    else {
        return [self.lastNTrialsData count];
    }
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    if(graph.tag==0){
        
        if([self.trialData count]==0)return 0.0;
        //NSInteger i=[self.trialData count]-nPointsVisible+index; //show last nPoints
        float naccuracy=[[[self.trialData objectAtIndex:index] objectForKey:@"accuracy"] floatValue];
        //cap graph
        if(naccuracy>1)naccuracy=1;
        else if (naccuracy<-1)naccuracy=-1;
        return naccuracy;
    }
    else {
        if([self.lastNTrialsData count]==0)return 0.0;
        //NSInteger i=[self.trialData count]-nPointsVisible+index; //show last nPoints
        float naccuracy=[[[self.lastNTrialsData objectAtIndex:index] objectForKey:@"accuracy"] floatValue];
        //cap graph
        if(naccuracy>1)naccuracy=1;
        else if (naccuracy<-1)naccuracy=-1;
        return naccuracy;
        
    }
}




#pragma mark - SimpleLineGraph Delegate
- (NSString *)popUpSuffixForlineGraph:(BEMSimpleLineGraphView *)graph {
    return @"";
}

- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
    return 3;
}

- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
    if(graph.tag==0) return [self.trialData count];
    else return [self.lastNTrialsData count];
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index {
    return @"";
}

- (void)lineGraph:(BEMSimpleLineGraphView *)graph didTouchGraphWithClosestIndex:(NSInteger)index {
}

- (void)lineGraph:(BEMSimpleLineGraphView *)graph didReleaseTouchFromGraphWithClosestIndex:(CGFloat)index {
}

- (void)lineGraphDidFinishLoading:(BEMSimpleLineGraphView *)graph {
    
    if(graph.tag==0){
        [self updateStats];
        [self.myGraph drawPrecisionOverlay:[self getLevelAccuracy:currentLevel]];
        
        //last dot
        self.myGraph.lastDot.alpha=0.0;
        [UIView animateWithDuration:0.2 delay:.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.myGraph.lastDot.alpha=1.0;
        } completion:nil];

          self.myGraph.lastPointLabel.text=[NSString stringWithFormat:@"%.03f SEC",([[[self.trialData lastObject] objectForKey:@"accuracy"] floatValue])];
    }
    
    
    else{
        [self.allGraph drawPrecisionOverlay:[self getLevelAccuracy:currentLevel]];
        
        //last dot
        self.allGraph.lastDot.alpha=0.0;
        [UIView animateWithDuration:0.2 delay:.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.allGraph.lastDot.alpha=1.0;
        } completion:nil];
        
        self.allGraph.lastPointLabel.text=[NSString stringWithFormat:@"%.03f SEC",([[[self.lastNTrialsData lastObject] objectForKey:@"accuracy"] floatValue])];
    }
    
    
    
}




#pragma mark - ViewController Delegate

- (void)viewWillAppear:(BOOL)animated
{

    
    [self loadTrialData];
    [self loadLevelProgress];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{

    if(viewLoaded==false){
        //set view offscreen for bounce in
        progressView.frame=CGRectMake(0, screenHeight, progressView.frame.size.width, progressView.frame.size.height);
        trophyButton.alpha=0;
        medalButton.alpha=0;
        highScoreLabel.alpha=0;
        bestLabel.alpha=0;
        restartButton.alpha=0;
        
        [self.view bringSubviewToFront:progressView];
        [self performSelector:@selector(setupDots) withObject:self afterDelay:.5];
    }
    
//    [UIView animateWithDuration:0.8
//                          delay:0.4
//         usingSpringWithDamping:.8
//          initialSpringVelocity:1.0
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^{
//                         progressView.frame=CGRectMake(0, screenHeight-44, progressView.frame.size.width, progressView.frame.size.height);
//                         if([stageLabels count]>0){
//                             TextArrow *sLabel=[stageLabels objectAtIndex:[self getCurrentStage]];
//                             float y=sLabel.frame.origin.y;
//                             progressView.dotsContainer.frame=CGRectMake(0,-y+15, screenWidth, progressView.dotsContainer.frame.size.height);
//                         }
//                     }
//                     completion:^(BOOL finished){
//                         [self.view sendSubviewToBack:progressView];
//                         [self.view sendSubviewToBack:blob];
//                         //[self.myGraph reloadGraph];
//
//                     }];

    if(showIntro){
        [self performSelector:@selector(showIntroView) withObject:self afterDelay:1.5];
    }
    
    //viewLoaded=true; //moved to setupDots

    
//    if(trialSequence==0)[instructions updateText:@"START" animate:YES];



   [super viewDidAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
    
   // Return YES for supported orientations
  // return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


-(void)authenticateLocalPlayer{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else{
            if ([GKLocalPlayer localPlayer].authenticated) {
                _gameCenterEnabled = YES;
                
                // Get the default leaderboard identifier.
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    if (error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    else{
                        _leaderboardIdentifier = leaderboardIdentifier;
                    }
                }];
            }
            
            else{
                _gameCenterEnabled = NO;
            }
        }
    };
}



@end
