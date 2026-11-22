// Chrono v7.2 - dylib by Ragnar
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <stdint.h>
#import <string.h>
#import <strings.h>

#define COL(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define kOverlayTag 7777001

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

#pragma mark - Thèmes du menu (0 = Clair, 1 = Sombre, 2 = Noël)

static NSInteger ThemeIdx(void) { return DefInt(@"ui.theme", 0); }

static UIColor *ThBG(void) {
    switch (ThemeIdx()) { case 1: return COL(24,24,27); case 2: return COL(12,52,36); default: return COL(242,242,243); }
}
static UIColor *ThSec(void) {
    switch (ThemeIdx()) { case 1: return COL(40,40,45); case 2: return COL(20,78,53); default: return UIColor.whiteColor; }
}
static UIColor *ThText(void) {
    switch (ThemeIdx()) { case 1: return COL(245,245,247); case 2: return COL(255,248,240); default: return COL(17,17,19); }
}
static UIColor *ThSub(void) {
    switch (ThemeIdx()) { case 1: return COL(150,150,160); case 2: return COL(190,215,198); default: return COL(120,120,128); }
}
static UIColor *ThChip(void) {
    switch (ThemeIdx()) { case 1: return COL(60,60,66); case 2: return COL(34,98,68); default: return COL(229,229,231); }
}
static UIColor *ThAcc(void) {
    switch (ThemeIdx()) { case 2: return COL(204,42,48); default: return COL(99,91,224); }
}
static UIColor *ThLine(void) {
    switch (ThemeIdx()) { case 1: return COL(64,64,70); case 2: return COL(44,108,78); default: return COL(232,232,234); }
}
static UIColor *ThTabSel(void) {
    switch (ThemeIdx()) { case 1: return COL(92,92,100); case 2: return COL(204,42,48); default: return UIColor.whiteColor; }
}
static UIColor *ThTabSelText(void) {
    return (ThemeIdx() == 0) ? COL(17,17,19) : UIColor.whiteColor;
}

#pragma mark - Couleurs du chrono

static UIColor *AccentColor(NSInteger i) {
    switch (i) {
        case 1: return COL(52,152,219);
        case 2: return COL(231,76,60);
        case 3: return COL(155,89,182);
        case 4: return COL(241,196,15);
        case 5: return COL(255,255,255);
        default: return COL(0,204,54);
    }
}

static UIColor *BgColor(NSInteger i) {
    switch (i) {
        case 1: return COL(34,34,38);
        case 2: return COL(10,20,48);
        case 3: return COL(8,40,24);
        case 4: return COL(52,10,18);
        default: return COL(0,0,0);
    }
}

#pragma mark - Textes du chrono

static NSAttributedString *CellText(int n, NSString *unit, UIColor *col, CGFloat h) {
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%02d", n]
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:h * 0.42 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col}];
    [a appendAttributedString:[[NSAttributedString alloc]
        initWithString:unit
            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:h * 0.2 weight:UIFontWeightSemibold],
                         NSForegroundColorAttributeName: COL(160,160,168)}]];
    return a;
}

static UIColor *MixColor(UIColor *c, CGFloat t, CGFloat target) {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [c getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r + (target - r) * t green:g + (target - g) * t blue:b + (target - b) * t alpha:1.0];
}
static UIColor *GradTop(UIColor *c) { return MixColor(c, 0.28, 1.0); }
static UIColor *GradBottom(UIColor *c) { return MixColor(c, 0.38, 0.0); }

// Style LiveSplit : gros chiffre à droite, centièmes plus petits (ex : 0 .00)
static NSAttributedString *LiveSplitText(NSTimeInterval t, UIColor *col, CGFloat h) {
    if (t < 0) t = 0;
    int total = (int)t;
    int cs = (int)((t - floor(t)) * 100);
    NSString *mainS;
    if (total < 60) mainS = [NSString stringWithFormat:@"%d", total];
    else if (total < 3600) mainS = [NSString stringWithFormat:@"%d:%02d", total / 60, total % 60];
    else mainS = [NSString stringWithFormat:@"%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60];
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc]
        initWithString:mainS
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:h * 0.86 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col}];
    [a appendAttributedString:[[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@".%02d", cs]
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:h * 0.51 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col}]];
    return a;
}

static NSString *PlainTime(NSTimeInterval t) {
    if (t < 0) t = 0;
    int total = (int)t;
    int cs = (int)((t - floor(t)) * 100);
    if (total < 3600) return [NSString stringWithFormat:@"%02d:%02d.%02d", total / 60, total % 60, cs];
    return [NSString stringWithFormat:@"%d:%02d:%02d.%02d", total / 3600, (total % 3600) / 60, total % 60, cs];
}

// Style iOS Timer : chiffres fins centrés
static NSAttributedString *IOSTimerText(NSTimeInterval t, UIColor *col, CGFloat h) {
    return [[NSAttributedString alloc]
        initWithString:PlainTime(t)
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:h * 0.62 weight:UIFontWeightLight],
                         NSForegroundColorAttributeName: col}];
}

// Style texte seul : chiffres gras avec ombre
static NSAttributedString *TextOnlyText(NSTimeInterval t, UIColor *col, CGFloat h) {
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [UIColor colorWithWhite:0 alpha:0.85];
    sh.shadowOffset = CGSizeMake(0, 1);
    sh.shadowBlurRadius = 4;
    return [[NSAttributedString alloc]
        initWithString:PlainTime(t)
            attributes:@{NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:h * 0.7 weight:UIFontWeightBold],
                         NSForegroundColorAttributeName: col,
                         NSShadowAttributeName: sh}];
}

#pragma mark - Composants du menu

static UILabel *MkLabel(UIView *p, NSString *t, CGRect f, CGFloat size, UIFontWeight w, UIColor *c) {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.textColor = c;
    l.numberOfLines = 0;
    l.font = [UIFont systemFontOfSize:size weight:w];
    [p addSubview:l];
    return l;
}

static UIButton *MkButton(UIView *p, NSString *t, CGRect f, UIColor *bg, UIColor *fg, CGFloat size, id target, SEL sel) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = f;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:fg forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
    b.backgroundColor = bg;
    b.layer.cornerRadius = f.size.height / 2;
    if (target) [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    [p addSubview:b];
    return b;
}

static UIView *MkSection(UIView *p, CGFloat y, CGFloat pageW, CGFloat h) {
    UIView *s = [[UIView alloc] initWithFrame:CGRectMake(16, y, pageW - 32, h)];
    s.backgroundColor = ThSec();
    s.layer.cornerRadius = 20;
    [p addSubview:s];
    return s;
}

static void SetH(UIView *v, CGFloat h) {
    CGRect f = v.frame;
    f.size.height = h;
    v.frame = f;
}

static void MkLine(UIView *p, CGFloat y) {
    UIView *l = [[UIView alloc] initWithFrame:CGRectMake(18, y, p.bounds.size.width - 36, 1)];
    l.backgroundColor = ThLine();
    [p addSubview:l];
}

static void StyleChip(UIButton *b, BOOL sel) {
    b.backgroundColor = sel ? ThAcc() : ThChip();
    [b setTitleColor:(sel ? UIColor.whiteColor : ThText()) forState:UIControlStateNormal];
}

static UITextField *MkField(UIView *p, CGRect f, NSString *placeholder, NSString *text) {
    UITextField *t = [[UITextField alloc] initWithFrame:f];
    t.backgroundColor = ThChip();
    t.textColor = ThText();
    t.tintColor = ThAcc();
    t.font = [UIFont systemFontOfSize:16];
    t.layer.cornerRadius = 12;
    t.text = text;
    t.autocorrectionType = UITextAutocorrectionTypeNo;
    t.autocapitalizationType = UITextAutocapitalizationTypeNone;
    t.returnKeyType = UIReturnKeyDone;
    t.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
        attributes:@{NSForegroundColorAttributeName: ThSub()}];
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    t.leftView = pad;
    t.leftViewMode = UITextFieldViewModeAlways;
    [p addSubview:t];
    return t;
}

static NSString *SliderText(NSString *g, double v) {
    if ([g isEqualToString:@"opacity"] || [g isEqualToString:@"zoom"])
        return [NSString stringWithFormat:@"%d%%", (int)round(v * 100)];
    if ([g isEqualToString:@"width"] || [g isEqualToString:@"height"])
        return [NSString stringWithFormat:@"%d px", (int)round(v)];
    return [NSString stringWithFormat:@"%d", (int)round(v)];
}

static UIImage *SnowDot(void) {
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(12, 12)];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [UIColor.whiteColor setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 12, 12)] fill];
    }];
}

