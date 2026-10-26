// Chrono.m — v2
// Chronomètre flottant + onglet Réglages (taille, couleur, image de fond, texte)
// Frameworks requis : UIKit, Foundation, PhotosUI, QuartzCore

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import <QuartzCore/QuartzCore.h>

#define kScale @"chrono_scale"
#define kColor @"chrono_color"
#define kText  @"chrono_text"

#pragma mark - Helpers

static UIWindow *CRKeyWindow(void) {
    UIWindow *fallback = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ws.windows) {
            if (w.isKeyWindow) return w;
        }
        if (!fallback) fallback = ws.windows.firstObject;
    }
    return fallback;
}

static UIViewController *CRTopVC(void) {
    UIViewController *vc = CRKeyWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static NSString *CRImagePath(void) {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [dir stringByAppendingPathComponent:@"chrono_bg.jpg"];
}

static NSString *CRFormat(NSTimeInterval t) {
    int cs = (int)(t * 100) % 100;
    int s  = (int)t % 60;
    int m  = ((int)t / 60) % 60;
    int h  = (int)t / 3600;
    if (h > 0) return [NSString stringWithFormat:@"%d:%02d:%02d.%02d", h, m, s, cs];
    return [NSString stringWithFormat:@"%02d:%02d.%02d", m, s, cs];
}

#pragma mark - Chrono

@interface CRChrono : NSObject <PHPickerViewControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIImageView *bg;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIColorWell *well;
@property (nonatomic, strong) UITextField *field;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) CFTimeInterval startTime;
@property (nonatomic) NSTimeInterval accumulated;
@property (nonatomic) BOOL running;
@property (nonatomic) CGFloat scale;
@property (nonatomic, strong) UIColor *color;
+ (instancetype)shared;
- (void)installWhenReady;
@end

@implementation CRChrono

+ (instancetype)shared {
    static CRChrono *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [CRChrono new]; });
    return s;
}

#pragma mark Install

- (void)installWhenReady {
    UIWindow *w = CRKeyWindow();
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self installWhenReady];
        });
        return;
    }
    [self loadPrefs];
    [self buildCardInWindow:w];
    [self buildPanelInWindow:w];
    [self applyStyle];
}

- (void)loadPrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    CGFloat sc = [d floatForKey:kScale];
    self.scale = (sc >= 0.4 && sc <= 1.4) ? sc : 1.0;
    NSData *cd = [d dataForKey:kColor];
    UIColor *c = cd ? [NSKeyedUnarchiver unarchivedObjectOfClass:UIColor.class fromData:cd error:nil] : nil;
    self.color = c ?: UIColor.whiteColor;
}

- (void)savePrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d setFloat:self.scale forKey:kScale];
    NSData *cd = [NSKeyedArchiver archivedDataWithRootObject:self.color requiringSecureCoding:YES error:nil];
    if (cd) [d setObject:cd forKey:kColor];
    [d setObject:self.field.text ?: @"" forKey:kText];
}

#pragma mark UI helpers

- (UIButton *)buttonTitle:(NSString *)title frame:(CGRect)f action:(SEL)a {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = f;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    b.layer.cornerRadius = 8;
    [b addTarget:self action:a forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UILabel *)labelText:(NSString *)t frame:(CGRect)f size:(CGFloat)sz {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.textColor = UIColor.whiteColor;
    l.font = [UIFont boldSystemFontOfSize:sz];
    return l;
}

#pragma mark Card (le chrono)

- (void)buildCardInWindow:(UIWindow *)w {
    self.card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 130)];
    self.card.center = CGPointMake(w.bounds.size.width / 2, 140);
    self.card.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.card.layer.cornerRadius = 16;
    self.card.clipsToBounds = YES;

    self.bg = [[UIImageView alloc] initWithFrame:self.card.bounds];
    self.bg.contentMode = UIViewContentModeScaleAspectFill;
    self.bg.clipsToBounds = YES;
    self.bg.image = [UIImage imageWithContentsOfFile:CRImagePath()];
    [self.card addSubview:self.bg];

    self.textLabel = [self labelText:[NSUserDefaults.standardUserDefaults stringForKey:kText] frame:CGRectMake(8, 62, 204, 20) size:13];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    [self.card addSubview:self.textLabel];

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 10, 204, 50)];
    self.timeLabel.text = CRFormat(0);
    self.timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:36 weight:UIFontWeightSemibold];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.adjustsFontSizeToFitWidth = YES;
    self.timeLabel.minimumScaleFactor = 0.5;
    [self.card addSubview:self.timeLabel];

    self.startBtn = [self buttonTitle:@"Start" frame:CGRectMake(12, 88, 100, 32) action:@selector(toggle)];
    [self.card addSubview:self.startBtn];
    [self.card addSubview:[self buttonTitle:@"Reset" frame:CGRectMake(118, 88, 58, 32) action:@selector(reset)]];
    [self.card addSubview:[self buttonTitle:@"⚙︎" frame:CGRectMake(182, 88, 30, 32) action:@selector(openSettings)]];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.card addGestureRecognizer:pan];

    [w addSubview:self.card];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    CGPoint t = [g translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [g setTranslation:CGPointZero inView:v.superview];
}

#pragma mark Panel (réglages)

