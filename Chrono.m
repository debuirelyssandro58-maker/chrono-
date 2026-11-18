// Chrono v5 - dylib by Ragnar
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define COL(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define kOverlayTag 7777001
#define kPanelBG COL(11,11,12)
#define kBorder  COL(58,58,62)
#define kGreen   COL(46,204,113)
#define kGray    COL(170,170,176)

#pragma mark - Outils

static NSUserDefaults *Defs(void) { return [NSUserDefaults standardUserDefaults]; }

static double DefFloat(NSString *k, double d) {
    NSNumber *o = [Defs() objectForKey:k];
    return o ? o.doubleValue : d;
}
static NSInteger DefInt(NSString *k, NSInteger d) {
    NSNumber *o = [Defs() objectForKey:k];
    return o ? o.integerValue : d;
}
static BOOL DefBool(NSString *k, BOOL d) {
    NSNumber *o = [Defs() objectForKey:k];
    return o ? o.boolValue : d;
}

static UIWindow *KeyWindow(void) {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)s).windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static UIViewController *TopVC(void) {
    UIViewController *vc = KeyWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static UIColor *AccentColor(NSInteger i) {
    switch (i) {
        case 1: return COL(52,152,219);
        case 2: return COL(231,76,60);
        case 3: return COL(155,89,182);
        case 4: return COL(241,196,15);
        case 5: return COL(255,255,255);
        default: return COL(46,204,113);
    }
}

static NSAttributedString *CellText(int n, NSString *unit, UIColor *col) {
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%02d", n]
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:30 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col}];
    [a appendAttributedString:[[NSAttributedString alloc]
        initWithString:unit
            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
                         NSForegroundColorAttributeName: COL(160,160,168)}]];
    return a;
}

static NSAttributedString *BigTime(NSTimeInterval t, UIColor *col) {
    if (t < 0) t = 0;
    int total = (int)t;
    int h = total / 3600;
    int m = (total % 3600) / 60;
    int s = total % 60;
    int cs = (int)((t - floor(t)) * 100);
    NSString *main = (h > 0)
        ? [NSString stringWithFormat:@"%d:%02d:%02d", h, m, s]
        : [NSString stringWithFormat:@"%02d:%02d", m, s];
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:main
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:46 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col}];
    [a appendAttributedString:[[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@".%02d", cs]
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightSemibold],
                         NSForegroundColorAttributeName: [col colorWithAlphaComponent:0.75]}]];
    return a;
}

static UILabel *AddLabel(UIView *p, NSString *t, CGFloat x, CGFloat y, CGFloat w, CGFloat h, CGFloat size, UIColor *c, BOOL bold) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, h)];
    l.text = t;
    l.textColor = c;
    l.numberOfLines = 0;
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    [p addSubview:l];
    return l;
}

static UIButton *AddButton(UIView *p, NSString *t, CGRect f, UIColor *bg, UIColor *fg, id target, SEL sel) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = f;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:fg forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    b.backgroundColor = bg;
    b.layer.cornerRadius = 10;
    [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    [p addSubview:b];
    return b;
}

static UISegmentedControl *AddSegment(UIView *p, NSArray *items, CGRect f, NSInteger sel, id target, SEL action) {
    UISegmentedControl *s = [[UISegmentedControl alloc] initWithItems:items];
    s.frame = f;
    s.selectedSegmentIndex = sel;
    s.selectedSegmentTintColor = kGreen;
    s.backgroundColor = COL(44,44,46);
    [s setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateNormal];
    [s setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.blackColor} forState:UIControlStateSelected];
    [s addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [p addSubview:s];
    return s;
}