#pragma mark - Pont IL2CPP (moteur Unity)

typedef struct {
    void *(*domain_get)(void);
    void *(*thread_attach)(void *);
    void **(*domain_get_assemblies)(void *, size_t *);
    void *(*assembly_get_image)(void *);
    const char *(*image_get_name)(void *);
    size_t (*image_get_class_count)(void *);
    void *(*image_get_class)(void *, size_t);
    const char *(*class_get_name)(void *);
    const char *(*class_get_namespace)(void *);
    void *(*class_from_name)(void *, const char *, const char *);
    void *(*class_get_method_from_name)(void *, const char *, int);
    void *(*class_get_methods)(void *, void **);
    const char *(*method_get_name)(void *);
    void *(*runtime_invoke)(void *, void *, void **, void **);
    void *(*class_get_type)(void *);
    void *(*type_get_object)(void *);
    uint16_t *(*string_chars)(void *);
    int (*string_length)(void *);
    uint32_t (*gchandle_new)(void *, int);
    void *(*gchandle_get_target)(uint32_t);
    void (*gchandle_free)(uint32_t);
    BOOL ok;
} Il2Api;

static Il2Api gIl;

static BOOL Il2Ready(void) {
    typedef void *(*DomFn)(void);
    DomFn d = (DomFn)dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
    return (d != NULL) && (d() != NULL);
}

static BOOL Il2Load(void) {
    if (gIl.ok) return YES;
    if (!Il2Ready()) return NO;
#define L(f, n) gIl.f = (__typeof__(gIl.f))dlsym(RTLD_DEFAULT, n)
    L(domain_get, "il2cpp_domain_get");
    L(thread_attach, "il2cpp_thread_attach");
    L(domain_get_assemblies, "il2cpp_domain_get_assemblies");
    L(assembly_get_image, "il2cpp_assembly_get_image");
    L(image_get_name, "il2cpp_image_get_name");
    L(image_get_class_count, "il2cpp_image_get_class_count");
    L(image_get_class, "il2cpp_image_get_class");
    L(class_get_name, "il2cpp_class_get_name");
    L(class_get_namespace, "il2cpp_class_get_namespace");
    L(class_from_name, "il2cpp_class_from_name");
    L(class_get_method_from_name, "il2cpp_class_get_method_from_name");
    L(class_get_methods, "il2cpp_class_get_methods");
    L(method_get_name, "il2cpp_method_get_name");
    L(runtime_invoke, "il2cpp_runtime_invoke");
    L(class_get_type, "il2cpp_class_get_type");
    L(type_get_object, "il2cpp_type_get_object");
    L(string_chars, "il2cpp_string_chars");
    L(string_length, "il2cpp_string_length");
    L(gchandle_new, "il2cpp_gchandle_new");
    L(gchandle_get_target, "il2cpp_gchandle_get_target");
    L(gchandle_free, "il2cpp_gchandle_free");
#undef L
    gIl.ok = (gIl.domain_get && gIl.domain_get_assemblies && gIl.assembly_get_image && gIl.image_get_name &&
              gIl.image_get_class_count && gIl.image_get_class && gIl.class_get_name &&
              gIl.class_get_namespace && gIl.class_get_methods && gIl.method_get_name);
    if (gIl.ok && gIl.thread_attach) gIl.thread_attach(gIl.domain_get());
    return gIl.ok;
}

static void *Il2FindClass(const char *ns, const char *name) {
    if (!gIl.class_from_name) return NULL;
    size_t n = 0;
    void **asms = gIl.domain_get_assemblies(gIl.domain_get(), &n);
    if (!asms) return NULL;
    for (size_t i = 0; i < n; i++) {
        void *img = gIl.assembly_get_image(asms[i]);
        void *k = img ? gIl.class_from_name(img, ns, name) : NULL;
        if (k) return k;
    }
    return NULL;
}

// --- Vitesse du jeu (Time.timeScale) ---
typedef void (*SetTimeScaleFn)(float);
typedef float (*GetTimeScaleFn)(void);
typedef void *(*ResolveIcallFn)(const char *);

static BOOL TimeScaleAvailable(void) {
    return dlsym(RTLD_DEFAULT, "il2cpp_resolve_icall") != NULL;
}

static void SetUnityTimeScale(float v) {
    static SetTimeScaleFn fn = NULL;
    if (!Il2Ready()) return;
    if (!fn) {
        ResolveIcallFn r = (ResolveIcallFn)dlsym(RTLD_DEFAULT, "il2cpp_resolve_icall");
        if (r) fn = (SetTimeScaleFn)r("UnityEngine.Time::set_timeScale(System.Single)");
    }
    if (fn) fn(v);
}

static float GetUnityTimeScale(void) {
    static GetTimeScaleFn fn = NULL;
    if (!Il2Ready()) return -1.0f;
    if (!fn) {
        ResolveIcallFn r = (ResolveIcallFn)dlsym(RTLD_DEFAULT, "il2cpp_resolve_icall");
        if (r) fn = (GetTimeScaleFn)r("UnityEngine.Time::get_timeScale()");
    }
    return fn ? fn() : -1.0f;
}

static float BlitzMultiplier(void) {
    NSInteger i = DefInt(@"game.blitzmul", 2);
    return (i == 0) ? 1.5f : ((i == 1) ? 2.0f : 3.0f);
}

// --- Pièces invisibles (recherche des Renderer dont le nom contient un mot-clé) ---
typedef struct {
    BOOL ready;
    void *rendererTypeObj;
    void *findObjects;
    void *getGO;
    void *getName;
    void *setEnabled;
    char keyword[64];
} CoinCtx;

static CoinCtx gCoin;

static BOOL Il2CoinSetup(void) {
    if (gCoin.ready) return YES;
    if (!Il2Load()) return NO;
    if (!gIl.class_from_name || !gIl.class_get_method_from_name || !gIl.runtime_invoke ||
        !gIl.class_get_type || !gIl.type_get_object || !gIl.string_chars || !gIl.string_length ||
        !gIl.gchandle_new || !gIl.gchandle_get_target || !gIl.gchandle_free) return NO;
    void *kRenderer = Il2FindClass("UnityEngine", "Renderer");
    void *kObject = Il2FindClass("UnityEngine", "Object");
    void *kComponent = Il2FindClass("UnityEngine", "Component");
    if (!kRenderer || !kObject || !kComponent) return NO;
    void *t = gIl.class_get_type(kRenderer);
    gCoin.rendererTypeObj = t ? gIl.type_get_object(t) : NULL;
    gCoin.findObjects = gIl.class_get_method_from_name(kObject, "FindObjectsOfType", 1);
    gCoin.getName = gIl.class_get_method_from_name(kObject, "get_name", 0);
    gCoin.getGO = gIl.class_get_method_from_name(kComponent, "get_gameObject", 0);
    gCoin.setEnabled = gIl.class_get_method_from_name(kRenderer, "set_enabled", 1);
    if (!gCoin.rendererTypeObj || !gCoin.findObjects || !gCoin.getName || !gCoin.getGO || !gCoin.setEnabled) return NO;
    gCoin.ready = YES;
    return YES;
}

static BOOL ContainsCI(const uint16_t *s, int len, const char *needle) {
    int nl = (int)strlen(needle);
    if (nl == 0 || len < nl) return NO;
    for (int i = 0; i <= len - nl; i++) {
        int j = 0;
        for (; j < nl; j++) {
            uint16_t c = s[i + j];
            char n = needle[j];
            if (c >= 'A' && c <= 'Z') c = (uint16_t)(c + 32);
            if (n >= 'A' && n <= 'Z') n = (char)(n + 32);
            if (c != (uint16_t)n) break;
        }
        if (j == nl) return YES;
    }
    return NO;
}

#pragma mark - Interfaces

@interface GameTools : NSObject
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *fpsLink;
@property (nonatomic) CFTimeInterval lastStamp;
@property (nonatomic) int frames;
@property (nonatomic, strong) UIButton *blitzBtn;
@property (nonatomic) BOOL blitzOn;
@property (nonatomic) BOOL blitzForce;
@property (nonatomic, strong) CADisplayLink *logicLink;
@property (nonatomic) BOOL coinsHidden;
@property (nonatomic) BOOL coinsRestore;
@property (nonatomic) BOOL coinHasArray;
@property (nonatomic) uint32_t coinHandle;
@property (nonatomic) long coinIndex;
@property (nonatomic) long coinCount;
@property (nonatomic) CFTimeInterval coinLastFetch;
+ (instancetype)shared;
- (void)setFPSEnabled:(BOOL)on;
- (void)applyResolution:(NSInteger)idx;
- (void)applySaturation:(double)v;
- (void)setStatusBarHidden:(BOOL)on;
- (void)setBlitzEnabled:(BOOL)on;
- (void)applyBlitz;
- (void)setCoinsHidden:(BOOL)on;
- (void)coinKeywordChanged;
- (NSString *)unityStatus;
- (NSString *)coinStatus;
- (NSString *)searchClasses:(NSString *)kw;
- (void)reapplyAll;
@end