- (void)buildPanelInWindow:(UIWindow *)w {
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 316)];
    self.panel.center = CGPointMake(w.bounds.size.width / 2, w.bounds.size.height / 2);
    self.panel.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    self.panel.layer.cornerRadius = 16;
    self.panel.hidden = YES;

    UILabel *title = [self labelText:@"Réglages" frame:CGRectMake(0, 12, 280, 24) size:17];
    title.textAlignment = NSTextAlignmentCenter;
    [self.panel addSubview:title];

    [self.panel addSubview:[self labelText:@"Taille" frame:CGRectMake(16, 48, 200, 20) size:14]];
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(16, 72, 248, 30)];
    self.slider.minimumValue = 0.4;
    self.slider.maximumValue = 1.4;
    self.slider.value = self.scale;
    [self.slider addTarget:self action:@selector(sizeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:self.slider];

    [self.panel addSubview:[self labelText:@"Couleur" frame:CGRectMake(16, 112, 150, 20) size:14]];
    self.well = [[UIColorWell alloc] initWithFrame:CGRectMake(216, 106, 48, 36)];
    self.well.selectedColor = self.color;
    self.well.supportsAlpha = NO;
    [self.well addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:self.well];

    [self.panel addSubview:[self labelText:@"Texte" frame:CGRectMake(16, 156, 200, 20) size:14]];
    self.field = [[UITextField alloc] initWithFrame:CGRectMake(16, 180, 248, 34)];
    self.field.text = [NSUserDefaults.standardUserDefaults stringForKey:kText];
    self.field.textColor = UIColor.whiteColor;
    self.field.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    self.field.layer.cornerRadius = 8;
    self.field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 34)];
    self.field.leftViewMode = UITextFieldViewModeAlways;
    self.field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Texte sous le chrono"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
    self.field.returnKeyType = UIReturnKeyDone;
    self.field.delegate = self;
    [self.field addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.panel addSubview:self.field];

    [self.panel addSubview:[self buttonTitle:@"Choisir une image" frame:CGRectMake(16, 226, 248, 34) action:@selector(pickImage)]];
    [self.panel addSubview:[self buttonTitle:@"Retirer l'image" frame:CGRectMake(16, 268, 120, 34) action:@selector(removeImage)]];
    [self.panel addSubview:[self buttonTitle:@"Fermer" frame:CGRectMake(144, 268, 120, 34) action:@selector(closeSettings)]];

    [w addSubview:self.panel];
}

- (void)openSettings {
    UIWindow *w = CRKeyWindow();
    if (w && self.panel.superview != w) {
        [w addSubview:self.card];
        [w addSubview:self.panel];
    }
    [self.panel.superview bringSubviewToFront:self.panel];
    self.panel.hidden = NO;
}

- (void)closeSettings {
    [self.field resignFirstResponder];
    self.panel.hidden = YES;
    [self savePrefs];
}

#pragma mark Réglages : actions

- (void)applyStyle {
    self.card.transform = CGAffineTransformMakeScale(self.scale, self.scale);
    self.timeLabel.textColor = self.color;
    self.textLabel.textColor = self.color;
}

- (void)sizeChanged:(UISlider *)s {
    self.scale = s.value;
    [self applyStyle];
}

- (void)colorChanged:(UIColorWell *)w {
    if (w.selectedColor) self.color = w.selectedColor;
    [self applyStyle];
}

- (void)textChanged:(UITextField *)f {
    self.textLabel.text = f.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)f {
    [f resignFirstResponder];
    return YES;
}

- (void)removeImage {
    [NSFileManager.defaultManager removeItemAtPath:CRImagePath() error:nil];
    self.bg.image = nil;
}

#pragma mark Image (import)

- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.filter = PHPickerFilter.imagesFilter;
    cfg.selectionLimit = 1;
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    p.delegate = self;
    [CRTopVC() presentViewController:p animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *r = results.firstObject;
    if (!r || ![r.itemProvider canLoadObjectOfClass:UIImage.class]) return;
    [r.itemProvider loadObjectOfClass:UIImage.class completionHandler:^(id obj, NSError *err) {
        if (![obj isKindOfClass:UIImage.class]) return;
        UIImage *img = (UIImage *)obj;
        NSData *d = UIImageJPEGRepresentation(img, 0.85);
        [d writeToFile:CRImagePath() atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{ self.bg.image = img; });
    }];
}

#pragma mark Chrono logique

- (NSTimeInterval)elapsed {
    return self.accumulated + (self.running ? CACurrentMediaTime() - self.startTime : 0);
}

- (void)toggle {
    if (self.running) {
        self.accumulated += CACurrentMediaTime() - self.startTime;
        self.running = NO;
        [self.timer invalidate];
        self.timer = nil;
        [self.startBtn setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        self.startTime = CACurrentMediaTime();
        self.running = YES;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(tick) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.startBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }
}

- (void)tick {
    self.timeLabel.text = CRFormat([self elapsed]);
}

- (void)reset {
    self.accumulated = 0;
    self.startTime = CACurrentMediaTime();
    self.timeLabel.text = CRFormat(0);
}

@end

#pragma mark - Entrée du dylib

__attribute__((constructor))
static void CRInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CRChrono shared] installWhenReady];
    });
}