static UISlider *AddSlider(UIView *p, CGRect f, float mn, float mx, float v, id target, SEL action) {
    UISlider *s = [[UISlider alloc] initWithFrame:f];
    s.minimumValue = mn;
    s.maximumValue = mx;
    s.value = v;
    s.minimumTrackTintColor = kGreen;
    [s addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [p addSubview:s];
    return s;
}

static UISwitch *AddSwitch(UIView *p, CGFloat x, CGFloat y, BOOL on, id target, SEL action) {
    UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(x, y, 51, 31)];
    s.on = on;
    s.onTintColor = kGreen;
    [s addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [p addSubview:s];
    return s;
}

#pragma mark - Interfaces

@interface GameTools : NSObject
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic) CFTimeInterval lastStamp;
@property (nonatomic) int frames;
+ (instancetype)shared;
- (void)setFPSEnabled:(BOOL)on;
- (void)applyResolution:(NSInteger)idx;
- (void)applySaturation:(double)v;
- (void)setStatusBarHidden:(BOOL)on;
- (void)reapplyAll;
@end

@interface ChronoView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIView *box;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) NSArray<UIView *> *cells;
@property (nonatomic, strong) NSArray<UILabel *> *cellLabels;
@property (nonatomic, strong) UIView *lsPanel;
@property (nonatomic, strong) UILabel *lsState;
@property (nonatomic, strong) UILabel *lsTime;
@property (nonatomic) NSInteger style;
@property (nonatomic) NSInteger accent;
@property (nonatomic) CGFloat length;
@property (nonatomic) CGFloat zoom;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval accumulated;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) BOOL running;
- (void)applyConfig;
- (void)pickImage;
- (void)clearImage;
@end

@interface SettingsView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, weak) ChronoView *chrono;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) NSArray<UIScrollView *> *pages;
@property (nonatomic, strong) NSArray<UIButton *> *colorBtns;
@property (nonatomic, strong) UILabel *lenLabel;
@property (nonatomic, strong) UILabel *zoomLabel;
@property (nonatomic, strong) UILabel *satLabel;
@property (nonatomic, strong) UIButton *copyBtn;
- (instancetype)initWithFrame:(CGRect)f chrono:(ChronoView *)c;
@end

static SettingsView *gSettings = nil;

static void ShowSettings(ChronoView *c) {
    UIWindow *w = KeyWindow();
    if (!w) return;
    if (gSettings) [gSettings removeFromSuperview];
    gSettings = [[SettingsView alloc] initWithFrame:w.bounds chrono:c];
    [w addSubview:gSettings];
}

#pragma mark - GameTools

static BOOL gHideStatusBar = NO;
static BOOL Hook_prefersStatusBarHidden(id self, SEL _cmd) { return gHideStatusBar; }

static void ScaleTree(UIView *v, CGFloat f) {
    if (v.tag == kOverlayTag) return;
    static Class metalCls = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ metalCls = NSClassFromString(@"CAMetalLayer"); });
    BOOL isMetal = (metalCls != nil) && [v.layer isKindOfClass:metalCls];
    BOOL isGL = [NSStringFromClass([v.layer class]) isEqualToString:@"CAEAGLLayer"];
    if (isMetal || isGL) {
        v.contentScaleFactor = f;
        if (isMetal) {
            CGSize s = CGSizeMake(v.bounds.size.width * f, v.bounds.size.height * f);
            @try { [v.layer setValue:[NSValue valueWithCGSize:s] forKey:@"drawableSize"]; }
            @catch (NSException *e) {}
        }
    }
    for (UIView *sub in v.subviews) ScaleTree(sub, f);
}

@implementation GameTools

+ (instancetype)shared {
    static GameTools *g = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ g = [[GameTools alloc] init]; });
    return g;
}

- (void)setFPSEnabled:(BOOL)on {
    if (on) {
        UIWindow *w = KeyWindow();
        if (!w) return;
        if (!self.fpsLabel) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 76, 22)];
            l.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightBold];
            l.textColor = kGreen;
            l.textAlignment = NSTextAlignmentCenter;
            l.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
            l.layer.cornerRadius = 8;
            l.layer.masksToBounds = YES;
            l.text = @"-- FPS";
            l.tag = kOverlayTag;
            l.userInteractionEnabled = NO;
            l.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            self.fpsLabel = l;
        }
        self.fpsLabel.frame = CGRectMake(w.bounds.size.width - 76 - 12, w.safeAreaInsets.top + 6, 76, 22);
        if (self.fpsLabel.superview != w) [w addSubview:self.fpsLabel];
        self.fpsLabel.hidden = NO;
        if (!self.link) {
            self.lastStamp = 0;
            self.frames = 0;
            self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
            [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
    } else {
        [self.link invalidate];
        self.link = nil;
        self.fpsLabel.hidden = YES;
    }
}

