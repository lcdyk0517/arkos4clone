package i18n

//go:generate go run ./tools/i18n-extract

// LanguageVariant represents a supported language.
type LanguageVariant string

// Language holds all localized strings for the UI.
type Language struct {
	Title   string
	Variant LanguageVariant

	Common    CommonStrings
	Menu1     Menu1Strings
	Menu2     Menu2Strings
	Menu3     Menu3Strings
	Menu4     Menu4Strings
	Cleanup   CleanupStrings
	Overclock OverclockStrings
}

// CommonStrings holds shared UI strings.
type CommonStrings struct {
	Exit                 string
	InvalidSelection     string
	PleaseEnterNumber    string
	Back                 string
	SelectNumber         string
	PressEnterToContinue string
	GoodBye              string
}

// Menu1Strings holds the welcome/intro strings.
type Menu1Strings struct {
	SelectYourConsole string
	Welcome           string
	NoteInfo1         string
	NoteInfo2         string
	NoteInfo3         string

	BeforeSelectingConsole string
	SubInfo                string
	Continue1              string
	Continue2              string
	CancelledBye           string
}

// Menu2Strings holds brand selection strings.
type Menu2Strings struct {
	PleaseSelectBrand string
	SearchOption      string
	SearchPrompt      string
	SearchResultsFmt  string
	SearchNoResults   string
	SearchHint        string
}

// Menu3Strings holds console selection and copy strings.
type Menu3Strings struct {
	AvailableConsolesFor   string
	NoConsolesFound        string
	Copying                string
	CopyingExtra           string
	CopyingFmt             string
	SelectBatteryVersion   string
	BatteryVersionOriginal string
	BatteryVersionFix      string
	CloneR36sNote          string
}

// Menu4Strings holds language selection strings.
type Menu4Strings struct {
	SelectLanguage    string
	DefaultEnglish    string
	Info1             string
	TagFileCreated    string
	OperationComplete string
}

// CleanupStrings holds cleanup operation strings.
type CleanupStrings struct {
	OperationCompleted   string
	ModelsCopied         string
	Tip1                 string
	CleanTargetDir       string
	DeleteFileFmt        string
	DeletionFailedFmt    string
	DeleteDirectoryFmt   string
	DirDeletionFailedFmt string
}

// OverclockStrings holds overclock and voltage strings.
type OverclockStrings struct {
	AskOverclock         string
	OverclockTitle       string
	MaxFreqLabel         string
	BootFreqLabel        string
	BootFreqMustLE       string
	DefaultFreqNote      string
	RedWarning           string
	FreezeWarning        string
	CurrentConfig        string
	ConfigCPU            string
	ConfigGPU            string
	ConfigDDR            string
	MaxFreq              string
	BootFreq             string
	ApplyOverclock       string
	OverclockApplied     string
	UsingDefaults        string
	DDRCloneDefault      string
	DDROriginalDefault   string
	OCWarning            string
	GPUDDRFreezeTip      string
	AskVoltage           string
	VoltageTitle         string
	VoltageWarning       string
	VoltageConfirmPrompt string
	VoltageConfirmText   string
	VoltageInputPrompt   string
	VoltageWrongInput    string
	VoltageApplied       string
	VoltageSkipped       string
}

// AllLanguages returns all supported languages.
func AllLanguages() []Language {
	return []Language{
		English,
		Chinese,
		Korean,
		BrazilianPortuguese,
		German,
		Greek,
		Spanish,
		French,
		Japanese,
		Polish,
		Portuguese,
		Russian,
		Swedish,
		Vietnamese,
		ChineseTraditional,
	}
}

// ByVariant looks up a language by its variant code.
func ByVariant(variant LanguageVariant) (*Language, bool) {
	switch variant {
	case "en":
		return &English, true
	case "cn":
		return &Chinese, true
	case "ko":
		return &Korean, true
	case "br":
		return &BrazilianPortuguese, true
	case "de":
		return &German, true
	case "el":
		return &Greek, true
	case "es":
		return &Spanish, true
	case "fr":
		return &French, true
	case "ja":
		return &Japanese, true
	case "pl":
		return &Polish, true
	case "pt":
		return &Portuguese, true
	case "ru":
		return &Russian, true
	case "sv":
		return &Swedish, true
	case "vi":
		return &Vietnamese, true
	case "zh-tw":
		return &ChineseTraditional, true
	default:
		return nil, false
	}
}

// SupportedLanguages returns a list of supported language codes.
func SupportedLanguages() []string {
	return []string{"en", "cn", "ko", "br", "de", "el", "es", "fr", "ja", "pl", "pt", "ru", "sv", "vi", "zh-tw"}
}

// LanguageByCode returns a language by its code.
func LanguageByCode(code string) (*Language, bool) {
	switch code {
	case "en":
		return &English, true
	case "cn":
		return &Chinese, true
	case "ko":
		return &Korean, true
	case "br":
		return &BrazilianPortuguese, true
	case "de":
		return &German, true
	case "el":
		return &Greek, true
	case "es":
		return &Spanish, true
	case "fr":
		return &French, true
	case "ja":
		return &Japanese, true
	case "pl":
		return &Polish, true
	case "pt":
		return &Portuguese, true
	case "ru":
		return &Russian, true
	case "sv":
		return &Swedish, true
	case "vi":
		return &Vietnamese, true
	case "zh-tw":
		return &ChineseTraditional, true
	default:
		return nil, false
	}
}
