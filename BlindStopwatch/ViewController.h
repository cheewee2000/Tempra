//
//  ViewController.h
//  VolumeSnap
//
//  Created by Randall Brown on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMSimpleLineGraphView.h"
#import "Dots.h"
#import "TextArrow.h"
#import "Level.h"
#import "LevelProgressView.h"
#import <GameKit/GameKit.h>
#import "BFPaperButton.h"
#import "MachTimer.h"
#import "VolumeTrigger.h"

@interface ViewController : UIViewController <GKGameCenterControllerDelegate, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>

{

    int screenWidth,screenHeight;
    float safeBottomInset;//modern screens: home-indicator padding
    VolumeTrigger *volumeTrigger;
    int trialSequence;
    int lastStage;

    int allTimeTotalTrials;
    
    #pragma mark - timing
    //NSTimeInterval startTime;
    NSTimeInterval elapsed;
    NSTimeInterval timerGoal;
    NSString *timeValuesFile;
    NSString *allTrialDataFile;
    NSString *lastNTrialDataFile;

    MachTimer* aTimer;
    float touchX,touchY;
    NSTimeInterval touchStartTime;
    NSTimeInterval touchLength;
    
    #pragma mark - points
    float best;
    float experiencePoints;
    int currentLevel;
    int starBank;
    
    int life;
    float start;
    CGPoint offset;
    BOOL practicing;
    int nHeartsReplenished;
    int currentStreak;
    int nStarsEarned;
    int nLifeEarned;
    
    
    #pragma mark - progressview
    LevelProgressView *progressView;
    UIVisualEffectView *gameOverBlur;

    UILabel *bestLabel;
    UILabel *highScoreLabel;
    NSMutableArray *dots;
    Dots *bestLevelDot;
    
    float buttonYPos;
    
    BFPaperButton *restartExpandButton;
    UIButton *restartButton;
    UIButton *playButton;
    UIButton *trophyButton;
    UIButton *medalButton;
    
    NSMutableArray * stageLabels;
    int resetCountdown;

    UIView *labelContainer;
    UILabel *counterLabel;
    UILabel *counterGoalLabel;
    UILabel *goalPrecision;
    NSMutableArray *hearts;

    IBOutlet UILabel *differencelLabel;
    UILabel *questionMark;
    
    
    #pragma mark - Labels
    TextArrow* instructions;
    TextArrow* levelAlert;
    NSMutableArray * levelArrows;
    IBOutlet UILabel *nextLevelLabel;

    
    #pragma mark - Buttons

    UIButton *nextButton;
    UIButton *shareButton;
    
    
    #pragma mark - Blob
    UIView *blob;
    UIVisualEffectView *blobBlur;

    Dots *mainDot;
    NSArray *satellites;
    
    UIImageView * xView;
    UIImageView * oView;
    UIVisualEffectView *labelContainerBlur;

    NSInteger nPointsVisible;

    
    #pragma mark - stats
    UIView *stats;
    UILabel *averageTime;
    UILabel *accuracy;
    UILabel *precision;
    UILabel* precisionUnit;
    UILabel* averageUnit;
    UILabel* accuracyUnit;
    UILabel* averageLabel;
    UILabel* accuracyLabel;
    UILabel *precisionLabel;
    UILabel *myGraphLabel;

    
    UIView *allStats;
    UILabel *allAverageTime;
    UILabel *allAccuracy;
    UILabel *allPrecision;
    UILabel* allPrecisionUnit;
    UILabel* allAverageUnit;
    UILabel* allAccuracyUnit;
    UILabel* allAverageLabel;
    UILabel* allAccuracyLabel;
    UILabel *allPrecisionLabel;
    UILabel *allGraphLabel;
    
    #pragma mark - intro
    UIView *intro;
    UILabel* introTitle;
    TextArrow* introArrow;
    UILabel* introSubtitle;
    UILabel* introParagraph;
    UILabel* credits;

    UIButton* feedbackButton;
    BOOL showIntro;
    
    
    BOOL viewLoaded;
    
}


//void drawLine(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
//@property (weak, nonatomic) IBOutlet UILabel *screenLabel;
//@property (assign, nonatomic) NSInteger indexNumber;

@property (strong, nonatomic) NSMutableArray *trialData;
@property (strong, nonatomic) NSMutableArray *allTrialData;
@property (strong, nonatomic) NSMutableArray *lastNTrialsData;
@property (strong, nonatomic) NSMutableArray *levelData;

//@property (strong, nonatomic) NSMutableArray *ArrayOfDates;
//@property (strong, nonatomic) NSMutableDictionary *TimeData;
//@property (strong, nonatomic) IBOutlet UILabel *labelValues;
//@property (strong, nonatomic) IBOutlet UILabel *labelDates;

@property BOOL gameCenterEnabled;
@property NSString *leaderboardIdentifier;

@property (strong, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph;
@property (strong, nonatomic) IBOutlet BEMSimpleLineGraphView *allGraph;


//@property (weak, nonatomic) IBOutlet UISegmentedControl *graphColorChoice;
//@property (weak, nonatomic) IBOutlet UIStepper *graphObjectIncrement;

@end