- (void)tick:(CADisplayLink *)l {
    if (self.lastStamp == 0) { self.lastStamp = l.timestamp; return; }
    self.frames += 1;
    CFTimeInterval dt = l.timestamp - self.lastStamp;
    if (dt >= 0.5) {
        self.fpsLabel.text = [NSString stringWithFormat:@"%d FPS", (int)round(self.frames / dt)];
        self.frames = 0;
        self.lastStamp = l.timestamp;
    }
}

- (void)applyResolution:(NSInteger)idx {
    if (idx == 2 && ![Defs() objectForKey:@"game.res"]) return;
    CGFloat native = [UIScreen mainScreen].nativeScale;
    CGRect b = [UIScreen mainScreen].bounds;
    CGFloat maxPts = MAX(b.size.width, b.size.height);
    CGFloat f = native;
    if (idx == 0) f = native * 0.5;
    else if (idx == 1) f = native * 0.75;
    else if (idx == 3) f = 3840.0 / maxPts;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        for (UIView *v in w.subviews) ScaleTree(v, f);
    }
}

- (void)applySaturation:(double)v {
    UIView *target = KeyWindow().rootViewController.view;
    if (!target) return;
    if (fabs(v - 50.0) < 0.5) { target.layer.filters = nil; return; }
    Class cls = NSClassFromString(@"CAFilter");
    if (!cls) return;
    @try {
        id f = [cls performSelector:NSSelectorFromString(@"filterWithType:") withObject:@"colorSaturate"];
        [f setValue:@(v / 50.0) forKey:@"inputAmount"];
        target.layer.filters = @[f];
    } @catch (NSException *e) {}
}

- (void)setStatusBarHidden:(BOOL)on {
    gHideStatusBar = on;
    if (on) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            Method m = class_getInstanceMethod([UIViewController class], @selector(prefersStatusBarHidden));
            if (m) method_setImplementation(m, (IMP)Hook_prefersStatusBarHidden);
        });
    }
    [KeyWindow().rootViewController setNeedsStatusBarAppearanceUpdate];
}

- (void)reapplyAll {
    [self setFPSEnabled:DefBool(@"game.fps", NO)];
    [self applyResolution:DefInt(@"game.res", 2)];
    [self applySaturation:DefFloat(@"game.sat", 50)];
    [self setStatusBarHidden:DefBool(@"game.hidebar", NO)];
}

@end

#pragma mark - ChronoView

