// Chrono.m — v4
//
// Chrono en 3 cases (00h 15m 16s) + compteur FPS + résolution du jeu réglable.
//
//   1 clic sur le chrono  -> lance
//   1 clic                -> pause
//   1 clic en pause       -> reset
//   Appui long            -> réglages
//   Glisser               -> déplacer
//
// Frameworks : Foundation, UIKit, QuartzCore, PhotosUI, CoreGraphics

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#define kScale   @"chrono4_scale"
#define kWidth   @"chrono4_width"
#define kSat     @"chrono4_saturation"
#define kOpacity @"chrono4_bg_opacity"
#define kRes     @"chrono4_resolution"
#define kFPS     @"chrono4_show_fps"
#define kHideSB  @"chrono4_hide_statusbar"
#define kRunC    @"chrono4_color_run"
#define kPauseC  @"chrono4_color_pause"
#define kBgC     @"chrono4_color_bg"
#define kTextC   @"chrono4_color_text"
#define kText    @"chrono_text"

// Dimensions des cases
#define kPillH   34.0
#define kGap     6.0
#define kTextH   22.0
#define kFpsH    24.0
#define kFpsW    84.0
#define kBoxH    (kTextH + 2.0 + kPillH + 4.0 + kFpsH)

// Fond du menu : capture du profil TikTok (JPEG réduit, encodé en base64)
static const char kPanelBgB64[] =
    "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"
    "tvvbAsrcejgtgq+CVdNdvHxNvd8O/Lu25myzDojZOMqXVCu6EIzcn+1i3s/y57oqeJ+b58u8OUmknJtLuTfcBZRwq4SgrqLd3kTj"
    "wpPdwS5bLxW5FzalRdHaEFGUFNJOWz/B818DQ5ybTcpNrubfcYk3Jtybbfi3uBb5dMJZWXYsXjlWocFa4tpJ/vcub8uR4swK+Oca"
    "q5ycb64uKbbjFx3afwfLcrFOaaanJNLZPd8jClKLbjJpvv2e24FhlRhHT2qqo8McmceNbvZctuZV3f2Nn+V/yNm7SaTez71vyI+Z"
    "Yq8Wb8WuFfiBShAAZAAGAAB0uh9HOkeRhRzdJ6yum7dcVeQq3LZtc+fnuWfyb6b/AHjK/wDO/wD7HH1Z+ZTWq6sq+uC7oxskkvw3"
    "PftTUPv2V/rS/UDrfk303+8ZX/nf/wBjl9a0nO0jMVOow4b7I9Z9NS3Tb57r3pmr2pqH37K/1pfqaL77sianfbZbJLbecnJ7fiB1"
    "WLl9C44lKydOz5XqEVZKM3s5bc2vneZIhqfQqFcq4YGpxhL6UVa0n8VxnEgDu+nOlY1OFo3s9ZG2S2oQtvlPZNR4Uk20u/wK19Au"
    "kT78SL25f20f1NXSPpNDWcDTcerHnRLDjtxue/E9kt1y5dxT+1dQ+/5X+tL9QLz5AdIfucP9aH6j5A9IvucP9aH6lH7V1D7/AJX+"
    "tL9R7V1D7/lf60v1Al6TF03X12bKcXwtb+K3L2uyMY85pL3s4xybk5Ntt89w5N97bM5pmcuzS4rp05cOwu1HErTUr4b+Se5W3Z2P"
    "bVdGNq3cGlvy3KADpwm3GXnbAADRxNmPfbjXwvoslXbXJSjKL2aZN1rW83XMqN+dYpOEeGMYraMV47L395XAAAAAAAAAAAAAAAAA"
    "AAAAAAEjCxnlXqHdFc5PyRHLuhLT9MdrX7SfP8X3IDzm5ax5QxseMW47bry9xqeo1xezhJtd+z5EHicYuyT3snvs/d4s0gWntKr6"
    "k/yHtKr6k/yKsAWntKr6k/yHtKr6k/yKsAWntKr6k/yHtKr6k/yKs91QdtsYJ7OT2AvK5qyEZx7pLdGi7Oqqm485Nd/D4EbJjbiU"
    "xjXc3W91tts0QALVahGW6hB8Xgm+824eRDNqnj3xSl37Lx/3RTG5WSjKN8HtOL5/Hz/EDzk0Sx75Vy8O5+aNRdahCOZgQyq1zit3"
    "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"
    "aW8U3FPv2fetzxRk246nGtrhntupRUly7nz8QLKenRhPsztk4PMjVyS7mu/4/kea8LCs6nbtCVtzo748ny+d3e/u/MhS1DKlYpyt"
    "bl1it32X0ktkzxDKuhwcM9uCzrY8lyly5/kgJ9OnUdVV19yhK1SfG7IxUNm0vmvm+aKokwz8iFfApprns3FNx379m1y/AjAAAAAA"
    "AAAAAAAAAAAbce+zGtVlb2fivBlx/wBm1Wr6l0V+K/VFEZjKUJKUW1JdzQEq+i7F+bdDjr8JeH4PwNPBGX9nNf5ZcmWGNq74eDKh"
    "xru4kv5o3PDwcz51FihJ+EX/AEYFPKEofSi18UeSzlpWVX/ZWxa+LRreHnp/2al/CwIB6jXOX0YtrzJscPPf/u1H+FG2Ok5Fj/bX"
    "JL4uQFc4RinxTTflHn+Z1/RHV63jrT75KNkG3U3+8nz2+JTrHwMLnbNTmvCXP8iBn5deTZGVdXBw/veLL0vNZzDPU041K4l9ZxMp"
    "4rsajxccHDm9tiDk5NOJjyuyLFCuC5t/09586p17VKK1CGZZwru4tpfzIuXm5ObNSyb52td3E+S+CN51494jdyRwtp2tOzZqudLU"
    "dQtyZLZTfzY+UV3IhgHNM5nLuiIiMQAAhIAAABtjj2SW+23xA1A39ls84+o7LZ5x9QNAN/ZbPOPqOy2ecfUDQDf2Wzzj6jstnnH1"
    "A0A39ls84+o7LZ5x9QNAN/ZbPOPqOy2ecfUDQDf2Wzzj6jstnnH1A0A39ls84+o7LZ5x9QNAN/ZbPOPqOy2ecfUDQDf2Wzzj6jst"
    "nnH1A0A39ls84+o7LZ5x9QNAN/ZbPOPqOy2ecfUDQDf2Wzzj6jstnnH1A0A39ls84+o7LZ5x9QNAN/ZbPOPqOy2ecfUDQDf2Wzzj"
    "6jstnnH1A0A3PGsS7k/gzS009mtmAAAAAABvt3AASK83JrW0bp7eTe5uWq5S/fi/jFEEATXquW/34r4RRpsy8i36d02vLfY0AAAA"
    "AAAAAAAAAAAlYtS2433+BJPFP9lD4HuO3EuLfbfnt37AZ4ZcDlwvhT2b25b+Rgvq1pXsK/aef1faq9/m1778EtvHbbvKOzg6yXVc"
    "br3+bxbcTXhvt4geTMoyjtxRa4lut1tuvM7XNwdtEu0pW40p4mLC6NcbE7Vam5Wbx7+6W34IgvAx54uPk3RtyVj6XC9UO2Xzm5tf"
    "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"
    "2s/iY7Tf9tZ/Ex0zuVfj9u/2fkzVfk048XK62EF73/Q4R32vvsm//uZrbbe7HTRb1Lbaq11nVnnSVVW8aIvfn3yfmyqANIjDzNTU"
    "tqW5re4ACVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH/2Q==";