@interface ChronoView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UILabel *xmasLabel;
@property (nonatomic, strong) UIView *box;
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) NSArray<UIView *> *cells;
@property (nonatomic, strong) NSArray<UILabel *> *cellLabels;
@property (nonatomic, strong) UILabel *mainLabel;
@property (nonatomic, strong) CAGradientLayer *gradLayer;
@property (nonatomic, strong) CALayer *maskLayer;
@property (nonatomic) NSInteger style;
@property (nonatomic) NSInteger accent;
@property (nonatomic) NSInteger bgIdx;
@property (nonatomic) BOOL showBg;
@property (nonatomic) BOOL stretchOn;
@property (nonatomic) CGFloat timerW;
@property (nonatomic) CGFloat timerH;
@property (nonatomic) CGFloat zoomVal;
@property (nonatomic) CGFloat opacityVal;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval accumulated;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) BOOL running;
- (void)applyConfig;
- (void)pickImage;
- (void)clearImage;
@end

@interface SettingsView : UIView <UIGestureRecognizerDelegate, UITextFieldDelegate>
@property (nonatomic, weak) ChronoView *chrono;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) NSArray<UIScrollView *> *pages;
@property (nonatomic, strong) NSArray<UIButton *> *tabBtns;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UILabel *> *valueLabels;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *coinStatusLabel;
@property (nonatomic, strong) UIView *subPage;
@property (nonatomic, strong) UIButton *subCopyBtn;
@property (nonatomic, strong) UIButton *pseudoBtn;
@property (nonatomic, strong) UITextField *exField;
@property (nonatomic, strong) UITextView *exView;
@property (nonatomic) NSInteger currentTab;
@property (nonatomic) CGFloat cardW;
@property (nonatomic) CGFloat cardH;
@property (nonatomic) CGFloat footerH;
- (instancetype)initWithFrame:(CGRect)f chrono:(ChronoView *)c;
- (void)selectTab:(NSInteger)i;
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

#pragma mark FPS

- (void)setFPSEnabled:(BOOL)on {
    if (on) {
        UIWindow *w = KeyWindow();
        if (!w) return;
        if (!self.fpsLabel) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 76, 22)];
            l.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightBold];
            l.textColor = COL(46,204,113);
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
        if (!self.fpsLink) {
            self.lastStamp = 0;
            self.frames = 0;
            self.fpsLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsTick:)];
            [self.fpsLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
    } else {
        [self.fpsLink invalidate];
        self.fpsLink = nil;
        self.fpsLabel.hidden = YES;
    }
}

- (void)fpsTick:(CADisplayLink *)l {
    if (self.lastStamp == 0) { self.lastStamp = l.timestamp; return; }
    self.frames += 1;
    CFTimeInterval dt = l.timestamp - self.lastStamp;
    if (dt >= 0.5) {
        self.fpsLabel.text = [NSString stringWithFormat:@"%d FPS", (int)round(self.frames / dt)];
        self.frames = 0;
        self.lastStamp = l.timestamp;
    }
}

#pragma mark Résolution / saturation / barre d'état

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

#pragma mark Boucle logique (Blitz + pièces)

- (void)updateLogicLink {
    BOOL need = (self.blitzOn || self.coinsHidden || self.coinsRestore);
    if (need && !self.logicLink) {
        self.logicLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(logicTick:)];
        self.logicLink.preferredFramesPerSecond = 30;
        [self.logicLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else if (!need && self.logicLink) {
        [self.logicLink invalidate];
        self.logicLink = nil;
    }
}

- (void)logicTick:(CADisplayLink *)l {
    if (self.blitzOn && self.blitzForce) {
        float cur = GetUnityTimeScale();
        // On accélère seulement quand le jeu tourne à vitesse normale (1.0) : on ne touche pas à la pause (0).
        if (cur > 0.99f && cur < 1.01f) SetUnityTimeScale(BlitzMultiplier());
    }
    if (self.coinsHidden || self.coinsRestore) [self coinStep];
}

#pragma mark Blitz

- (void)updateBlitzTitle {
    if (!self.blitzBtn) return;
    if (self.blitzForce) {
        [self.blitzBtn setTitle:@"⚡ BLITZ" forState:UIControlStateNormal];
        [self.blitzBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        self.blitzBtn.backgroundColor = COL(46,204,113);
    } else {
        [self.blitzBtn setTitle:@"⚡ NORMAL" forState:UIControlStateNormal];
        [self.blitzBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.blitzBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.78];
    }
}

- (void)toggleBlitz {
    self.blitzForce = !self.blitzForce;
    if (!self.blitzForce) {
        float cur = GetUnityTimeScale();
        if (cur > 1.01f) SetUnityTimeScale(1.0f);
    } else {
        float cur = GetUnityTimeScale();
        if (cur < 0 || (cur > 0.99f && cur < 1.01f)) SetUnityTimeScale(BlitzMultiplier());
    }
    [self updateBlitzTitle];
}

- (void)dragBlitz:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    UIView *sup = v.superview;
    if (!sup) return;
    CGPoint d = [g translationInView:sup];
    v.center = CGPointMake(v.center.x + d.x, v.center.y + d.y);
    [g setTranslation:CGPointZero inView:sup];
}

- (void)applyBlitz {
    if (!(self.blitzOn && self.blitzForce)) return;
    float cur = GetUnityTimeScale();
    if (cur > 1.01f) SetUnityTimeScale(BlitzMultiplier());
}

- (void)setBlitzEnabled:(BOOL)on {
    if (on) {
        UIWindow *w = KeyWindow();
        if (!w) return;
        self.blitzOn = YES;
        self.blitzForce = YES;
        if (!self.blitzBtn) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(0, 0, 112, 36);
            b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            b.layer.cornerRadius = 18;
            b.layer.borderWidth = 1;
            b.layer.borderColor = COL(58,58,62).CGColor;
            b.tag = kOverlayTag;
            [b addTarget:self action:@selector(toggleBlitz) forControlEvents:UIControlEventTouchUpInside];
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragBlitz:)];
            [b addGestureRecognizer:pan];
            b.center = CGPointMake(w.bounds.size.width - 74, w.bounds.size.height * 0.45);
            self.blitzBtn = b;
        }
        if (self.blitzBtn.superview != w) [w addSubview:self.blitzBtn];
        self.blitzBtn.hidden = NO;
        [self updateBlitzTitle];
        float cur = GetUnityTimeScale();
        if (cur < 0 || (cur > 0.99f && cur < 1.01f)) SetUnityTimeScale(BlitzMultiplier());
    } else {
        float cur = GetUnityTimeScale();
        if (self.blitzOn && cur > 1.01f) SetUnityTimeScale(1.0f);
        self.blitzOn = NO;
        self.blitzBtn.hidden = YES;
    }
    [self updateLogicLink];
}

#pragma mark Pièces invisibles

- (void)coinKeywordChanged {
    NSString *k = [Defs() stringForKey:@"game.coinkey"];
    if (k.length == 0) k = @"coin";
    strncpy(gCoin.keyword, k.UTF8String, sizeof(gCoin.keyword) - 1);
    gCoin.keyword[sizeof(gCoin.keyword) - 1] = 0;
}

- (void)setCoinsHidden:(BOOL)on {
    [self coinKeywordChanged];
    if (on) {
        self.coinsHidden = YES;
        self.coinsRestore = NO;
    } else {
        if (self.coinsHidden) self.coinsRestore = YES;
        self.coinsHidden = NO;
    }
    [self updateLogicLink];
}