@implementation ChronoView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.tag = kOverlayTag;
        self.backgroundColor = UIColor.clearColor;

        // Texte au-dessus du chrono
        _titleField = [[UITextField alloc] init];
        _titleField.textColor = UIColor.whiteColor;
        _titleField.tintColor = UIColor.whiteColor;
        _titleField.textAlignment = NSTextAlignmentCenter;
        _titleField.font = [UIFont boldSystemFontOfSize:16];
        _titleField.returnKeyType = UIReturnKeyDone;
        _titleField.delegate = self;
        _titleField.text = [Defs() stringForKey:@"chrono.title"];
        _titleField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:@"Écrire un texte…"
                attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.45]}];
        _titleField.layer.shadowColor = UIColor.blackColor.CGColor;
        _titleField.layer.shadowOpacity = 0.9;
        _titleField.layer.shadowRadius = 2;
        _titleField.layer.shadowOffset = CGSizeMake(0, 1);
        _titleField.layer.masksToBounds = NO;
        [self addSubview:_titleField];

        // Zone du chrono
        _box = [[UIView alloc] init];
        _box.layer.cornerRadius = 12;
        _box.clipsToBounds = YES;
        [self addSubview:_box];

        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.clipsToBounds = YES;
        [_box addSubview:_bgImageView];

        _dimView = [[UIView alloc] init];
        _dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.40];
        _dimView.hidden = YES;
        [_box addSubview:_dimView];

        // Style "Boîtes" : trois cases noires arrondies
        NSMutableArray *cells = [NSMutableArray array];
        NSMutableArray *labels = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            UIView *c = [[UIView alloc] init];
            c.backgroundColor = [UIColor colorWithWhite:0 alpha:0.88];
            c.layer.cornerRadius = 12;
            c.layer.borderWidth = 1;
            c.layer.borderColor = COL(46,46,50).CGColor;
            UILabel *l = [[UILabel alloc] init];
            l.textAlignment = NSTextAlignmentCenter;
            l.adjustsFontSizeToFitWidth = YES;
            l.minimumScaleFactor = 0.5;
            [c addSubview:l];
            [_box addSubview:c];
            [cells addObject:c];
            [labels addObject:l];
        }
        _cells = cells;
        _cellLabels = labels;

        // Style "LiveSplit"
        _lsPanel = [[UIView alloc] init];
        _lsPanel.backgroundColor = COL(8,8,9);
        _lsPanel.layer.borderWidth = 1;
        _lsPanel.layer.borderColor = COL(46,46,50).CGColor;
        [_box addSubview:_lsPanel];

        _lsState = [[UILabel alloc] init];
        _lsState.font = [UIFont boldSystemFontOfSize:11];
        [_lsPanel addSubview:_lsState];

        _lsTime = [[UILabel alloc] init];
        _lsTime.textAlignment = NSTextAlignmentRight;
        _lsTime.adjustsFontSizeToFitWidth = YES;
        _lsTime.minimumScaleFactor = 0.5;
        [_lsPanel addSubview:_lsTime];

        // Gestes : 1 appui = lancer / pause / reset, appui long = réglages
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(boxTapped)];
        [_box addGestureRecognizer:tap];
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(boxLongPressed:)];
        lp.minimumPressDuration = 0.6;
        [_box addGestureRecognizer:lp];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
        pan.cancelsTouchesInView = NO;
        [self addGestureRecognizer:pan];

        [self applyConfig];
    }
    return self;
}

- (void)applyConfig {
    self.style = DefInt(@"chrono.style", 0);
    self.accent = DefInt(@"chrono.accent", 0);
    self.length = (CGFloat)MAX(180.0, MIN(340.0, DefFloat(@"chrono.length", 240)));
    self.zoom = (CGFloat)MAX(0.6, MIN(1.5, DefFloat(@"chrono.zoom", 1.0)));
    [self relayout];
    [self refreshBackground];
    [self refresh];
    [self applyZoom];
}

- (void)relayout {
    CGFloat L = self.length;
    CGFloat titleH = 28.0;
    BOOL boxes = (self.style == 0);
    CGFloat cw = (L - 16.0) / 3.0;
    CGFloat boxH = boxes ? round(cw * 0.95) : round(L * 0.40);
    self.bounds = CGRectMake(0, 0, L, titleH + boxH);
    self.titleField.frame = CGRectMake(0, 0, L, titleH);
    self.box.frame = CGRectMake(0, titleH, L, boxH);
    self.bgImageView.frame = self.box.bounds;
    self.dimView.frame = self.box.bounds;
    for (NSInteger i = 0; i < 3; i++) {
        UIView *c = self.cells[i];
        c.hidden = !boxes;
        c.frame = CGRectMake(i * (cw + 8.0), 0, cw, boxH);
        self.cellLabels[i].frame = c.bounds;
    }
    self.lsPanel.hidden = boxes;
    self.lsPanel.frame = self.box.bounds;
    self.lsState.frame = CGRectMake(14, 10, L - 28, 14);
    self.lsTime.frame = CGRectMake(10, 26, L - 24, boxH - 32);
}

- (void)refreshBackground {
    BOOL has = (self.bgImageView.image != nil);
    self.dimView.hidden = !has;
    self.lsPanel.backgroundColor = has ? [UIColor colorWithWhite:0 alpha:0.35] : COL(8,8,9);
}