typedef NS_ENUM(NSInteger, CRState) { CRStateIdle, CRStateRunning, CRStatePaused };

#pragma mark - Compteur d'images (FPS)

// Compte les images réellement présentées par le jeu (couche Metal).
static int64_t gFrames = 0;
static id (*orig_nextDrawable)(id, SEL) = NULL;

static id hook_nextDrawable(id self, SEL _cmd) {
    __atomic_fetch_add(&gFrames, 1, __ATOMIC_RELAXED);
    return orig_nextDrawable(self, _cmd);
}

static void CRHookFrames(void) {
    Class cls = NSClassFromString(@"CAMetalLayer");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, NSSelectorFromString(@"nextDrawable"));
    if (!m || orig_nextDrawable) return;
    orig_nextDrawable = (id (*)(id, SEL))method_getImplementation(m);
    method_setImplementation(m, (IMP)hook_nextDrawable);
}

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

static UIViewController *CRTop(UIViewController *vc) {
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static NSString *CRImagePath(void) {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [dir stringByAppendingPathComponent:@"chrono_bg.jpg"];
}

static UIColor *CRLoadColor(NSString *key, UIColor *def) {
    NSData *d = [NSUserDefaults.standardUserDefaults dataForKey:key];
    UIColor *c = d ? [NSKeyedUnarchiver unarchivedObjectOfClass:UIColor.class fromData:d error:nil] : nil;
    return c ?: def;
}

static void CRSaveColor(NSString *key, UIColor *c) {
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:c requiringSecureCoding:YES error:nil];
    if (d) [NSUserDefaults.standardUserDefaults setObject:d forKey:key];
}

#pragma mark - Classes

@interface CRChrono : NSObject <PHPickerViewControllerDelegate, UITextFieldDelegate>
+ (instancetype)shared;
- (void)installWhenReady;
- (void)layoutChanged;
- (BOOL)capturesPoint:(CGPoint)p;
@property (nonatomic, readonly) UIViewController *gameRootVC;
@property (nonatomic) BOOL hideStatusBar;
@end

// Fenêtre par-dessus le jeu : les touches passent au jeu partout sauf sur le chrono.
@interface CROverlayWindow : UIWindow
@property (nonatomic) BOOL allowKey;
@end

@implementation CROverlayWindow
- (BOOL)canBecomeKeyWindow { return self.allowKey; }
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)e {
    return [[CRChrono shared] capturesPoint:p];
}
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v = [super hitTest:p withEvent:e];
    if (v == nil || v == self || v == self.rootViewController.view || v.tag == 7001) return nil;
    return v;
}
@end

@interface CRRootVC : UIViewController
@end