- (void)coinStep {
    if (!Il2CoinSetup()) return;
    BOOL enabledFlag = self.coinsHidden ? NO : YES;
    CFTimeInterval now = CACurrentMediaTime();
    if (!self.coinHasArray) {
        if (now - self.coinLastFetch < 1.0) return;
        self.coinLastFetch = now;
        void *exc = NULL;
        void *params[1] = { gCoin.rendererTypeObj };
        void *arr = gIl.runtime_invoke(gCoin.findObjects, NULL, params, &exc);
        if (!arr || exc) {
            if (!self.coinsHidden) { self.coinsRestore = NO; [self updateLogicLink]; }
            return;
        }
        self.coinHandle = gIl.gchandle_new(arr, 0);
        self.coinHasArray = YES;
        self.coinIndex = 0;
        long cnt = (long)(*(uint64_t *)((char *)arr + 0x18));
        if (cnt > 20000) cnt = 20000;
        self.coinCount = cnt;
    }
    void *arr = gIl.gchandle_get_target(self.coinHandle);
    if (!arr) { self.coinHasArray = NO; return; }
    long end = self.coinIndex + 150;
    if (end > self.coinCount) end = self.coinCount;
    for (long i = self.coinIndex; i < end; i++) {
        void *r = *(void **)((char *)arr + 0x20 + i * 8);
        if (!r) continue;
        void *exc = NULL;
        void *go = gIl.runtime_invoke(gCoin.getGO, r, NULL, &exc);
        if (!go || exc) continue;
        exc = NULL;
        void *nameStr = gIl.runtime_invoke(gCoin.getName, go, NULL, &exc);
        if (!nameStr || exc) continue;
        int len = gIl.string_length(nameStr);
        const uint16_t *chars = gIl.string_chars(nameStr);
        if (chars && ContainsCI(chars, len, gCoin.keyword)) {
            uint8_t flag = enabledFlag ? 1 : 0;
            void *args[1] = { &flag };
            exc = NULL;
            gIl.runtime_invoke(gCoin.setEnabled, r, args, &exc);
        }
    }
    self.coinIndex = end;
    if (self.coinIndex >= self.coinCount) {
        gIl.gchandle_free(self.coinHandle);
        self.coinHasArray = NO;
        if (!self.coinsHidden) {
            self.coinsRestore = NO;
            [self updateLogicLink];
        }
    }
}

#pragma mark Diagnostic et explorateur

- (NSString *)unityStatus {
    if (!TimeScaleAvailable()) return @"Unity : non détecté ✗ (le Blitz ne marchera pas)";
    float cur = GetUnityTimeScale();
    if (cur < 0) return @"Unity : détecté, mais la vitesse est illisible ✗";
    return [NSString stringWithFormat:@"Unity : connecté ✓ (vitesse actuelle x%.1f)", cur];
}

- (NSString *)coinStatus {
    if (!Il2Load()) return @"Pièces : fonctions IL2CPP introuvables ✗";
    if (!Il2CoinSetup()) return @"Pièces : IL2CPP trouvé, mais méthodes manquantes ✗";
    return @"Pièces : prêt ✓";
}

- (NSString *)searchClasses:(NSString *)kw {
    if (!Il2Load()) return @"IL2CPP introuvable : les fonctions du moteur Unity sont masquées dans ce jeu.";
    if (kw.length < 2) return @"Tape au moins 2 lettres (ex : coin, speed, player).";
    const char *q = kw.UTF8String;
    if (gIl.thread_attach) gIl.thread_attach(gIl.domain_get());
    NSMutableString *out = [NSMutableString string];
    size_t n = 0;
    void **asms = gIl.domain_get_assemblies(gIl.domain_get(), &n);
    if (!asms) return @"Aucune assembly trouvée.";
    int found = 0;
    for (size_t i = 0; i < n && found < 40; i++) {
        void *img = gIl.assembly_get_image(asms[i]);
        if (!img) continue;
        const char *iname = gIl.image_get_name(img);
        if (!iname) continue;
        if (strncmp(iname, "System", 6) == 0 || strncmp(iname, "mscorlib", 8) == 0 || strncmp(iname, "Mono", 4) == 0) continue;
        size_t cc = gIl.image_get_class_count(img);
        for (size_t j = 0; j < cc && found < 40; j++) {
            void *k = gIl.image_get_class(img, j);
            if (!k) continue;
            const char *cn = gIl.class_get_name(k);
            if (!cn || !strcasestr(cn, q)) continue;
            const char *ns = gIl.class_get_namespace(k);
            NSMutableArray *ms = [NSMutableArray array];
            void *iter = NULL;
            void *m = NULL;
            int mc = 0;
            while ((m = gIl.class_get_methods(k, &iter)) != NULL) {
                const char *mn = gIl.method_get_name(m);
                if (mn && mc < 14) [ms addObject:[NSString stringWithUTF8String:mn]];
                mc++;
                if (mc > 400) break;
            }
            [out appendFormat:@"[%s] %s%s%s { %@%@ }\n\n", iname,
                (ns && ns[0]) ? ns : "", (ns && ns[0]) ? "." : "", cn,
                [ms componentsJoinedByString:@", "], (mc > 14) ? [NSString stringWithFormat:@" … +%d", mc - 14] : @""];
            found++;
        }
    }
    if (found == 0) return @"Aucune classe trouvée pour ce mot-clé.";
    if (found >= 40) [out appendString:@"(40 premiers résultats : précise ton mot-clé)"];
    return out;
}

- (void)reapplyAll {
    if (DefBool(@"game.blitz", NO)) [self setBlitzEnabled:YES];
    if (DefBool(@"game.coins", NO)) [self setCoinsHidden:YES];
    if (DefBool(@"game.fps", NO)) [self setFPSEnabled:YES];
    if ([Defs() objectForKey:@"game.res"]) [self applyResolution:DefInt(@"game.res", 2)];
    if (fabs(DefFloat(@"game.sat", 50) - 50.0) > 0.5) [self applySaturation:DefFloat(@"game.sat", 50)];
    if (DefBool(@"game.hidebar", NO)) [self setStatusBarHidden:YES];
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
        _titleField.font = [UIFont boldSystemFontOfSize:15];
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

        _xmasLabel = [[UILabel alloc] init];
        _xmasLabel.text = @"🎄";
        _xmasLabel.font = [UIFont systemFontOfSize:18];
        _xmasLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_xmasLabel];

        // Zone du chrono
        _box = [[UIView alloc] init];
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

        // Style "Chrono" : trois cases
        NSMutableArray *cells = [NSMutableArray array];
        NSMutableArray *labels = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            UIView *c = [[UIView alloc] init];
            c.layer.cornerRadius = 12;
            UILabel *l = [[UILabel alloc] init];
            l.textAlignment = NSTextAlignmentCenter;
            l.adjustsFontSizeToFitWidth = YES;
            l.minimumScaleFactor = 0.4;
            [c addSubview:l];
            [_box addSubview:c];
            [cells addObject:c];
            [labels addObject:l];
        }
        _cells = cells;
        _cellLabels = labels;

        // Autres styles : un seul texte
        _mainLabel = [[UILabel alloc] init];
        _mainLabel.adjustsFontSizeToFitWidth = YES;
        _mainLabel.minimumScaleFactor = 0.3;
        [_box addSubview:_mainLabel];

        // Style LiveSplit : texte rempli avec un dégradé vertical
        _gradLayer = [CAGradientLayer layer];
        _gradLayer.startPoint = CGPointMake(0.5, 0);
        _gradLayer.endPoint = CGPointMake(0.5, 1);
        _maskLayer = [CALayer layer];
        _gradLayer.mask = _maskLayer;
        [_box.layer addSublayer:_gradLayer];

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
    self.style = DefInt(@"chrono.style", 1);
    self.accent = DefInt(@"chrono.accent", 0);
    self.bgIdx = DefInt(@"chrono.bgcolor", 0);
    self.showBg = DefBool(@"chrono.showbg", YES);
    self.stretchOn = DefBool(@"chrono.stretch", NO);
    self.timerW = (CGFloat)MAX(120.0, MIN(420.0, DefFloat(@"chrono.width", 252)));
    self.timerH = (CGFloat)MAX(36.0, MIN(120.0, DefFloat(@"chrono.height", 56)));
    self.zoomVal = (CGFloat)MAX(0.5, MIN(1.5, DefFloat(@"chrono.zoom", 1.0)));
    self.opacityVal = (CGFloat)MAX(0.2, MIN(1.0, DefFloat(@"chrono.opacity", 1.0)));
    [self relayout];
    [self refreshBackground];
    [self refresh];
    [self applyZoom];
}