- (void)applyZoom {
    CGFloat z = self.zoom;
    self.transform = CGAffineTransformMakeScale(z, z);
    [self setScaleFactor:[UIScreen mainScreen].scale * z onView:self];
    [self clamp];
}

- (void)setScaleFactor:(CGFloat)cs onView:(UIView *)v {
    v.contentScaleFactor = cs;
    for (UIView *sub in v.subviews) [self setScaleFactor:cs onView:sub];
}

- (void)clamp {
    if (!self.superview) return;
    CGRect b = self.superview.bounds;
    CGSize sz = self.frame.size;
    CGPoint c = self.center;
    c.x = MAX(sz.width / 2, MIN(b.size.width - sz.width / 2, c.x));
    c.y = MAX(sz.height / 2, MIN(b.size.height - sz.height / 2, c.y));
    self.center = c;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint d = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + d.x, self.center.y + d.y);
    [g setTranslation:CGPointZero inView:self.superview];
    [self clamp];
}

#pragma mark Chrono

- (NSTimeInterval)elapsed {
    return self.accumulated + (self.running ? CACurrentMediaTime() - self.startTime : 0);
}

- (void)refresh {
    NSTimeInterval t = [self elapsed];
    BOOL idle = (!self.running && self.accumulated == 0);
    UIColor *col = self.running ? AccentColor(self.accent) : (idle ? UIColor.whiteColor : COL(243,156,18));
    if (self.style == 0) {
        int total = (int)t;
        NSArray *vals = @[@(total / 3600), @((total % 3600) / 60), @(total % 60)];
        NSArray *units = @[@"h", @"m", @"s"];
        for (NSInteger i = 0; i < 3; i++) {
            self.cellLabels[i].attributedText = CellText([vals[i] intValue], units[i], col);
        }
    } else {
        self.lsTime.attributedText = BigTime(t, col);
        self.lsState.text = self.running ? @"EN COURS" : (idle ? @"PRÊT" : @"PAUSE");
        self.lsState.textColor = col;
    }
}

- (void)tick { [self refresh]; }

- (void)startTimer {
    if (self.running) return;
    self.startTime = CACurrentMediaTime();
    self.running = YES;
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self refresh];
}

- (void)pauseTimer {
    if (!self.running) return;
    self.accumulated += CACurrentMediaTime() - self.startTime;
    self.running = NO;
    [self.timer invalidate];
    self.timer = nil;
    [self refresh];
}

- (void)resetTimer {
    [self.timer invalidate];
    self.timer = nil;
    self.running = NO;
    self.accumulated = 0;
    [self refresh];
}

- (void)boxTapped {
    BOOL idle = (!self.running && self.accumulated == 0);
    if (self.running) [self pauseTimer];
    else if (idle) [self startTimer];
    else [self resetTimer];
}

- (void)boxLongPressed:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) ShowSettings(self);
}

#pragma mark Image

- (void)pickImage {
    UIImagePickerController *p = [[UIImagePickerController alloc] init];
    p.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    p.delegate = self;
    [TopVC() presentViewController:p animated:YES completion:nil];
}