@implementation CRRootVC
- (void)loadView {
    UIView *v = [UIView new];
    v.backgroundColor = UIColor.clearColor;
    self.view = v;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
- (BOOL)shouldAutorotate { return YES; }

// Cette fenêtre ne doit jamais changer l'apparence du jeu (barre d'état, barre home...)
- (BOOL)prefersStatusBarHidden {
    if ([CRChrono shared].hideStatusBar) return YES;
    UIViewController *g = [CRChrono shared].gameRootVC;
    return g ? g.prefersStatusBarHidden : NO;
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    UIViewController *g = [CRChrono shared].gameRootVC;
    return g ? g.preferredStatusBarStyle : UIStatusBarStyleDefault;
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation { return UIStatusBarAnimationNone; }
- (BOOL)prefersHomeIndicatorAutoHidden {
    UIViewController *g = [CRChrono shared].gameRootVC;
    return g ? g.prefersHomeIndicatorAutoHidden : NO;
}
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    UIViewController *g = [CRChrono shared].gameRootVC;
    return g ? g.preferredScreenEdgesDeferringSystemGestures : UIRectEdgeNone;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[CRChrono shared] layoutChanged];
}
@end

#pragma mark - Chrono

@implementation CRChrono {
    UIWindow *_gameWindow;
    CROverlayWindow *_overlay;
    CRRootVC *_rootVC;

    UIView *_box;              // texte + cases + FPS
    UILabel *_textLabel;       // texte, au-dessus et hors du chrono
    UIView *_row;              // la rangée des 3 cases
    NSArray<UIView *> *_pills; // cases : subviews = [image, voile, label]
    UIView *_fpsPill;          // case FPS : subviews = [voile, label]
    UILabel *_fpsLabel;

    UIView *_panel;
    UIImageView *_panelBg;
    NSArray<UIScrollView *> *_pages;
    NSArray<UIButton *> *_tabButtons;
    UIScrollView *_textPage;
    NSInteger _tab;
    UILabel *_satValue;
    UILabel *_opValue;
    UITextField *_field;

    NSTimer *_timer;
    CFTimeInterval _startTime;
    NSTimeInterval _accumulated;
    CRState _state;

    NSTimer *_fpsTimer;
    int64_t _lastFrames;
    CFTimeInterval _lastFpsTime;

    NSTimer *_resTimer;
    NSMapTable *_origScale;

    CGFloat _scale;
    CGFloat _width;
    CGFloat _saturation;
    CGFloat _bgOpacity;
    NSInteger _resMode;        // 0 Bas, 1 Normal, 2 2K, 3 4K
    BOOL _showFPS;
    BOOL _hideStatusBar;
    UIColor *_runColor;
    UIColor *_pauseColor;
    UIColor *_bgColor;
    UIColor *_textColor;
    NSString *_text;
    BOOL _editing;
}

+ (instancetype)shared {
    static CRChrono *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [CRChrono new]; });
    return s;
}

- (UIViewController *)gameRootVC { return _gameWindow.rootViewController; }
- (BOOL)hideStatusBar { return _hideStatusBar; }
- (void)setHideStatusBar:(BOOL)h {
    _hideStatusBar = h;
    [_rootVC setNeedsStatusBarAppearanceUpdate];
}

#pragma mark Install

- (void)installWhenReady {
    UIWindow *w = CRKeyWindow();
    if (!w || !w.windowScene) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self installWhenReady];
        });
        return;
    }
    _gameWindow = w;
    [self loadPrefs];

    _overlay = [[CROverlayWindow alloc] initWithWindowScene:w.windowScene];
    _overlay.windowLevel = UIWindowLevelAlert + 100;
    _overlay.backgroundColor = UIColor.clearColor;
    _rootVC = [CRRootVC new];
    _overlay.rootViewController = _rootVC;
    _overlay.hidden = NO;

    [self buildBox];
    [self buildPanel];
    [self applyStyle];
    [self applySaturation];
    [self applyResolution];
    [self updateFPS];
    [_rootVC setNeedsStatusBarAppearanceUpdate];
}

- (void)loadPrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    float sc = [d floatForKey:kScale];
    _scale = (sc >= 0.4 && sc <= 1.6) ? sc : 1.0;
    float wd = [d floatForKey:kWidth];
    _width = (wd >= 120 && wd <= 420) ? wd : 192;
    float sat = [d objectForKey:kSat] ? [d floatForKey:kSat] : 50;
    _saturation = MAX(1, MIN(100, sat));
    _bgOpacity = [d objectForKey:kOpacity] ? [d floatForKey:kOpacity] : 0.88;
    NSInteger rm = [d objectForKey:kRes] ? [d integerForKey:kRes] : 1;
    _resMode = MAX(0, MIN(3, rm));
    _showFPS = [d objectForKey:kFPS] ? [d boolForKey:kFPS] : YES;
    _hideStatusBar = [d objectForKey:kHideSB] ? [d boolForKey:kHideSB] : YES;
    _text = [d stringForKey:kText] ?: @"";
    _runColor   = CRLoadColor(kRunC,   UIColor.whiteColor);
    _pauseColor = CRLoadColor(kPauseC, [UIColor colorWithRed:1.00 green:0.69 blue:0.13 alpha:1]);
    _bgColor    = CRLoadColor(kBgC,    UIColor.blackColor);
    _textColor  = CRLoadColor(kTextC,  UIColor.whiteColor);
}