- (void)relayout {
    CGFloat titleH = 26.0;
    UIWindow *kw = KeyWindow();
    CGFloat sw = kw ? kw.bounds.size.width : [UIScreen mainScreen].bounds.size.width;
    CGFloat W = self.stretchOn ? (sw - 16.0) / self.zoomVal : self.timerW;
    CGFloat H = self.timerH;
    self.bounds = CGRectMake(0, 0, W, titleH + H);
    self.titleField.frame = CGRectMake(0, 0, W - 30, titleH);
    self.xmasLabel.frame = CGRectMake(W - 30, 0, 30, titleH);
    self.xmasLabel.hidden = (ThemeIdx() != 2);
    self.box.frame = CGRectMake(0, titleH, W, H);
    self.bgImageView.frame = self.box.bounds;
    self.dimView.frame = self.box.bounds;

    BOOL cellsStyle = (self.style == 0);
    CGFloat cw = (W - 16.0) / 3.0;
    for (NSInteger i = 0; i < 3; i++) {
        UIView *c = self.cells[i];
        c.hidden = !cellsStyle;
        c.frame = CGRectMake(i * (cw + 8.0), 0, cw, H);
        self.cellLabels[i].frame = c.bounds;
    }
    BOOL lsStyle = (self.style == 1);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.gradLayer.hidden = !lsStyle;
    self.gradLayer.frame = self.box.bounds;
    self.maskLayer.frame = self.gradLayer.bounds;
    [CATransaction commit];
    self.mainLabel.hidden = (cellsStyle || lsStyle);
    self.mainLabel.frame = CGRectMake(8, 0, W - 16, H);
    self.mainLabel.textAlignment = (self.style == 1) ? NSTextAlignmentRight : NSTextAlignmentCenter;
    self.box.alpha = self.opacityVal;
}

- (void)refreshBackground {
    UIColor *bg = BgColor(self.bgIdx);
    BOOL show = self.showBg;
    BOOL xmas = (ThemeIdx() == 2);
    BOOL hasImg = (self.bgImageView.image != nil) && show && self.style != 3;
    self.bgImageView.hidden = !hasImg;
    self.dimView.hidden = !hasImg;

    UIColor *cellBg = show ? [bg colorWithAlphaComponent:0.92] : UIColor.clearColor;
    for (UIView *c in self.cells) {
        c.backgroundColor = cellBg;
        c.layer.borderWidth = (show || xmas) ? 1 : 0;
        c.layer.borderColor = (xmas ? COL(204,42,48) : COL(46,46,50)).CGColor;
    }
    self.box.layer.borderWidth = 0;
    switch (self.style) {
        case 0:
            self.box.backgroundColor = UIColor.clearColor;
            self.box.layer.cornerRadius = 12;
            break;
        case 1:
            self.box.backgroundColor = show ? bg : UIColor.clearColor;
            self.box.layer.cornerRadius = 0;
            break;
        case 2:
            self.box.backgroundColor = show ? ((self.bgIdx == 0) ? COL(28,28,30) : bg) : UIColor.clearColor;
            self.box.layer.cornerRadius = MIN(18.0, self.timerH / 2.0);
            break;
        default:
            self.box.backgroundColor = UIColor.clearColor;
            self.box.layer.cornerRadius = 0;
            break;
    }
    if (xmas && (self.style == 1 || self.style == 2)) {
        self.box.layer.borderWidth = 2;
        self.box.layer.borderColor = COL(204,42,48).CGColor;
    }
}

- (void)applyZoom {
    CGFloat z = self.zoomVal;
    self.transform = CGAffineTransformMakeScale(z, z);
    [self setScaleFactor:[UIScreen mainScreen].scale * z onView:self];
    if (self.stretchOn && self.superview) {
        self.center = CGPointMake(self.superview.bounds.size.width / 2, self.center.y);
    }
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
    UIColor *idleCol = (self.style == 1) ? COL(172,172,172) : UIColor.whiteColor;
    UIColor *pauseCol = (self.style == 1) ? COL(122,122,122) : COL(243,156,18);
    UIColor *col = self.running ? AccentColor(self.accent) : (idle ? idleCol : pauseCol);
    if (self.style == 0) {
        int total = (int)t;
        NSArray *vals = @[@(total / 3600), @((total % 3600) / 60), @(total % 60)];
        NSArray *units = @[@"h", @"m", @"s"];
        for (NSInteger i = 0; i < 3; i++) {
            self.cellLabels[i].attributedText = CellText([vals[i] intValue], units[i], col, self.timerH);
        }
    } else if (self.style == 1) {
        [self renderLiveSplit:t color:col];
    } else if (self.style == 2) {
        self.mainLabel.attributedText = IOSTimerText(t, col, self.timerH);
    } else {
        self.mainLabel.attributedText = TextOnlyText(t, col, self.timerH);
    }
}

- (void)renderLiveSplit:(NSTimeInterval)t color:(UIColor *)col {
    CGSize size = self.box.bounds.size;
    if (size.width < 10 || size.height < 10) return;
    CGFloat scale = [UIScreen mainScreen].scale * self.zoomVal;
    CGFloat maxW = size.width - 24.0;
    NSAttributedString *a = LiveSplitText(t, UIColor.whiteColor, self.timerH);
    CGSize ts = [a boundingRectWithSize:CGSizeMake(10000, 10000) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    if (ts.width > maxW && ts.width > 1) {
        a = LiveSplitText(t, UIColor.whiteColor, self.timerH * maxW / ts.width);
        ts = [a boundingRectWithSize:CGSizeMake(10000, 10000) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    }
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat preferredFormat];
    fmt.scale = scale;
    fmt.opaque = NO;
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:size format:fmt];
    UIImage *img = [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [a drawAtPoint:CGPointMake(size.width - 12.0 - ts.width, (size.height - ts.height) / 2.0)];
    }];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.maskLayer.contentsScale = scale;
    self.maskLayer.contents = (id)img.CGImage;
    self.gradLayer.colors = @[(id)GradTop(col).CGColor, (id)GradBottom(col).CGColor];
    [CATransaction commit];
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

static UIButton *MkCircle(UIView *p, NSString *t, CGRect f, id target, SEL sel) {
    UIButton *b = MkButton(p, t, f, ThChip(), ThText(), 20, target, sel);
    b.layer.cornerRadius = f.size.width / 2;
    return b;
}

@implementation SettingsView

- (instancetype)initWithFrame:(CGRect)f chrono:(ChronoView *)c {
    if ((self = [super initWithFrame:f])) {
        _chrono = c;
        _valueLabels = [NSMutableDictionary dictionary];
        self.tag = kOverlayTag;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.overrideUserInterfaceStyle = (ThemeIdx() == 0) ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;

        UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        t.delegate = self;
        [self addGestureRecognizer:t];

        CGFloat cw = MIN(380.0, f.size.width - 24.0);
        CGFloat ch = MIN(620.0, f.size.height - 40.0);
        _cardW = cw;
        _cardH = ch;
        _footerH = (ch < 460.0) ? 0.0 : 70.0;
        _card = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - cw) / 2, (f.size.height - ch) / 2, cw, ch)];
        _card.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                 UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _card.backgroundColor = ThBG();
        _card.layer.cornerRadius = 28;
        _card.clipsToBounds = YES;
        [self addSubview:_card];

        [self buildHeader];
        [self buildTabs];
        [self buildPages];
        [self buildFooter];
        [self selectTab:0];
        if (ThemeIdx() == 2) [self addSnow];
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

#pragma mark Structure

- (void)buildHeader {
    CGFloat cw = self.cardW;
    NSString *title = (ThemeIdx() == 2) ? @"🎄 Réglages" : @"Réglages";
    MkLabel(self.card, title, CGRectMake(20, 14, cw - 180, 44), 26, UIFontWeightBold, ThText());
    CGFloat bx = cw - 16 - 44;
    MkCircle(self.card, @"✕", CGRectMake(bx, 14, 44, 44), self, @selector(dismiss));
    MkCircle(self.card, @"♪", CGRectMake(bx - 52, 14, 44, 44), self, @selector(openTikTok));
    NSString *ic = (ThemeIdx() == 0) ? @"☀︎" : ((ThemeIdx() == 1) ? @"☾" : @"❄︎");
    MkCircle(self.card, ic, CGRectMake(bx - 104, 14, 44, 44), self, @selector(themeTapped));
}

- (void)buildTabs {
    CGFloat cw = self.cardW;
    UIView *pill = [[UIView alloc] initWithFrame:CGRectMake(16, 68, cw - 32, 46)];
    pill.backgroundColor = ThChip();
    pill.layer.cornerRadius = 23;
    [self.card addSubview:pill];
    NSArray *titles = @[@"Timer", @"Jeu", @"Écran", @"Image", @"Aide"];
    CGFloat tw = (cw - 32 - 8) / 5.0;
    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *b = MkButton(pill, titles[i], CGRectMake(4 + i * tw, 4, tw, 38), UIColor.clearColor, ThSub(), 14, self, @selector(tabTapped:));
        b.tag = i;
        [btns addObject:b];
    }
    self.tabBtns = btns;
}