- (void)clearImage {
    self.bgImageView.image = nil;
    [self refreshBackground];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    if (img) {
        self.bgImageView.image = img;
        [self refreshBackground];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Texte

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)tf {
    [Defs() setObject:tf.text forKey:@"chrono.title"];
}

@end

#pragma mark - SettingsView

@implementation SettingsView

- (instancetype)initWithFrame:(CGRect)f chrono:(ChronoView *)c {
    if ((self = [super initWithFrame:f])) {
        _chrono = c;
        self.tag = kOverlayTag;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;

        UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        t.delegate = self;
        [self addGestureRecognizer:t];

        CGFloat cw = MIN(300.0, f.size.width - 24.0);
        CGFloat ch = MIN(340.0, f.size.height - 24.0);
        _card = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - cw) / 2, (f.size.height - ch) / 2, cw, ch)];
        _card.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                 UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _card.backgroundColor = kPanelBG;
        _card.layer.cornerRadius = 16;
        _card.layer.borderWidth = 1;
        _card.layer.borderColor = kBorder.CGColor;
        _card.clipsToBounds = YES;
        [self addSubview:_card];

        AddLabel(_card, @"Réglages", 16, 12, cw - 70, 24, 18, UIColor.whiteColor, YES);
        UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
        close.frame = CGRectMake(cw - 46, 8, 34, 32);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        close.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [_card addSubview:close];

        AddSegment(_card, @[@"Chrono", @"Image", @"Jeu", @"Aide"], CGRectMake(12, 44, cw - 24, 30), 0, self, @selector(tabChanged:));

        NSMutableArray *pages = [NSMutableArray array];
        for (int i = 0; i < 4; i++) {
            UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 84, cw, ch - 84)];
            sv.hidden = (i != 0);
            [_card addSubview:sv];
            [pages addObject:sv];
        }
        _pages = pages;

        CGFloat h0 = [self buildChronoPage:pages[0] width:cw];
        CGFloat h1 = [self buildImagePage:pages[1] width:cw];
        CGFloat h2 = [self buildGamePage:pages[2] width:cw];
        CGFloat h3 = [self buildHelpPage:pages[3] width:cw];
        ((UIScrollView *)pages[0]).contentSize = CGSizeMake(cw, h0);
        ((UIScrollView *)pages[1]).contentSize = CGSizeMake(cw, h1);
        ((UIScrollView *)pages[2]).contentSize = CGSizeMake(cw, h2);
        ((UIScrollView *)pages[3]).contentSize = CGSizeMake(cw, h3);
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self;
}

- (void)dismiss {
    [self removeFromSuperview];
    if (gSettings == self) gSettings = nil;
}

- (void)tabChanged:(UISegmentedControl *)s {
    for (NSInteger i = 0; i < (NSInteger)self.pages.count; i++) {
        self.pages[i].hidden = (i != s.selectedSegmentIndex);
    }
}

#pragma mark Pages

- (CGFloat)buildChronoPage:(UIScrollView *)p width:(CGFloat)w {
    CGFloat x = 16, iw = w - 32, y = 8;
    AddLabel(p, @"Style du chrono", x, y, iw, 18, 13, kGray, NO);
    y += 22;
    AddSegment(p, @[@"Boîtes", @"LiveSplit"], CGRectMake(x, y, iw, 32), DefInt(@"chrono.style", 0), self, @selector(styleChanged:));
    y += 46;

    AddLabel(p, @"Couleur du chrono", x, y, iw, 18, 13, kGray, NO);
    y += 24;
    NSMutableArray *btns = [NSMutableArray array];
    CGFloat step = (iw - 34.0) / 5.0;
    for (int i = 0; i < 6; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(x + i * step, y, 34, 34);
        b.backgroundColor = AccentColor(i);
        b.layer.cornerRadius = 17;
        b.layer.borderWidth = 3;
        b.tag = i;
        [b addTarget:self action:@selector(accentTapped:) forControlEvents:UIControlEventTouchUpInside];
        [p addSubview:b];
        [btns addObject:b];
    }
    self.colorBtns = btns;
    [self refreshColorBtns];
    y += 48;

    double len = MAX(180.0, MIN(340.0, DefFloat(@"chrono.length", 240)));
    self.lenLabel = AddLabel(p, [NSString stringWithFormat:@"Longueur : %d", (int)len], x, y, iw, 18, 13, kGray, NO);
    y += 22;
    AddSlider(p, CGRectMake(x, y, iw, 30), 180, 340, (float)len, self, @selector(lengthChanged:));
    y += 40;

    double zoom = MAX(0.6, MIN(1.5, DefFloat(@"chrono.zoom", 1.0)));
    self.zoomLabel = AddLabel(p, [NSString stringWithFormat:@"Taille : %d%%", (int)round(zoom * 100)], x, y, iw, 18, 13, kGray, NO);
    y += 22;
    AddSlider(p, CGRectMake(x, y, iw, 30), 0.6, 1.5, (float)zoom, self, @selector(zoomChanged:));
    y += 40;

    AddLabel(p, @"1 appui : lancer / pause / reset.\nAppui long sur le chrono : ouvrir ce menu.", x, y, iw, 34, 11, kGray, NO);
    y += 44;
    return y;
}