- (void)savePrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d setFloat:_scale forKey:kScale];
    [d setFloat:_width forKey:kWidth];
    [d setFloat:_saturation forKey:kSat];
    [d setFloat:_bgOpacity forKey:kOpacity];
    [d setInteger:_resMode forKey:kRes];
    [d setBool:_showFPS forKey:kFPS];
    [d setBool:_hideStatusBar forKey:kHideSB];
    [d setObject:_text ?: @"" forKey:kText];
    CRSaveColor(kRunC, _runColor);
    CRSaveColor(kPauseC, _pauseColor);
    CRSaveColor(kBgC, _bgColor);
    CRSaveColor(kTextC, _textColor);
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

- (UISlider *)sliderMin:(float)mn max:(float)mx value:(float)v frame:(CGRect)f action:(SEL)a {
    UISlider *s = [[UISlider alloc] initWithFrame:f];
    s.minimumValue = mn;
    s.maximumValue = mx;
    s.value = v;
    [s addTarget:self action:a forControlEvents:UIControlEventValueChanged];
    return s;
}

#pragma mark Le chrono (3 cases)

- (void)buildBox {
    UIView *root = _rootVC.view;

    _box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _width, kBoxH)];
    _box.tag = 7001;
    _box.center = CGPointMake(_overlay.bounds.size.width / 2, 80);
    [root addSubview:_box];

    // Texte : au-dessus du chrono, en dehors
    _textLabel = [self labelText:_text frame:CGRectMake(0, 0, _width, kTextH) size:14];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.adjustsFontSizeToFitWidth = YES;
    _textLabel.minimumScaleFactor = 0.6;
    _textLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    _textLabel.layer.shadowOpacity = 0.9;
    _textLabel.layer.shadowRadius = 2;
    _textLabel.layer.shadowOffset = CGSizeMake(0, 1);
    [_box addSubview:_textLabel];

    // Rangée des 3 cases : 00h  15m  16s
    _row = [[UIView alloc] initWithFrame:CGRectMake(0, kTextH + 2, _width, kPillH)];
    [_box addSubview:_row];

    UIImage *img = [UIImage imageWithContentsOfFile:CRImagePath()];
    NSMutableArray *pills = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        UIView *p = [UIView new];
        p.layer.cornerRadius = 8;
        p.clipsToBounds = YES;

        UIImageView *iv = [UIImageView new];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.image = img;

        UIView *tint = [UIView new];

        UILabel *l = [UILabel new];
        l.textAlignment = NSTextAlignmentCenter;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.5;
        l.font = [UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightSemibold];

        [p addSubview:iv];
        [p addSubview:tint];
        [p addSubview:l];
        [_row addSubview:p];
        [pills addObject:p];
    }
    _pills = pills;

    // Case FPS, sous le chrono
    _fpsPill = [UIView new];
    _fpsPill.layer.cornerRadius = 8;
    _fpsPill.clipsToBounds = YES;
    UIView *ft = [UIView new];
    _fpsLabel = [UILabel new];
    _fpsLabel.textAlignment = NSTextAlignmentCenter;
    _fpsLabel.adjustsFontSizeToFitWidth = YES;
    _fpsLabel.minimumScaleFactor = 0.6;
    _fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightBold];
    _fpsLabel.text = @"-- FPS";
    _fpsLabel.textColor = UIColor.whiteColor;
    [_fpsPill addSubview:ft];
    [_fpsPill addSubview:_fpsLabel];
    [_box addSubview:_fpsPill];

    [self layoutPills];

    // Gestes : clic, appui long, glisser
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    lp.minimumPressDuration = 0.6;
    [tap requireGestureRecognizerToFail:lp];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [_row addGestureRecognizer:tap];
    [_row addGestureRecognizer:lp];
    [_row addGestureRecognizer:pan];
}

// Place les 3 cases selon la longueur choisie
- (void)layoutPills {
    CGFloat bw = floor((_width - 2 * kGap) / 3.0);
    _box.bounds = CGRectMake(0, 0, _width, kBoxH);
    _textLabel.frame = CGRectMake(0, 0, _width, kTextH);
    _row.frame = CGRectMake(0, kTextH + 2, _width, kPillH);
    for (NSInteger i = 0; i < 3; i++) {
        UIView *p = _pills[i];
        p.frame = CGRectMake(i * (bw + kGap), 0, bw, kPillH);
        p.subviews[0].frame = p.bounds;
        p.subviews[1].frame = p.bounds;
        p.subviews[2].frame = CGRectInset(p.bounds, 4, 0);
    }
    _fpsPill.frame = CGRectMake(0, kTextH + 2 + kPillH + 4, kFpsW, kFpsH);
    _fpsPill.subviews[0].frame = _fpsPill.bounds;
    _fpsLabel.frame = CGRectInset(_fpsPill.bounds, 4, 0);
}

- (void)setPillImage:(UIImage *)img {
    for (UIView *p in _pills) ((UIImageView *)p.subviews[0]).image = img;
}

- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *sv = _box.superview;
    CGPoint t = [g translationInView:sv];
    _box.center = CGPointMake(_box.center.x + t.x, _box.center.y + t.y);
    [g setTranslation:CGPointZero inView:sv];
}

- (void)longPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) [self openSettings];
}