- (void)buildPages {
    CGFloat cw = self.cardW;
    CGFloat top = 124.0;
    CGFloat h = self.cardH - top - self.footerH;
    NSMutableArray *pages = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, top, cw, h)];
        sv.showsVerticalScrollIndicator = NO;
        sv.hidden = YES;
        [self.card addSubview:sv];
        [pages addObject:sv];
    }
    self.pages = pages;
    CGFloat hs[5];
    hs[0] = [self buildTimerPage:pages[0]];
    hs[1] = [self buildGamePage:pages[1]];
    hs[2] = [self buildScreenPage:pages[2]];
    hs[3] = [self buildImagePage:pages[3]];
    hs[4] = [self buildHelpPage:pages[4]];
    for (int i = 0; i < 5; i++) {
        ((UIScrollView *)pages[i]).contentSize = CGSizeMake(cw, hs[i]);
    }
}

- (void)buildFooter {
    if (self.footerH <= 0) return;
    CGFloat cw = self.cardW, ch = self.cardH, fh = self.footerH;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, ch - fh, cw, 1)];
    line.backgroundColor = ThLine();
    [self.card addSubview:line];
    MkLabel(self.card, @"dylib by Ragnar", CGRectMake(20, ch - fh + 12, 170, 46), 15, UIFontWeightMedium, ThSub());
    MkButton(self.card, @"Mon TikTok", CGRectMake(cw - 16 - 170, ch - fh + 12, 170, 46), ThAcc(), UIColor.whiteColor, 17, self, @selector(openTikTok));
}

- (void)addSnow {
    CAEmitterCell *c = [CAEmitterCell emitterCell];
    c.contents = (id)SnowDot().CGImage;
    c.birthRate = 12;
    c.lifetime = 10;
    c.velocity = 28;
    c.velocityRange = 14;
    c.yAcceleration = 6;
    c.emissionLongitude = M_PI_2;
    c.emissionRange = M_PI / 6;
    c.scale = 0.35;
    c.scaleRange = 0.25;
    c.alphaRange = 0.4;
    c.spin = 0.3;
    c.spinRange = 0.6;
    CAEmitterLayer *e = [CAEmitterLayer layer];
    e.frame = self.card.bounds;
    e.emitterShape = kCAEmitterLayerLine;
    e.emitterPosition = CGPointMake(self.cardW / 2, -8);
    e.emitterSize = CGSizeMake(self.cardW, 1);
    e.emitterCells = @[c];
    [self.card.layer addSublayer:e];
}

- (void)selectTab:(NSInteger)i {
    self.currentTab = i;
    for (NSInteger k = 0; k < (NSInteger)self.tabBtns.count; k++) {
        UIButton *b = self.tabBtns[k];
        BOOL sel = (k == i);
        b.backgroundColor = sel ? ThTabSel() : UIColor.clearColor;
        [b setTitleColor:(sel ? ThTabSelText() : ThSub()) forState:UIControlStateNormal];
        self.pages[k].hidden = !sel;
    }
}

- (void)tabTapped:(UIButton *)b {
    [self endEditing:YES];
    [self selectTab:b.tag];
}

#pragma mark Éléments réutilisables

- (CGFloat)addChips:(NSArray<NSString *> *)titles group:(NSString *)gid selected:(NSInteger)sel parent:(UIView *)p x:(CGFloat)x y:(CGFloat)y maxW:(CGFloat)maxW {
    CGFloat cx = x, cy = y, h = 42.0, gap = 8.0;
    for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
        NSString *t = titles[i];
        CGFloat bw = ceil([t sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]}].width) + 36.0;
        if (cx + bw > x + maxW && cx > x) {
            cx = x;
            cy += h + gap;
        }
        UIButton *b = MkButton(p, t, CGRectMake(cx, cy, bw, h), ThChip(), ThText(), 16, self, @selector(chipTapped:));
        b.tag = i;
        b.accessibilityIdentifier = gid;
        StyleChip(b, i == sel);
        cx += bw + gap;
    }
    return cy + h;
}

- (void)addSwitchRow:(UIView *)sec y:(CGFloat)y title:(NSString *)title gid:(NSString *)gid on:(BOOL)on {
    CGFloat sw = sec.bounds.size.width;
    MkLabel(sec, title, CGRectMake(18, y, sw - 100, 64), 18, UIFontWeightMedium, ThText());
    UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(sw - 18 - 51, y + 16, 51, 31)];
    s.on = on;
    s.onTintColor = ThAcc();
    s.accessibilityIdentifier = gid;
    [s addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [sec addSubview:s];
}