- (CGFloat)buildImagePage:(UIScrollView *)p width:(CGFloat)w {
    CGFloat x = 16, iw = w - 32, y = 8;
    AddLabel(p, @"Fond du chrono", x, y, iw, 18, 13, kGray, NO);
    y += 26;
    AddButton(p, @"Choisir une image", CGRectMake(x, y, iw, 42), kGreen, UIColor.blackColor, self, @selector(pickImage));
    y += 52;
    AddButton(p, @"Retirer l'image (fond noir)", CGRectMake(x, y, iw, 42), COL(44,44,46), UIColor.whiteColor, self, @selector(clearImage));
    y += 52;
    AddLabel(p, @"Par défaut, le fond est noir.", x, y, iw, 18, 11, kGray, NO);
    y += 28;
    return y;
}

- (CGFloat)buildGamePage:(UIScrollView *)p width:(CGFloat)w {
    CGFloat x = 16, iw = w - 32, y = 8;

    AddLabel(p, @"Compteur FPS", x, y + 5, iw - 60, 22, 15, UIColor.whiteColor, NO);
    AddSwitch(p, x + iw - 51, y, DefBool(@"game.fps", NO), self, @selector(fpsChanged:));
    y += 42;

    AddLabel(p, @"Résolution du jeu", x, y, iw, 18, 13, kGray, NO);
    y += 22;
    AddSegment(p, @[@"50%", @"75%", @"Natif", @"4K"], CGRectMake(x, y, iw, 32), DefInt(@"game.res", 2), self, @selector(resChanged:));
    y += 38;
    AddLabel(p, @"Certains jeux ignorent ce réglage.", x, y, iw, 16, 11, kGray, NO);
    y += 26;

    double sat = DefFloat(@"game.sat", 50);
    self.satLabel = AddLabel(p, [NSString stringWithFormat:@"Saturation : %d (50 = normal)", (int)round(sat)], x, y, iw, 18, 13, kGray, NO);
    y += 22;
    AddSlider(p, CGRectMake(x, y, iw, 30), 1, 100, (float)sat, self, @selector(satChanged:));
    y += 42;

    AddLabel(p, @"Masquer la barre d'état", x, y + 5, iw - 60, 22, 15, UIColor.whiteColor, NO);
    AddSwitch(p, x + iw - 51, y, DefBool(@"game.hidebar", NO), self, @selector(barChanged:));
    y += 48;
    return y;
}

- (CGFloat)buildHelpPage:(UIScrollView *)p width:(CGFloat)w {
    CGFloat x = 16, iw = w - 32, y = 8;
    AddLabel(p, @"Besoin d'aide ?", x, y, iw, 24, 18, UIColor.whiteColor, YES);
    y += 32;
    AddLabel(p, @"Ajoute g420262 sur TikTok pour avoir de l'aide.", x, y, iw, 44, 15, UIColor.whiteColor, NO);
    y += 56;
    self.copyBtn = AddButton(p, @"Copier g420262", CGRectMake(x, y, iw, 42), kGreen, UIColor.blackColor, self, @selector(copyHandle));
    y += 60;
    AddLabel(p, @"dylib by Ragnar", x, y, iw, 18, 12, kGray, NO);
    y += 30;
    return y;
}

#pragma mark Actions

- (void)refreshColorBtns {
    NSInteger sel = DefInt(@"chrono.accent", 0);
    for (UIButton *b in self.colorBtns) {
        b.layer.borderColor = (b.tag == sel) ? UIColor.whiteColor.CGColor : UIColor.clearColor.CGColor;
    }
}

- (void)styleChanged:(UISegmentedControl *)s {
    [Defs() setInteger:s.selectedSegmentIndex forKey:@"chrono.style"];
    [self.chrono applyConfig];
}