- (void)layoutChanged {
    if (!_box) return;
    CGSize b = _rootVC.view.bounds.size;
    CGPoint c = _box.center;
    c.x = MAX(20, MIN(b.width - 20, c.x));
    c.y = MAX(20, MIN(b.height - 20, c.y));
    _box.center = c;
    if (_panel && !_panel.hidden) [self layoutPanel];
}

// Les touches ne sont captées que sur le chrono, les réglages ou un sélecteur ouvert.
// Partout ailleurs elles passent directement au jeu.
- (BOOL)capturesPoint:(CGPoint)p {
    if (!_row || !_overlay) return NO;
    if (_rootVC.presentedViewController) return YES;
    if (!_panel.hidden && CGRectContainsPoint(_panel.frame, p)) return YES;
    CGPoint pc = [_row convertPoint:p fromView:_overlay];
    return [_row pointInside:pc withEvent:nil];
}

#pragma mark Logique du chrono

- (NSTimeInterval)elapsed {
    return _accumulated + (_state == CRStateRunning ? CACurrentMediaTime() - _startTime : 0);
}

// 1 clic : lancer / pause / (en pause) reset
- (void)tapped {
    switch (_state) {
        case CRStateIdle:
            _startTime = CACurrentMediaTime();
            _state = CRStateRunning;
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(tick) userInfo:nil repeats:YES];
            [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
            break;
        case CRStateRunning:
            _accumulated += CACurrentMediaTime() - _startTime;
            _state = CRStatePaused;
            [_timer invalidate];
            _timer = nil;
            break;
        case CRStatePaused:
            _accumulated = 0;
            _state = CRStateIdle;
            break;
    }
    [self showTime:[self elapsed]];
}

- (void)tick {
    [self showTime:[self elapsed]];
}

- (void)showTime:(NSTimeInterval)t {
    int total = (int)t;
    NSArray<NSString *> *txt = @[
        [NSString stringWithFormat:@"%02dh", total / 3600],
        [NSString stringWithFormat:@"%02dm", (total / 60) % 60],
        [NSString stringWithFormat:@"%02ds", total % 60]
    ];
    UIColor *c = (_state == CRStatePaused) ? _pauseColor : _runColor;
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *l = (UILabel *)_pills[i].subviews[2];
        l.text = txt[i];
        l.textColor = c;
    }
}

#pragma mark Style

- (void)applyStyle {
    _box.transform = CGAffineTransformMakeScale(_scale, _scale);
    UIColor *veil = [_bgColor colorWithAlphaComponent:_bgOpacity];
    for (UIView *p in _pills) p.subviews[1].backgroundColor = veil;
    _fpsPill.subviews[0].backgroundColor = veil;
    _textLabel.textColor = _textColor;
    _textLabel.text = _text;
    [self showTime:[self elapsed]];
}

#pragma mark FPS

- (void)updateFPS {
    [_fpsTimer invalidate];
    _fpsTimer = nil;
    _fpsPill.hidden = !_showFPS;
    if (!_showFPS) return;
    _lastFrames = __atomic_load_n(&gFrames, __ATOMIC_RELAXED);
    _lastFpsTime = CACurrentMediaTime();
    _fpsTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(fpsTick) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_fpsTimer forMode:NSRunLoopCommonModes];
}

- (void)fpsTick {
    CFTimeInterval now = CACurrentMediaTime();
    int64_t f = __atomic_load_n(&gFrames, __ATOMIC_RELAXED);
    double dt = now - _lastFpsTime;
    int v = dt > 0 ? (int)lround((double)(f - _lastFrames) / dt) : 0;
    _lastFrames = f;
    _lastFpsTime = now;

    if (v <= 0) {
        _fpsLabel.text = @"-- FPS";
        _fpsLabel.textColor = UIColor.whiteColor;
        return;
    }
    _fpsLabel.text = [NSString stringWithFormat:@"%d FPS", v];
    if (v >= 50)      _fpsLabel.textColor = [UIColor colorWithRed:0.24 green:0.86 blue:0.52 alpha:1];
    else if (v >= 30) _fpsLabel.textColor = [UIColor colorWithRed:1.00 green:0.69 blue:0.13 alpha:1];
    else              _fpsLabel.textColor = [UIColor colorWithRed:1.00 green:0.32 blue:0.32 alpha:1];
}

#pragma mark Saturation

// Saturation de l'écran du jeu : 1 à 100 (50 = normal)
- (void)applySaturation {
    if (!_gameWindow) return;
    if (fabs(_saturation - 50) < 0.5) {
        _gameWindow.layer.filters = nil;
        return;
    }
    Class cls = NSClassFromString(@"CAFilter");
    SEL sel = NSSelectorFromString(@"filterWithType:");
    if (!cls || ![cls respondsToSelector:sel]) return;
    id f = [cls performSelector:sel withObject:@"colorSaturate"];
    if (!f) return;
    [f setValue:@(_saturation / 50.0) forKey:@"inputAmount"];
    _gameWindow.layer.filters = @[f];
}

#pragma mark Résolution du jeu

// Bas = 1280 px, Normal = d'origine, 2K = 2560 px, 4K = 3840 px (sur le grand côté)
- (CGFloat)targetPixels {
    switch (_resMode) {
        case 0: return 1280;
        case 2: return 2560;
        case 3: return 3840;
        default: return 0;
    }
}