- (void)addSliderRow:(UIView *)sec y:(CGFloat)y gid:(NSString *)gid title:(NSString *)title min:(float)mn max:(float)mx value:(float)v {
    CGFloat sw = sec.bounds.size.width;
    MkLabel(sec, title, CGRectMake(18, y + 10, sw - 140, 26), 18, UIFontWeightMedium, ThText());
    UILabel *vl = MkLabel(sec, SliderText(gid, v), CGRectMake(sw - 118, y + 10, 100, 26), 17, UIFontWeightRegular, ThSub());
    vl.textAlignment = NSTextAlignmentRight;
    self.valueLabels[gid] = vl;
    UISlider *s = [[UISlider alloc] initWithFrame:CGRectMake(18, y + 40, sw - 36, 30)];
    s.minimumValue = mn;
    s.maximumValue = mx;
    s.value = v;
    s.minimumTrackTintColor = ThAcc();
    s.accessibilityIdentifier = gid;
    [s addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [sec addSubview:s];
}

- (void)addColors:(NSInteger)count group:(NSString *)gid selected:(NSInteger)sel in:(UIView *)sec y:(CGFloat)y {
    CGFloat sw = sec.bounds.size.width;
    CGFloat d = 38.0;
    CGFloat step = (sw - 36.0 - d) / (CGFloat)(count - 1);
    for (NSInteger i = 0; i < count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(18 + i * step, y, d, d);
        b.backgroundColor = [gid isEqualToString:@"accent"] ? AccentColor(i) : BgColor(i);
        b.layer.cornerRadius = d / 2;
        b.layer.borderWidth = 3;
        b.layer.borderColor = (i == sel) ? ThAcc().CGColor : ThLine().CGColor;
        b.tag = i;
        b.accessibilityIdentifier = gid;
        [b addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
        [sec addSubview:b];
    }
}

#pragma mark Pages

- (CGFloat)buildTimerPage:(UIScrollView *)p {
    CGFloat cw = self.cardW, iw = cw - 32, y = 6;
    y = [self addChips:@[@"Chrono", @"LiveSplit", @"iOS Timer", @"Texte seul"] group:@"style"
              selected:DefInt(@"chrono.style", 1) parent:p x:16 y:y maxW:iw] + 16;

    UIView *s1 = MkSection(p, y, cw, 68);
    [self addSwitchRow:s1 y:2 title:@"Étirer" gid:@"stretch" on:DefBool(@"chrono.stretch", NO)];
    y += 68 + 14;

    UIView *s2 = MkSection(p, y, cw, 4 * 78);
    [self addSliderRow:s2 y:0 gid:@"opacity" title:@"Opacité" min:0.2f max:1.0f value:(float)DefFloat(@"chrono.opacity", 1.0)];
    MkLine(s2, 78);
    [self addSliderRow:s2 y:78 gid:@"zoom" title:@"Taille" min:0.5f max:1.5f value:(float)DefFloat(@"chrono.zoom", 1.0)];
    MkLine(s2, 156);
    [self addSliderRow:s2 y:156 gid:@"width" title:@"Largeur" min:120 max:420 value:(float)DefFloat(@"chrono.width", 252)];
    MkLine(s2, 234);
    [self addSliderRow:s2 y:234 gid:@"height" title:@"Hauteur" min:36 max:120 value:(float)DefFloat(@"chrono.height", 56)];
    y += 4 * 78 + 14;

    UIView *s3 = MkSection(p, y, cw, 104);
    MkLabel(s3, @"Couleur du chrono", CGRectMake(18, 10, iw - 36, 28), 18, UIFontWeightMedium, ThText());
    [self addColors:6 group:@"accent" selected:DefInt(@"chrono.accent", 0) in:s3 y:50];
    y += 104 + 14;

    MkLabel(p, @"1 appui sur le chrono : lancer, pause, reset.\nAppui long : ouvrir ce menu.", CGRectMake(28, y, cw - 56, 40), 13, UIFontWeightRegular, ThSub());
    y += 56;
    return y;
}

- (CGFloat)buildGamePage:(UIScrollView *)p {
    CGFloat cw = self.cardW, y = 6;
    MkLabel(p, @"MODE BLITZ", CGRectMake(28, y, cw - 56, 22), 13, UIFontWeightSemibold, ThSub());
    y += 28;
    UIView *s1 = MkSection(p, y, cw, 10);
    CGFloat sw = s1.bounds.size.width;
    [self addSwitchRow:s1 y:2 title:@"Mode Blitz" gid:@"blitz" on:DefBool(@"game.blitz", NO)];
    MkLine(s1, 70);
    MkLabel(s1, @"Vitesse", CGRectMake(18, 78, 200, 24), 16, UIFontWeightMedium, ThSub());
    CGFloat bottom = [self addChips:@[@"x1.5", @"x2", @"x3"] group:@"blitzmul" selected:DefInt(@"game.blitzmul", 2)
                             parent:s1 x:18 y:106 maxW:sw - 36];
    self.statusLabel = MkLabel(s1, [[GameTools shared] unityStatus], CGRectMake(18, bottom + 12, sw - 36, 40), 14, UIFontWeightRegular, ThSub());
    MkLabel(s1, @"Accélère le jeu dès le début de chaque run. Pendant les boosts de départ, appuie sur le bouton ⚡ pour repasser en vitesse normale, puis rappuie dessus quand tu prends l'étoile.",
            CGRectMake(18, bottom + 58, sw - 36, 100), 13, UIFontWeightRegular, ThSub());
    SetH(s1, bottom + 58 + 100 + 8);
    y += s1.frame.size.height + 22;

    MkLabel(p, @"PIÈCES", CGRectMake(28, y, cw - 56, 22), 13, UIFontWeightSemibold, ThSub());
    y += 28;
    UIView *s2 = MkSection(p, y, cw, 10);
    [self addSwitchRow:s2 y:2 title:@"Pièces invisibles (test)" gid:@"coins" on:DefBool(@"game.coins", NO)];
    MkLine(s2, 70);
    MkLabel(s2, @"Mot-clé des pièces", CGRectMake(18, 78, sw - 36, 24), 16, UIFontWeightMedium, ThSub());
    NSString *kw = [Defs() stringForKey:@"game.coinkey"];
    UITextField *f = MkField(s2, CGRectMake(18, 106, sw - 36, 44), @"coin", (kw.length ? kw : @"coin"));
    f.tag = 11;
    f.delegate = self;
    self.coinStatusLabel = MkLabel(s2, [[GameTools shared] coinStatus], CGRectMake(18, 160, sw - 36, 24), 14, UIFontWeightRegular, ThSub());
    MkLabel(s2, @"Les pièces restent actives et comptées : seul leur affichage est coupé.", CGRectMake(18, 188, sw - 36, 44), 13, UIFontWeightRegular, ThSub());
    SetH(s2, 240);
    y += 240 + 22;

    MkLabel(p, @"OUTILS", CGRectMake(28, y, cw - 56, 22), 13, UIFontWeightSemibold, ThSub());
    y += 28;
    UIView *s3 = MkSection(p, y, cw, 76);
    MkButton(s3, @"Explorateur de classes (avancé)", CGRectMake(14, 14, s3.bounds.size.width - 28, 48), ThAcc(), UIColor.whiteColor, 16, self, @selector(openExplorer));
    y += 76 + 24;
    return y;
}

- (CGFloat)buildScreenPage:(UIScrollView *)p {
    CGFloat cw = self.cardW, y = 6;
    UIView *s1 = MkSection(p, y, cw, 10);
    CGFloat sw = s1.bounds.size.width;
    [self addSwitchRow:s1 y:2 title:@"Compteur FPS" gid:@"fps" on:DefBool(@"game.fps", NO)];
    MkLine(s1, 70);
    MkLabel(s1, @"Résolution du jeu", CGRectMake(18, 78, sw - 36, 24), 16, UIFontWeightMedium, ThSub());
    CGFloat bottom = [self addChips:@[@"50%", @"75%", @"Natif", @"4K"] group:@"res" selected:DefInt(@"game.res", 2)
                             parent:s1 x:18 y:106 maxW:sw - 36];
    MkLabel(s1, @"Certains jeux ignorent ce réglage.", CGRectMake(18, bottom + 10, sw - 36, 22), 13, UIFontWeightRegular, ThSub());
    SetH(s1, bottom + 44);
    y += s1.frame.size.height + 16;

    UIView *s2 = MkSection(p, y, cw, 78 + 70);
    [self addSliderRow:s2 y:0 gid:@"sat" title:@"Saturation (50 = normal)" min:1 max:100 value:(float)DefFloat(@"game.sat", 50)];
    MkLine(s2, 78);
    [self addSwitchRow:s2 y:80 title:@"Masquer la barre d'état" gid:@"bar" on:DefBool(@"game.hidebar", NO)];
    y += 148 + 24;
    return y;
}

- (CGFloat)buildImagePage:(UIScrollView *)p {
    CGFloat cw = self.cardW, y = 6;
    UIView *s1 = MkSection(p, y, cw, 10);
    CGFloat sw = s1.bounds.size.width;
    [self addSwitchRow:s1 y:2 title:@"Afficher le fond" gid:@"showbg" on:DefBool(@"chrono.showbg", YES)];
    MkLine(s1, 70);
    MkLabel(s1, @"Couleur du fond", CGRectMake(18, 78, sw - 36, 26), 18, UIFontWeightMedium, ThText());
    [self addColors:5 group:@"bgcolor" selected:DefInt(@"chrono.bgcolor", 0) in:s1 y:114];
    MkLine(s1, 168);
    CGFloat bw = (sw - 36 - 10) / 2.0;
    MkButton(s1, @"Choisir une photo", CGRectMake(18, 184, bw, 48), ThChip(), ThText(), 15, self, @selector(pickImage));
    MkButton(s1, @"Retirer", CGRectMake(18 + bw + 10, 184, bw, 48), ThChip(), ThText(), 15, self, @selector(clearImage));
    SetH(s1, 250);
    y += 250 + 16;
    MkLabel(p, @"Par défaut, le fond du chrono est noir.", CGRectMake(28, y, cw - 56, 22), 13, UIFontWeightRegular, ThSub());
    y += 44;
    return y;
}

- (CGFloat)buildHelpPage:(UIScrollView *)p {
    CGFloat cw = self.cardW, y = 6;
    UIView *s1 = MkSection(p, y, cw, 190);
    CGFloat sw = s1.bounds.size.width;
    MkLabel(s1, @"Besoin d'aide ?", CGRectMake(18, 14, sw - 36, 30), 22, UIFontWeightBold, ThText());
    MkLabel(s1, @"Ajoute g420262 sur TikTok pour avoir de l'aide.", CGRectMake(18, 50, sw - 36, 50), 16, UIFontWeightRegular, ThText());
    self.pseudoBtn = MkButton(s1, @"Copier g420262", CGRectMake(18, 118, sw - 36, 52), ThAcc(), UIColor.whiteColor, 17, self, @selector(onCopyPseudo));
    y += 190 + 16;

    UIView *s2 = MkSection(p, y, cw, 76);
    MkButton(s2, @"Réinitialiser les réglages du chrono", CGRectMake(14, 14, s2.bounds.size.width - 28, 48), ThChip(), ThText(), 16, self, @selector(resetAll));
    y += 76 + 16;

    MkLabel(p, @"dylib by Ragnar", CGRectMake(28, y, cw - 56, 22), 13, UIFontWeightRegular, ThSub());
    y += 50;
    return y;
}

#pragma mark Pages secondaires (TikTok, Explorateur)

- (UIView *)makeSubPage:(NSString *)title {
    [self.subPage removeFromSuperview];
    UIView *v = [[UIView alloc] initWithFrame:self.card.bounds];
    v.backgroundColor = ThBG();
    [self.card addSubview:v];
    self.subPage = v;
    MkButton(v, @"‹ Retour", CGRectMake(14, 14, 110, 44), ThChip(), ThText(), 16, self, @selector(closeSub));
    UILabel *t = MkLabel(v, title, CGRectMake(130, 14, self.cardW - 144, 44), 20, UIFontWeightBold, ThText());
    t.textAlignment = NSTextAlignmentCenter;
    return v;
}

- (void)closeSub {
    [self endEditing:YES];
    [self.subPage removeFromSuperview];
    self.subPage = nil;
}

- (void)openTikTok {
    UIView *v = [self makeSubPage:@"TikTok"];
    CGFloat cw = self.cardW;
    UILabel *l = MkLabel(v, @"mon tiktok : kit.563", CGRectMake(16, 130, cw - 32, 50), 28, UIFontWeightBold, ThText());
    l.textAlignment = NSTextAlignmentCenter;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.6;
    l.numberOfLines = 1;
    self.subCopyBtn = MkButton(v, @"Copier kit.563", CGRectMake(40, 206, cw - 80, 54), ThAcc(), UIColor.whiteColor, 18, self, @selector(onCopyKit));
}

- (void)openExplorer {
    UIView *v = [self makeSubPage:@"Explorateur"];
    CGFloat cw = self.cardW, ch = self.cardH;
    self.exField = MkField(v, CGRectMake(16, 70, cw - 32 - 106, 46), @"mot-clé (ex : coin)", nil);
    self.exField.delegate = self;
    self.exField.tag = 21;
    MkButton(v, @"Chercher", CGRectMake(cw - 16 - 96, 70, 96, 46), ThAcc(), UIColor.whiteColor, 16, self, @selector(doSearch));
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(16, 126, cw - 32, ch - 126 - 78)];
    tv.backgroundColor = ThSec();
    tv.textColor = ThText();
    tv.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    tv.editable = NO;
    tv.layer.cornerRadius = 14;
    tv.text = @"Tape un mot-clé puis touche « Chercher ».\nExemples : coin, speed, player, boost.";
    [v addSubview:tv];
    self.exView = tv;
    MkButton(v, @"Copier le résultat", CGRectMake(16, ch - 64, cw - 32, 48), ThChip(), ThText(), 17, self, @selector(onCopyResult));
}

- (void)doSearch {
    [self.exField resignFirstResponder];
    self.exView.text = [[GameTools shared] searchClasses:self.exField.text];
}

- (void)onCopyResult {
    [UIPasteboard generalPasteboard].string = self.exView.text ?: @"";
}

- (void)onCopyKit {
    [UIPasteboard generalPasteboard].string = @"kit.563";
    [self.subCopyBtn setTitle:@"Copié ✓" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.subCopyBtn setTitle:@"Copier kit.563" forState:UIControlStateNormal];
    });
}