- (void)accentTapped:(UIButton *)b {
    [Defs() setInteger:b.tag forKey:@"chrono.accent"];
    [self refreshColorBtns];
    [self.chrono applyConfig];
}

- (void)lengthChanged:(UISlider *)s {
    double v = round(s.value);
    [Defs() setDouble:v forKey:@"chrono.length"];
    self.lenLabel.text = [NSString stringWithFormat:@"Longueur : %d", (int)v];
    [self.chrono applyConfig];
}

- (void)zoomChanged:(UISlider *)s {
    double v = round(s.value * 20.0) / 20.0;
    [Defs() setDouble:v forKey:@"chrono.zoom"];
    self.zoomLabel.text = [NSString stringWithFormat:@"Taille : %d%%", (int)round(v * 100)];
    [self.chrono applyConfig];
}

- (void)pickImage {
    ChronoView *c = self.chrono;
    [self dismiss];
    [c pickImage];
}

- (void)clearImage {
    [self.chrono clearImage];
}

- (void)fpsChanged:(UISwitch *)s {
    [Defs() setBool:s.isOn forKey:@"game.fps"];
    [[GameTools shared] setFPSEnabled:s.isOn];
}

- (void)resChanged:(UISegmentedControl *)s {
    [Defs() setInteger:s.selectedSegmentIndex forKey:@"game.res"];
    [[GameTools shared] applyResolution:s.selectedSegmentIndex];
}

- (void)satChanged:(UISlider *)s {
    double v = round(s.value);
    [Defs() setDouble:v forKey:@"game.sat"];
    self.satLabel.text = [NSString stringWithFormat:@"Saturation : %d (50 = normal)", (int)v];
    [[GameTools shared] applySaturation:v];
}

- (void)barChanged:(UISwitch *)s {
    [Defs() setBool:s.isOn forKey:@"game.hidebar"];
    [[GameTools shared] setStatusBarHidden:s.isOn];
}

- (void)copyHandle {
    [UIPasteboard generalPasteboard].string = @"g420262";
    [self.copyBtn setTitle:@"Copié ✓" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.copyBtn setTitle:@"Copier g420262" forState:UIControlStateNormal];
    });
}

@end

#pragma mark - Entrée du dylib

static ChronoView *gChrono = nil;

static void ShowBanner(UIWindow *w) {
    UILabel *l = [[UILabel alloc] init];
    l.text = @"dylib by Ragnar";
    l.font = [UIFont boldSystemFontOfSize:15];
    l.textColor = UIColor.whiteColor;
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:0 alpha:0.88];
    l.layer.cornerRadius = 14;
    l.layer.masksToBounds = YES;
    l.layer.borderWidth = 1;
    l.layer.borderColor = kBorder.CGColor;
    l.tag = kOverlayTag;
    l.userInteractionEnabled = NO;
    [l sizeToFit];
    CGFloat bw = l.bounds.size.width + 36;
    CGFloat bh = 34;
    l.frame = CGRectMake((w.bounds.size.width - bw) / 2, w.safeAreaInsets.top + 10, bw, bh);
    l.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    l.alpha = 0;
    [w addSubview:l];
    [UIView animateWithDuration:0.35 animations:^{ l.alpha = 1; } completion:^(BOOL f) {
        [UIView animateWithDuration:0.5 delay:2.5 options:0 animations:^{ l.alpha = 0; } completion:^(BOOL f2) {
            [l removeFromSuperview];
        }];
    }];
}

static void ShowChrono(void) {
    static int attempts = 0;
    if (gChrono) return;
    UIWindow *w = KeyWindow();
    if (!w) {
        if (attempts++ < 10) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ ShowChrono(); });
        }
        return;
    }
    gChrono = [[ChronoView alloc] initWithFrame:CGRectMake(20, 100, 240, 100)];
    [w addSubview:gChrono];
    [gChrono applyConfig];
    ShowBanner(w);
    [[GameTools shared] reapplyAll];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [[GameTools shared] reapplyAll]; });
}

__attribute__((constructor))
static void chrono_init(void) {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ ShowChrono(); });
    }];
}