- (void)collectRenderViews:(UIView *)v into:(NSMutableArray *)out {
    Class metal = NSClassFromString(@"CAMetalLayer");
    Class eagl = NSClassFromString(@"CAEAGLLayer");
    if ((metal && [v.layer isKindOfClass:metal]) || (eagl && [v.layer isKindOfClass:eagl])) {
        [out addObject:v];
    }
    for (UIView *sub in v.subviews) [self collectRenderViews:sub into:out];
}

- (void)setScale:(CGFloat)sc forRenderView:(UIView *)v {
    v.contentScaleFactor = sc;
    v.layer.contentsScale = sc;
    if ([v.layer respondsToSelector:NSSelectorFromString(@"setDrawableSize:")]) {
        CGSize sz = CGSizeMake(v.bounds.size.width * sc, v.bounds.size.height * sc);
        [v.layer setValue:[NSValue valueWithCGSize:sz] forKey:@"drawableSize"];
    }
    [v setNeedsLayout];
}

- (void)applyResolutionNow {
    CGFloat px = [self targetPixels];
    if (!_gameWindow || px <= 0) return;
    CGSize b = _gameWindow.bounds.size;
    CGFloat longSide = MAX(b.width, b.height);
    if (longSide <= 0) return;
    CGFloat target = MIN(6.0, px / longSide);
    NSMutableArray *views = [NSMutableArray array];
    [self collectRenderViews:_gameWindow into:views];
    for (UIView *v in views) {
        if (![_origScale objectForKey:v]) [_origScale setObject:@(v.contentScaleFactor) forKey:v];
        if (fabs(v.contentScaleFactor - target) > 0.01) [self setScale:target forRenderView:v];
    }
}

- (void)applyResolution {
    [_resTimer invalidate];
    _resTimer = nil;
    if (!_origScale) _origScale = [NSMapTable weakToStrongObjectsMapTable];
    if (!_gameWindow) return;

    if (_resMode != 1) {
        [self applyResolutionNow];
        // Le jeu peut remettre sa résolution : on la réapplique régulièrement
        _resTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(applyResolutionNow) userInfo:nil repeats:YES];
        return;
    }
    // Normal : retour à la résolution d'origine
    NSMutableArray *views = [NSMutableArray array];
    [self collectRenderViews:_gameWindow into:views];
    for (UIView *v in views) {
        NSNumber *o = [_origScale objectForKey:v];
        if (o) [self setScale:o.doubleValue forRenderView:v];
        [_origScale removeObjectForKey:v];
    }
}

#pragma mark Réglages

- (UIImage *)panelBackgroundImage {
    static UIImage *img; static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *b64 = [NSString stringWithUTF8String:kPanelBgB64];
        NSData *d = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (d) img = [UIImage imageWithData:d];
    });
    return img;
}

- (UILabel *)hintText:(NSString *)t frame:(CGRect)f {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.numberOfLines = 0;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    return l;
}

- (UIScrollView *)newPage {
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 86, 300, 354)];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sv.hidden = YES;
    [_panel addSubview:sv];
    return sv;
}