- (void)onCopyPseudo {
    [UIPasteboard generalPasteboard].string = @"g420262";
    [self.pseudoBtn setTitle:@"Copié ✓" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.pseudoBtn setTitle:@"Copier g420262" forState:UIControlStateNormal];
    });
}

#pragma mark Actions

- (void)reopenOnCurrentTab {
    NSInteger tab = self.currentTab;
    ChronoView *c = self.chrono;
    [self dismiss];
    ShowSettings(c);
    [gSettings selectTab:tab];
}

- (void)themeTapped {
    [Defs() setInteger:(ThemeIdx() + 1) % 3 forKey:@"ui.theme"];
    [self.chrono applyConfig];
    [self reopenOnCurrentTab];
}

- (void)resetAll {
    NSArray *keys = @[@"chrono.style", @"chrono.accent", @"chrono.bgcolor", @"chrono.showbg", @"chrono.stretch",
                      @"chrono.width", @"chrono.height", @"chrono.zoom", @"chrono.opacity"];
    for (NSString *k in keys) [Defs() removeObjectForKey:k];
    [self.chrono applyConfig];
    [self reopenOnCurrentTab];
}

- (void)chipTapped:(UIButton *)b {
    NSString *g = b.accessibilityIdentifier;
    for (UIView *v in b.superview.subviews) {
        if ([v isKindOfClass:[UIButton class]] && [v.accessibilityIdentifier isEqualToString:g]) {
            StyleChip((UIButton *)v, v == b);
        }
    }
    NSInteger i = b.tag;
    if ([g isEqualToString:@"style"]) {
        [Defs() setInteger:i forKey:@"chrono.style"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"blitzmul"]) {
        [Defs() setInteger:i forKey:@"game.blitzmul"];
        [[GameTools shared] applyBlitz];
    } else if ([g isEqualToString:@"res"]) {
        [Defs() setInteger:i forKey:@"game.res"];
        [[GameTools shared] applyResolution:i];
    }
}

- (void)colorTapped:(UIButton *)b {
    NSString *g = b.accessibilityIdentifier;
    for (UIView *v in b.superview.subviews) {
        if ([v isKindOfClass:[UIButton class]] && [v.accessibilityIdentifier isEqualToString:g]) {
            v.layer.borderColor = (v == b) ? ThAcc().CGColor : ThLine().CGColor;
        }
    }
    if ([g isEqualToString:@"accent"]) [Defs() setInteger:b.tag forKey:@"chrono.accent"];
    else [Defs() setInteger:b.tag forKey:@"chrono.bgcolor"];
    [self.chrono applyConfig];
}

- (void)switchChanged:(UISwitch *)s {
    NSString *g = s.accessibilityIdentifier;
    BOOL on = s.isOn;
    if ([g isEqualToString:@"stretch"]) {
        [Defs() setBool:on forKey:@"chrono.stretch"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"showbg"]) {
        [Defs() setBool:on forKey:@"chrono.showbg"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"blitz"]) {
        [Defs() setBool:on forKey:@"game.blitz"];
        [[GameTools shared] setBlitzEnabled:on];
        self.statusLabel.text = [[GameTools shared] unityStatus];
    } else if ([g isEqualToString:@"coins"]) {
        [Defs() setBool:on forKey:@"game.coins"];
        [[GameTools shared] setCoinsHidden:on];
        self.coinStatusLabel.text = [[GameTools shared] coinStatus];
    } else if ([g isEqualToString:@"fps"]) {
        [Defs() setBool:on forKey:@"game.fps"];
        [[GameTools shared] setFPSEnabled:on];
    } else if ([g isEqualToString:@"bar"]) {
        [Defs() setBool:on forKey:@"game.hidebar"];
        [[GameTools shared] setStatusBarHidden:on];
    }
}

- (void)sliderChanged:(UISlider *)s {
    NSString *g = s.accessibilityIdentifier;
    double v = s.value;
    if ([g isEqualToString:@"opacity"]) {
        v = round(v * 20.0) / 20.0;
        [Defs() setDouble:v forKey:@"chrono.opacity"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"zoom"]) {
        v = round(v * 20.0) / 20.0;
        [Defs() setDouble:v forKey:@"chrono.zoom"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"width"]) {
        v = round(v);
        [Defs() setDouble:v forKey:@"chrono.width"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"height"]) {
        v = round(v);
        [Defs() setDouble:v forKey:@"chrono.height"];
        [self.chrono applyConfig];
    } else if ([g isEqualToString:@"sat"]) {
        v = round(v);
        [Defs() setDouble:v forKey:@"game.sat"];
        [[GameTools shared] applySaturation:v];
    }
    self.valueLabels[g].text = SliderText(g, v);
}

- (void)pickImage {
    ChronoView *c = self.chrono;
    [self dismiss];
    [c pickImage];
}

- (void)clearImage {
    [self.chrono clearImage];
}

#pragma mark Champs texte

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [tf resignFirstResponder];
    if (tf.tag == 21) [self doSearch];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)tf {
    if (tf.tag == 11) {
        NSString *k = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (k.length == 0) k = @"coin";
        [Defs() setObject:k forKey:@"game.coinkey"];
        [[GameTools shared] coinKeywordChanged];
    }
}

@end

#pragma mark - Entrée du dylib

static ChronoView *gChrono = nil;

static BOOL gSafeMode = NO;

static void ShowBanner(UIWindow *w) {
    UILabel *l = [[UILabel alloc] init];
    l.text = gSafeMode ? @"dylib by Ragnar · mode sûr" : @"dylib by Ragnar";
    l.font = [UIFont boldSystemFontOfSize:15];
    l.textColor = UIColor.whiteColor;
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:0 alpha:0.88];
    l.layer.cornerRadius = 14;
    l.layer.masksToBounds = YES;
    l.layer.borderWidth = 1;
    l.layer.borderColor = COL(58,58,62).CGColor;
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
    gChrono = [[ChronoView alloc] initWithFrame:CGRectMake(20, 110, 252, 82)];
    [w addSubview:gChrono];
    [gChrono applyConfig];
    ShowBanner(w);
    if (!gSafeMode) {
        // Les réglages du jeu (Blitz, pièces, FPS...) ne sont réappliqués que bien après le démarrage.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [[GameTools shared] reapplyAll]; });
    }
}

__attribute__((constructor))
static void chrono_init(void) {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            // Protection : si le lancement précédent a planté avant 12 s, on démarre en mode sûr
            // (tous les réglages du jeu sont coupés).
            gSafeMode = [Defs() boolForKey:@"boot.pending"];
            if (gSafeMode) {
                for (NSString *k in @[@"game.blitz", @"game.coins", @"game.fps", @"game.res", @"game.sat", @"game.hidebar"]) {
                    [Defs() removeObjectForKey:k];
                }
            }
            [Defs() setBool:YES forKey:@"boot.pending"];
            [Defs() synchronize];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [Defs() setBool:NO forKey:@"boot.pending"];
                [Defs() synchronize];
            });
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ ShowChrono(); });
    }];
}