- (void)buildPanel {
    CGFloat pw = 300, W = pw - 32, y;

    _panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 440)];
    _panel.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
    _panel.layer.cornerRadius = 16;
    _panel.clipsToBounds = YES;
    _panel.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    _panel.hidden = YES;
    [_rootVC.view addSubview:_panel];

    // Fond du menu : le profil TikTok, assombri pour garder les réglages lisibles
    UIImage *bg = [self panelBackgroundImage];
    if (bg) {
        _panelBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, pw, pw * bg.size.height / bg.size.width)];
        _panelBg.image = bg;
        [_panel addSubview:_panelBg];
    }
    UIView *dim = [[UIView alloc] initWithFrame:_panel.bounds];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.62];
    dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_panel addSubview:dim];

    // En-tête
    [_panel addSubview:[self labelText:@"Réglages" frame:CGRectMake(16, 12, pw - 72, 26) size:18]];
    [_panel addSubview:[self buttonTitle:@"✕" frame:CGRectMake(pw - 48, 10, 34, 30) action:@selector(closeSettings)]];

    // Onglets (catégories)
    NSArray<NSString *> *names = @[@"Chrono", @"FPS", @"Jeu", @"Couleurs", @"Texte"];
    UIScrollView *tabs = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 46, pw, 34)];
    tabs.showsHorizontalScrollIndicator = NO;
    NSMutableArray *btns = [NSMutableArray array];
    CGFloat x = 16;
    for (NSInteger i = 0; i < (NSInteger)names.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:names[i] forState:UIControlStateNormal];
        [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        CGFloat bw = [names[i] sizeWithAttributes:@{NSFontAttributeName: b.titleLabel.font}].width + 24;
        b.frame = CGRectMake(x, 0, bw, 30);
        b.layer.cornerRadius = 15;
        b.tag = i;
        [b addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [tabs addSubview:b];
        [btns addObject:b];
        x += bw + 8;
    }
    tabs.contentSize = CGSizeMake(x + 8, 34);
    [_panel addSubview:tabs];
    _tabButtons = btns;

    // --- Catégorie 0 : Chrono ---
    UIScrollView *p0 = [self newPage];
    y = 8;
    [p0 addSubview:[self labelText:@"Taille" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 22;
    [p0 addSubview:[self sliderMin:0.4 max:1.6 value:_scale frame:CGRectMake(16, y, W, 30) action:@selector(sizeChanged:)]];
    y += 42;
    [p0 addSubview:[self labelText:@"Longueur" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 22;
    [p0 addSubview:[self sliderMin:120 max:420 value:_width frame:CGRectMake(16, y, W, 30) action:@selector(widthChanged:)]];
    y += 46;
    [p0 addSubview:[self hintText:@"1 clic : lancer. 1 clic : pause. 1 clic en pause : reset. Appui long sur le chrono : ces réglages. Glisse-le pour le déplacer." frame:CGRectMake(16, y, W, 64)]];
    y += 72;
    p0.contentSize = CGSizeMake(pw, y);

    // --- Catégorie 1 : FPS ---
    UIScrollView *p1 = [self newPage];
    y = 8;
    [p1 addSubview:[self labelText:@"Afficher les FPS" frame:CGRectMake(16, y + 6, W - 60, 20) size:14]];
    UISwitch *fs = [[UISwitch alloc] initWithFrame:CGRectMake(16 + W - 51, y, 51, 31)];
    fs.on = _showFPS;
    [fs addTarget:self action:@selector(fpsChanged:) forControlEvents:UIControlEventValueChanged];
    [p1 addSubview:fs];
    y += 50;
    [p1 addSubview:[self hintText:@"Vert à partir de 50 FPS, orange à partir de 30, rouge en dessous. Valeur approximative : elle compte les images affichées par le jeu (jeux Metal). Sinon : « -- FPS »." frame:CGRectMake(16, y, W, 90)]];
    y += 98;
    p1.contentSize = CGSizeMake(pw, y);

    // --- Catégorie 2 : Jeu ---
    UIScrollView *p2 = [self newPage];
    y = 8;
    [p2 addSubview:[self labelText:@"Résolution du jeu" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 24;
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Bas", @"Normal", @"2K", @"4K"]];
    seg.frame = CGRectMake(16, y, W, 32);
    seg.selectedSegmentIndex = _resMode;
    [seg addTarget:self action:@selector(resChanged:) forControlEvents:UIControlEventValueChanged];
    [p2 addSubview:seg];
    y += 46;
    [p2 addSubview:[self labelText:@"Saturation (50 = normal)" frame:CGRectMake(16, y, W - 50, 20) size:14]];
    _satValue = [self labelText:[NSString stringWithFormat:@"%d", (int)_saturation] frame:CGRectMake(16 + W - 46, y, 46, 20) size:14];
    _satValue.textAlignment = NSTextAlignmentRight;
    [p2 addSubview:_satValue];
    y += 22;
    [p2 addSubview:[self sliderMin:1 max:100 value:_saturation frame:CGRectMake(16, y, W, 30) action:@selector(satChanged:)]];
    y += 46;
    [p2 addSubview:[self labelText:@"Masquer la barre iPhone" frame:CGRectMake(16, y + 6, W - 60, 20) size:14]];
    UISwitch *sb = [[UISwitch alloc] initWithFrame:CGRectMake(16 + W - 51, y, 51, 31)];
    sb.on = _hideStatusBar;
    [sb addTarget:self action:@selector(statusBarChanged:) forControlEvents:UIControlEventValueChanged];
    [p2 addSubview:sb];
    y += 50;
    p2.contentSize = CGSizeMake(pw, y);

    // --- Catégorie 3 : Couleurs ---
    UIScrollView *p3 = [self newPage];
    y = 8;
    y = [self colorRow:@"Chiffres en marche" tag:1 color:_runColor y:y width:W parent:p3];
    y = [self colorRow:@"Chiffres en pause" tag:2 color:_pauseColor y:y width:W parent:p3];
    y = [self colorRow:@"Fond des cases" tag:3 color:_bgColor y:y width:W parent:p3];
    y = [self colorRow:@"Couleur du texte" tag:4 color:_textColor y:y width:W parent:p3];
    [p3 addSubview:[self labelText:@"Opacité du fond" frame:CGRectMake(16, y, W - 50, 20) size:14]];
    _opValue = [self labelText:[NSString stringWithFormat:@"%d%%", (int)roundf(_bgOpacity * 100)] frame:CGRectMake(16 + W - 46, y, 46, 20) size:14];
    _opValue.textAlignment = NSTextAlignmentRight;
    [p3 addSubview:_opValue];
    y += 22;
    [p3 addSubview:[self sliderMin:0 max:100 value:_bgOpacity * 100 frame:CGRectMake(16, y, W, 30) action:@selector(opChanged:)]];
    y += 46;
    p3.contentSize = CGSizeMake(pw, y);

    // --- Catégorie 4 : Texte et image ---
    UIScrollView *p4 = [self newPage];
    y = 8;
    [p4 addSubview:[self labelText:@"Texte (au-dessus du chrono)" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 24;
    _field = [[UITextField alloc] initWithFrame:CGRectMake(16, y, W, 34)];
    _field.text = _text;
    _field.textColor = UIColor.whiteColor;
    _field.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    _field.layer.cornerRadius = 8;
    _field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 34)];
    _field.leftViewMode = UITextFieldViewModeAlways;
    _field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Ton texte"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
    _field.returnKeyType = UIReturnKeyDone;
    _field.delegate = self;
    [_field addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    [p4 addSubview:_field];
    y += 46;
    [p4 addSubview:[self buttonTitle:@"Choisir une image" frame:CGRectMake(16, y, W, 34) action:@selector(pickImage)]];
    y += 42;
    [p4 addSubview:[self buttonTitle:@"Retirer l'image" frame:CGRectMake(16, y, W, 34) action:@selector(removeImage)]];
    y += 46;
    p4.contentSize = CGSizeMake(pw, y);
    _textPage = p4;

    _pages = @[p0, p1, p2, p3, p4];
    [self selectTab:0];
}

- (void)selectTab:(NSInteger)i {
    _tab = i;
    for (NSInteger k = 0; k < (NSInteger)_pages.count; k++) {
        _pages[k].hidden = (k != i);
        _tabButtons[k].backgroundColor = [UIColor colorWithWhite:1 alpha:(k == i ? 0.35 : 0.12)];
    }
    [_field resignFirstResponder];
}

- (void)tabTapped:(UIButton *)b {
    [self selectTab:b.tag];
}

- (CGFloat)colorRow:(NSString *)title tag:(NSInteger)tag color:(UIColor *)c y:(CGFloat)y width:(CGFloat)W parent:(UIView *)parent {
    [parent addSubview:[self labelText:title frame:CGRectMake(16, y + 6, W - 60, 20) size:14]];
    UIColorWell *w = [[UIColorWell alloc] initWithFrame:CGRectMake(16 + W - 48, y, 48, 32)];
    w.tag = tag;
    w.title = title;
    w.supportsAlpha = NO;
    w.selectedColor = c;
    [w addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];
    [parent addSubview:w];
    return y + 44;
}

- (void)layoutPanel {
    CGSize b = _rootVC.view.bounds.size;
    CGFloat h = MIN(440, b.height - 24);
    if (_editing) h = MIN(h, 210);
    _panel.frame = CGRectMake((b.width - 300) / 2, _editing ? 8 : (b.height - h) / 2, 300, h);
}

- (void)openSettings {
    _panel.hidden = NO;
    [_rootVC.view bringSubviewToFront:_panel];
    [self layoutPanel];
}

- (void)closeSettings {
    [_field resignFirstResponder];
    _panel.hidden = YES;
    [self savePrefs];
}

- (void)sizeChanged:(UISlider *)s {
    _scale = s.value;
    [self applyStyle];
    [self savePrefs];
}

- (void)widthChanged:(UISlider *)s {
    _width = roundf(s.value);
    [self layoutPills];
    [self savePrefs];
}

- (void)resChanged:(UISegmentedControl *)s {
    _resMode = s.selectedSegmentIndex;
    [self applyResolution];
    [self savePrefs];
}

- (void)satChanged:(UISlider *)s {
    _saturation = roundf(s.value);
    _satValue.text = [NSString stringWithFormat:@"%d", (int)_saturation];
    [self applySaturation];
    [self savePrefs];
}

- (void)fpsChanged:(UISwitch *)s {
    _showFPS = s.on;
    [self updateFPS];
    [self savePrefs];
}

- (void)statusBarChanged:(UISwitch *)s {
    self.hideStatusBar = s.on;
    [self savePrefs];
}

- (void)opChanged:(UISlider *)s {
    _bgOpacity = roundf(s.value) / 100.0;
    _opValue.text = [NSString stringWithFormat:@"%d%%", (int)roundf(s.value)];
    [self applyStyle];
    [self savePrefs];
}

- (void)colorChanged:(UIColorWell *)w {
    UIColor *c = w.selectedColor;
    if (!c) return;
    switch (w.tag) {
        case 1: _runColor = c; break;
        case 2: _pauseColor = c; break;
        case 3: _bgColor = c; break;
        case 4: _textColor = c; break;
    }
    [self applyStyle];
    [self savePrefs];
}

- (void)textChanged:(UITextField *)f {
    _text = f.text ?: @"";
    _textLabel.text = _text;
    [self savePrefs];
}

#pragma mark Clavier

- (BOOL)textFieldShouldReturn:(UITextField *)f {
    [f resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)f {
    _editing = YES;
    _overlay.allowKey = YES;
    [_overlay makeKeyWindow];
    [self layoutPanel];
    [_textPage setContentOffset:CGPointZero animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)f {
    _editing = NO;
    [self layoutPanel];
    _overlay.allowKey = NO;
    [_gameWindow makeKeyWindow];
}

#pragma mark Image

- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.filter = PHPickerFilter.imagesFilter;
    cfg.selectionLimit = 1;
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    p.delegate = self;
    [CRTop(_rootVC) presentViewController:p animated:YES completion:nil];
}

- (void)removeImage {
    [NSFileManager.defaultManager removeItemAtPath:CRImagePath() error:nil];
    [self setPillImage:nil];
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
        dispatch_async(dispatch_get_main_queue(), ^{ [self setPillImage:img]; });
    }];
}

@end

#pragma mark - Entrée du dylib

__attribute__((constructor))
static void CRInit(void) {
    CRHookFrames();   // doit être posé avant que le jeu ne commence à afficher
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CRChrono shared] installWhenReady];
    });
}
