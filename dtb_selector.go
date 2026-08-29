package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
)

// ===================== 配置：别名 & 排除 =====================
type ConsoleConfig struct {
	RealName     string
	BrandEntries []BrandEntry
	ExtraSources []string
	Keywords     []string
}

type BrandEntry struct {
	Brand       string
	DisplayName string
}

// 控制台配置
var Consoles = []ConsoleConfig{
	//==================  YMC  ===================================
	{
		RealName: "a10mini",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "a10miniv4",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI V4"},
		},
		ExtraSources: []string{"logo/540P/"},
	},
	//==================  UDT  ===================================
	{
		RealName: "r36ultra",
		BrandEntries: []BrandEntry{
			{Brand: "UDT", DisplayName: "UDT R36Ultra"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36ultrax",
		BrandEntries: []BrandEntry{
			{Brand: "UDT", DisplayName: "UDT R36UltraX"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	//==================  AISLPC  ===================================
	{
		RealName: "k36s",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole K36S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36t",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole R36T"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36tmax",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole R36T MAX"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	//==================  GUSGU  ===================================
	{
		RealName: "h7",
		BrandEntries: []BrandEntry{
			{Brand: "GUSGU", DisplayName: "GUSGU H7"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	//==================  Lenovo  ===================================
	{
		RealName: "go2",
		BrandEntries: []BrandEntry{
			{Brand: "Lenovo", DisplayName: "Lenovo GO2"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	//==================  MagicX  ===================================
	{
		RealName: "xu10",
		BrandEntries: []BrandEntry{
			{Brand: "MagicX", DisplayName: "MagicX XU10"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  Batlexp  ===================================
	{
		RealName: "g350",
		BrandEntries: []BrandEntry{
			{Brand: "Batlexp", DisplayName: "Batlexp G350"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  Kinhank  ===================================
	{
		RealName: "k36",
		BrandEntries: []BrandEntry{
			{Brand: "Kinhank", DisplayName: "K36 Origin Panel"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  Anbernic  ===================================
	{
		RealName: "rg351mp",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351MP"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg351p",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351P"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rg351v panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351V Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg351v panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Anbernic", DisplayName: "RG351V Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  RetroBox  ===================================
	{
		RealName: "rp1",
		BrandEntries: []BrandEntry{
			{Brand: "RetroBox", DisplayName: "RetroBox P1"},
		},
		ExtraSources: []string{"logo/480P-270/"},
	},
	//==================  Powkiddy  ===================================
	{
		RealName: "rgb10",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rgbv10",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGBV10"},
		},
		ExtraSources: []string{"logo/320P/"},
	},
	{
		RealName: "rgb10x",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10X"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rgb10max1",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10Max1"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "rgb10max2",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB10Max2"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "rgb20s",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB20S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  Clone R36s  ===================================
	{
		RealName: "clone type1 amp",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type1 invert",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Without Amplifier And Invert Right Joystick"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type2",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type2 amp",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type3 panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 3 Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type3 panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 3 Panel 2[thanks Flecha]"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type3 panel3",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 3 Panel 3[The previous version was called Clone Type4]"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "clone type5",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 5"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  GameConsole  ===================================
	{
		RealName: "r46h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R46H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r40xxpromax",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX ProMax"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r40xx",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r36hpromax",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36H ProMax"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r45h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R45H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "r36splus",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36sPlus"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r33s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R33s"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel0",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 0"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel1",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel2",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel3",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 3"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel4 type1",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4 Type 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "origin panel4 type2",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4 Type 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "v21 panel4 rumble test",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s v21 Rumble Fix (Risk unknown. For testing purposes only.)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36xx",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36XX"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "o30s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole O30S"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r36h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r50s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R50S"},
		},
		ExtraSources: []string{"logo/854x480P/"},
	},
	{
		RealName: "r50h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R50H"},
		},
		ExtraSources: []string{"logo/720x1280P/"},
	},
	//==================  SoySauce R36s  ===================================
	{
		RealName: "sauce panel1",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 1"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel2",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 2"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel3",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 3"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel4",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 4"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "sauce panel5",
		BrandEntries: []BrandEntry{
			{Brand: "SoySauce R36s", DisplayName: "Soy Sauce Panel 5 [TEST]"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  Diium(SZDiiER)  ===================================
	{
		RealName: "dr28s",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "Diium Dr28s"},
		},
		ExtraSources: []string{"logo/480P-270/"},
	},
	{
		RealName: "d007",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "SZDiiER D007(Plus)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	//==================  XiFan HandHelds  ===================================
	{
		RealName: "mymini",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mymini"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "mini40",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mini40"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type1",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 1"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type2",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 2"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36max type3",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max Type 3[thanks Pandryl]"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "r36pro",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Pro"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xf35h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF35H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rf35h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF35H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xf40h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40H"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "rf40h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF40H"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "dc35v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC35V"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "dc40v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC40V"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "xf40v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40V"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "xf28",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF28"},
		},
		ExtraSources: []string{"logo/480P-1/"},
	},
	{
		RealName: "r36max2",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max2"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "xf45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "dc45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf45v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF45V"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf45h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF45H"},
		},
		ExtraSources: []string{"logo/768P/"},
	},
	{
		RealName: "rf55h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan RF55H"},
		},
		ExtraSources: []string{"logo/720x1280P-90/"},
	},
	//==================  XiFan HandHelds  ===================================
	{
		RealName: "hg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole HG36 (HG3506)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rx6h",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RX6H"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "xgb36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole XGB36 (G26)"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "t16max",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole T16MAX"},
		},
		ExtraSources: []string{"logo/720P/"},
	},
	{
		RealName: "u8 panel1",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8 Panel 1"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
	{
		RealName: "u8 panel2",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8 Panel 2"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
	{
		RealName: "rg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RG36"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "rg36pro",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RG36Pro"},
		},
		ExtraSources: []string{"logo/480P/"},
	},
	{
		RealName: "r40s",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole R40S (RK3326 Without L2/R2)"},
			{Brand: "Other", DisplayName: "GameConsole R39S"},
		},
		ExtraSources: []string{"logo/480P5-3/"},
	},
}

// 品牌列表
var Brands = []string{
	"YMC",
	"UDT",
	"GUSGU",
	"AISLPC",
	"Lenovo",
	"MagicX",
	"Batlexp",
	"Kinhank",
	"Anbernic",
	"RetroBox",
	"Powkiddy",
	"Clone R36s",
	"GameConsole",
	"SoySauce R36s",
	"Diium(SZDiiER)",
	"XiFan HandHelds",
	"Other",
}

// Multiple Language Support
type Language struct {
	Title   string
	Variant LanguageVariant

	Common    LanguageCommon
	Menu1     LanguageMenu1
	Menu2     LanguageMenu2
	Menu3     LanguageMenu3
	Cleanup   LanguageCleanup
	Menu4     LanguageMenu4
	Overclock LanguageOverclock
}

type LanguageCommon struct {
	Exit                 string
	InvalidSelection     string
	PleaseEnterNumber    string
	Back                 string
	SelectNumber         string
	PressEnterToContinue string
	GoodBye              string
}

type LanguageMenu1 struct {
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

type LanguageMenu2 struct {
	PleaseSelectBrand string
	SearchOption      string
	SearchPrompt      string
	SearchResultsFmt  string
	SearchNoResults   string
	SearchHint        string
}

type LanguageMenu3 struct {
	AvailableConsolesFor   string
	NoConsolesFound        string
	Copying                string
	CopyingExtra           string
	CopyingFmt             string
	SelectBatteryVersion   string
	BatteryVersionOriginal string
	BatteryVersionFix      string
}

type LanguageCleanup struct {
	OperationCompleted   string
	ModelsCopied         string
	Tip1                 string
	CleanTargetDir       string
	DeleteFileFmt        string
	DeletionFailedFmt    string
	DeleteDirectoryFmt   string
	DirDeletionFailedFmt string
}

type LanguageMenu4 struct {
	SelectLanguage    string
	DefaultEnglish    string
	Info1             string
	TagFileCreated    string
	OperationComplete string
}

type LanguageVariant string

const (
	ENGLISH LanguageVariant = "en"
	CHINESE LanguageVariant = "cn"
	KOREAN  LanguageVariant = "ko"
)

// ===================== 超频配置 =====================
type FreqOption struct {
	Value int
}

type FreqSelection struct {
	MaxFreq  int
	BootFreq int
}

type OverclockConfig struct {
	CPU     FreqSelection
	GPU     FreqSelection
	DDR     FreqSelection
	Voltage bool
}

type FreqParamDef struct {
	Name        string
	DefaultMax  int
	DefaultBoot int
	Options     []FreqOption
}

var cpuFreqOptions = []FreqOption{
	{408}, {600}, {816}, {1008}, {1200}, {1248}, {1296},
	{1368}, {1416}, {1440}, {1464}, {1488}, {1512}, {1608},
}

var gpuFreqOptions = []FreqOption{
	{200}, {300}, {400}, {480}, {520}, {600}, {650},
}

var ddrFreqOptions = []FreqOption{
	{194}, {328}, {450}, {528}, {666}, {786}, {924}, {1040},
}

// 超频相关的多语言字符串
type LanguageOverclock struct {
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

var english = Language{
	Title:   "DTB Selector Tool - Go Version",
	Variant: ENGLISH,
	Common: LanguageCommon{
		Exit:                 " Exit : ",
		SelectNumber:         "\nSelect number: ",
		InvalidSelection:     "Invalid selection.",
		PleaseEnterNumber:    "Please enter a number",
		PressEnterToContinue: "Press Enter to continue...",
		Back:                 "Back",
		GoodBye:              "Goodbye!",
	},
	Menu1: LanguageMenu1{
		SelectYourConsole: "DTB Selector - Select Your Console",
		Welcome:           "\n================ Welcome ================",
		NoteInfo1:         "NOTE:\n• This system currently only supports the listed R36 clones;\n  if your clone is not in the list, it is not supported yet.",
		NoteInfo2:         "💡 If you don't know what clone your device is, use https://lcdyk0517.github.io/dtbTools.html to help identify it",
		NoteInfo3:         "• Do NOT use the dtb files from the stock EmuELEC card with this system — it will brick the boot.",

		BeforeSelectingConsole: "Before selecting a console:",
		SubInfo:                "  then copies the chosen console and any mapped extra sources.",
		Continue1:              "  • Press Enter to continue; type 'q' to quit.",
		Continue2:              "\nPress Enter to continue, Press ",
		CancelledBye:           "Cancelled, bye! 👋",
	},
	Menu2: LanguageMenu2{
		PleaseSelectBrand: "│ Please select a brand",
		SearchOption:      "Search by model keyword",
		SearchPrompt:      "Enter model keyword (e.g. r36s, rgb10max, 35h). Empty = back: ",
		SearchResultsFmt:  "Search results for: \"%s\"",
		SearchNoResults:   "No matching consoles found. Try a different keyword.",
		SearchHint:        "Tip: Don't know which brand your device is? Choose Search and just type the model name.",
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor:   "Available consoles for: ",
		NoConsolesFound:        "No consoles found.",
		Copying:                "Copying: ",
		CopyingExtra:           "Copying extra resources...",
		CopyingFmt:             "  Copying: %s\n",
		SelectBatteryVersion:   "Select battery driver version:",
		BatteryVersionOriginal: "1. arkos original driver (this driver must be used together with batteryplus; otherwise, the battery level will display abnormally during charging).",
		BatteryVersionFix:      "2. arkos4clone battery driver (capable of correctly displaying battery level during both charging and discharging, and featuring an aging‑adaptive function)",
	},
	Cleanup: LanguageCleanup{
		OperationCompleted:   "  ✅  Operation completed!",
		ModelsCopied:         "Models that have been copied： ",
		Tip1:                 "  Tip: verify files in the destination directory.",
		CleanTargetDir:       "Cleaning target directory...",
		DeleteFileFmt:        "  Delete file: %s\n",
		DeletionFailedFmt:    "    Warning: Deletion failed %s: %v\n",
		DeleteDirectoryFmt:   "  Delete directory: %s\n",
		DirDeletionFailedFmt: "    Warning: Directory deletion failed %s: %v\n",
	},
	Menu4: LanguageMenu4{
		SelectLanguage:    "Select language:",
		DefaultEnglish:    "  1. English (Default)",
		Info1:             "Enter the number or press Enter. English is the default selection: ",
		TagFileCreated:    "Chinese language tag file has been created. (.cn created)",
		OperationComplete: "Operation complete! Language selected: ",
	},
	Overclock: LanguageOverclock{
		AskOverclock:         "Do you want to adjust overclocking parameters?",
		OverclockTitle:       "Overclocking Parameters Configuration",
		MaxFreqLabel:         "Maximum frequency (visible in ES after boot)",
		BootFreqLabel:        "Boot frequency (used during system startup)",
		BootFreqMustLE:       "Boot frequency must be <= max frequency",
		DefaultFreqNote:      "Default frequencies ensure normal boot. Frequencies above default shown in RED.",
		RedWarning:           "WARNING: Exceeding default frequency may cause system freeze!",
		FreezeWarning:        "If system freezes, please lower the frequency.",
		CurrentConfig:        "Current configuration:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "DDR",
		MaxFreq:              "Max",
		BootFreq:             "Boot",
		ApplyOverclock:       "Applying overclocking parameters to boot.ini...",
		OverclockApplied:     "Overclocking parameters applied successfully!",
		UsingDefaults:        "Using default overclocking parameters (1296/520/666).",
		DDRCloneDefault:      "Clone default",
		DDROriginalDefault:   "Original default",
		OCWarning:            "WARNING: In this mode, do NOT submit issues for any bugs.\n  Any CPU damage is at your own risk.\n  If you don't understand this, please select N.\n\n  Oh by the way, this system will NOT damage your speakers.\n  If you're worried about that risk, don't use it.\n  We have no idea why such ridiculous rumors spread.",
		GPUDDRFreezeTip:      "If the system freezes after entering, please lower the frequency.",
		AskVoltage:           "Do you want to increase voltage for higher stability?",
		VoltageTitle:         "Voltage Increase Configuration",
		VoltageWarning:       "WARNING: Increasing voltage may cause hardware damage!",
		VoltageConfirmPrompt: "To confirm you understand the risks, type: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "Enter confirmation: ",
		VoltageWrongInput:    "Incorrect input. Voltage increase cancelled.",
		VoltageApplied:       "Voltage increase applied successfully!",
		VoltageSkipped:       "Voltage increase skipped.",
	},
}

var chinese = Language{
	Title:   "DTB 选择工具 - Go 版本",
	Variant: CHINESE,
	Common: LanguageCommon{
		Exit:                 " 退出：",
		SelectNumber:         "\n选择序号: ",
		InvalidSelection:     "选择无效，请重试.",
		PleaseEnterNumber:    "请输入数字",
		PressEnterToContinue: "按 Enter 返回...",
		Back:                 "返回",
		GoodBye:              "再见！",
	},
	Menu1: LanguageMenu1{
		SelectYourConsole: "DTB Selector - 请选择机型",
		Welcome:           "\n================ 欢迎使用 ================",
		NoteInfo1:         "说明：\n本系统目前只支持下列机型，如果你的 R36 克隆机不在列表中，则暂时无法使用。",
		NoteInfo2:         "💡 如果你不知道你的设备是什么克隆，可以使用 https://lcdyk0517.github.io/dtbTools.html 来辅助判断",
		NoteInfo3:         "请不要使用原装 EmuELEC 卡中的 dtb 文件搭配本系统，否则会导致系统无法启动！",

		BeforeSelectingConsole: "选择机型前请阅读：",
		SubInfo:                "  • 随后复制所选机型及额外映射资源。",
		Continue1:              "  • 按 Enter 继续；输入 q 退出。",
		Continue2:              "\n按 Enter 继续，或输入 ",
		CancelledBye:           "已取消，拜拜 👋",
	},
	Menu2: LanguageMenu2{
		PleaseSelectBrand: "│ 请选择品牌",
		SearchOption:      "按型号关键字搜索",
		SearchPrompt:      "输入型号关键字 (例如 r36s、rgb10max、35h)，直接回车返回: ",
		SearchResultsFmt:  "搜索 \"%s\" 的结果: ",
		SearchNoResults:   "没有找到匹配的机型，请换个关键字试试.",
		SearchHint:        "提示：不知道设备属于哪个品牌？选择搜索，直接输入型号即可。",
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor:   "该品牌可用机型: ",
		NoConsolesFound:        "该品牌下没有机型.",
		Copying:                "开始复制: ",
		CopyingExtra:           "正在复制额外资源...",
		CopyingFmt:             "  开始复制: %s\n",
		SelectBatteryVersion:   "请选择电池驱动版本:",
		BatteryVersionOriginal: "1. arkos 原始驱动（该驱动需要搭配batteryplus来使用否则会在充电时电量显示异常）",
		BatteryVersionFix:      "2. arkos4clone 电池驱动（该版本驱动能够在充电和用电时正确显示电池电量，并且具备老化自适应功能）",
	},
	Cleanup: LanguageCleanup{
		OperationCompleted:   "  ✅  操作完成！",
		ModelsCopied:         "已复制的机型： ",
		Tip1:                 "  提示：请检查目标目录确保文件完整。",
		CleanTargetDir:       "开始清理目标目录...",
		DeleteFileFmt:        "  删除文件: %s\n",
		DeletionFailedFmt:    "    警告: 删除失败 %s: %v\n",
		DeleteDirectoryFmt:   "  删除目录: %s\n",
		DirDeletionFailedFmt: "    警告: 删除目录失败 %s: %v\n",
	},
	Menu4: LanguageMenu4{
		SelectLanguage:    "请选择语言:",
		DefaultEnglish:    "  1. English (默认)",
		Info1:             "输入序号或按 Enter 默认选择 English: ",
		TagFileCreated:    "已创建中文语言标记文件. (.cn created)",
		OperationComplete: "操作完成！已选择语言: ",
	},
	Overclock: LanguageOverclock{
		AskOverclock:         "是否要调整超频参数？",
		OverclockTitle:       "超频参数配置",
		MaxFreqLabel:         "最大频率（开机后可在ES中看到的最大频率）",
		BootFreqLabel:        "启动频率（系统启动时使用的频率）",
		BootFreqMustLE:       "启动频率必须 <= 最大频率",
		DefaultFreqNote:      "默认频率保证正常开机。超过默认频率的选项显示为红色。",
		RedWarning:           "警告：超过默认频率可能导致系统卡死！",
		FreezeWarning:        "如果遇到卡死请降低频率。",
		CurrentConfig:        "当前配置：",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "内存",
		MaxFreq:              "最大",
		BootFreq:             "启动",
		ApplyOverclock:       "正在将超频参数写入 boot.ini...",
		OverclockApplied:     "超频参数已成功应用！",
		UsingDefaults:        "使用默认超频参数 (1296/520/666)。",
		DDRCloneDefault:      "克隆机默认",
		DDROriginalDefault:   "original（原版机）默认",
		OCWarning:            "警告：在此模式下出现任何bug请不要提交issues。\n  导致CPU性能损坏请自行负责。\n  如果你对此行为不了解请选择N。\n\n  哦顺便说一句，该系统不会导致扬声器损坏。\n  如果你担心会有这种风险请不要使用。\n  我也不知道这种离谱的谣言为什么会被传播，甚至有人相信。",
		GPUDDRFreezeTip:      "如果进入系统后遇到卡死请降低频率。",
		AskVoltage:           "是否要增加电压以提高稳定性？",
		VoltageTitle:         "电压增加配置",
		VoltageWarning:       "警告：增加电压可能导致硬件损坏！",
		VoltageConfirmPrompt: "请输入以下内容确认您了解风险：",
		VoltageConfirmText:   "我知道我在做什么",
		VoltageInputPrompt:   "请输入确认文本：",
		VoltageWrongInput:    "输入错误，已取消电压增加。",
		VoltageApplied:       "电压增加已成功应用！",
		VoltageSkipped:       "已跳过电压增加。",
	},
}

var korean = Language{
	Title:   "DTB 선택 도구 - Go 버전",
	Variant: KOREAN,
	Common: LanguageCommon{
		Exit:                 " 종료：",
		SelectNumber:         "\n선택하세요: ",
		InvalidSelection:     "잘못된 선택이에요.",
		PleaseEnterNumber:    "숫자를 입력하세요",
		PressEnterToContinue: "Enter를 눌러주세요...",
		Back:                 "뒤로가기",
		GoodBye:              "빠이!",
	},
	Menu1: LanguageMenu1{
		SelectYourConsole: "DTB Selector - 콘솔을 선택하세요",
		Welcome:           "\n================ 방가방가 ================",
		NoteInfo1:         "NOTE:\n• 이 시스템은 현재 나열된 기기만 지원합니다.\n  만약 사용하시는 기기가 목록에 없다면, 아직 지원되지 않습니다.",
		NoteInfo2:         "💡 사용 중인 기기가 어떤 제품인지 모르는 경우, https://lcdyk0517.github.io/dtbTools.html 을 이용하여 확인하세요.",
		NoteInfo3:         "• 기본 EmuELEC 카드에 포함된 dtb 파일을 이 시스템에 사용하지 마십시오. 부팅이 불가능해집니다.",

		BeforeSelectingConsole: "기기를 선택하기 전에 다음 내용을 읽어주세요:",
		SubInfo:                "  선택한 기기의 필요한 파일이 자동으로 복사됩니다.",
		Continue1:              "  • 계속하려면 Enter 키를 누르고, 종료하려면 'q' 키를 누르세요.",
		Continue2:              "\nEnter 계속，",
		CancelledBye:           "취소되었어요, 안녕! 👋",
	},
	Menu2: LanguageMenu2{
		PleaseSelectBrand: "│ 브랜드를 선택하세요",
		SearchOption:      "모델 키워드로 검색",
		SearchPrompt:      "모델 키워드를 입력하세요 (예: r36s, rgb10max, 35h). 빈 입력 = 뒤로: ",
		SearchResultsFmt:  "\"%s\" 검색 결과: ",
		SearchNoResults:   "일치하는 기기를 찾을 수 없어요. 다른 키워드로 시도해 보세요.",
		SearchHint:        "팁: 브랜드를 모르겠나요? 검색을 선택하고 모델명을 입력하세요.",
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor:   "선택 가능한 기기: ",
		NoConsolesFound:        "기기를 찾을 수 없어요.",
		Copying:                "복사중",
		CopyingExtra:           "기타 리소스 복사중...",
		CopyingFmt:             "  복사중: %s\n",
		SelectBatteryVersion:   "배터리 드라이버 버전을 선택하세요:",
		BatteryVersionOriginal: "1. arkos 오리지널 드라이버 (이 드라이버는 batteryplus와 함께 사용해야 하며, 그렇지 않으면 충전 시 배터리 잔량이 비정상적으로 표시됩니다.)",
		BatteryVersionFix:      "2. arkos4clone 배터리 드라이버 (충전 및 사용 중에 배터리 잔량을 정확하게 표시할 수 있으며, 노화 적응 기능을 갖추고 있습니다.)",
	},
	Cleanup: LanguageCleanup{
		OperationCompleted:   "  ✅  성공!",
		ModelsCopied:         "복제된 모델： ",
		Tip1:                 "  팁: 대상 폴더의 파일을 확인하십시오.",
		CleanTargetDir:       "불필요한 파일 정리...",
		DeleteFileFmt:        "  파일삭제: %s\n",
		DeletionFailedFmt:    "    경고: 삭제실패 %s: %v\n",
		DeleteDirectoryFmt:   "  폴더 삭제: %s\n",
		DirDeletionFailedFmt: "    경고: 폴더 삭제 실패 %s: %v\n",
	},
	Menu4: LanguageMenu4{
		SelectLanguage:    "언어 선택:",
		DefaultEnglish:    "  1. English (기본)",
		Info1:             "번호를 입력하거나 Enter 키를 누르세요. 기본 설정은 영어입니다:",
		TagFileCreated:    "중국어 태그 파일이 생성되었어요. (.ko created)",
		OperationComplete: "작업이 완료되었어요! 언어가 선택되었어요: ",
	},
	Overclock: LanguageOverclock{
		AskOverclock:         "오버클럭 매개변수를 조정하시겠습니까?",
		OverclockTitle:       "오버클럭 매개변수 설정",
		MaxFreqLabel:         "최대 주파수 (부팅 후 ES에서 표시되는 최대 주파수)",
		BootFreqLabel:        "부팅 주파수 (시스템 부팅 시 사용되는 주파수)",
		BootFreqMustLE:       "부팅 주파수는 최대 주파수 이하여야 합니다",
		DefaultFreqNote:      "기본 주파수는 정상 부팅을 보장합니다. 기본을 초과하는 옵션은 빨간색으로 표시됩니다.",
		RedWarning:           "경고: 기본 주파수를 초과하면 시스템이 멈출 수 있습니다!",
		FreezeWarning:        "시스템이 멈추면 주파수를 낮추세요.",
		CurrentConfig:        "현재 설정:",
		ConfigCPU:            "CPU",
		ConfigGPU:            "GPU",
		ConfigDDR:            "메모리",
		MaxFreq:              "최대",
		BootFreq:             "부팅",
		ApplyOverclock:       "boot.ini에 오버클럭 매개변수를 적용 중...",
		OverclockApplied:     "오버클럭 매개변수가 성공적으로 적용되었습니다!",
		UsingDefaults:        "기본 오버클럭 매개변수 사용 (1296/520/666).",
		DDRCloneDefault:      "클론 기본",
		DDROriginalDefault:   "오리지널 기본",
		OCWarning:            "경고: 이 모드에서 발생하는 버그에 대해 issues를 제출하지 마세요.\n  CPU 손상은 사용자 책임입니다.\n  이해하지 못하셨다면 N을 선택하세요.\n\n  참고로 이 시스템은 스피커를 손상시키지 않습니다.\n  그런 위험이 걱정된다면 사용하지 마세요.\n  이런 터무니없는 소문이 왜 퍼지는지 모르겠습니다.",
		GPUDDRFreezeTip:      "시스템 진입 후 멈춤 현상이 발생하면 주파수를 낮추세요.",
		AskVoltage:           "안정성을 높이기 위해 전압을 올리시겠습니까?",
		VoltageTitle:         "전압 인상 설정",
		VoltageWarning:       "경고: 전압을 올리면 하드웨어가 손상될 수 있습니다!",
		VoltageConfirmPrompt: "위험을 이해했음을 확인하려면 입력하세요: ",
		VoltageConfirmText:   "i know what i am doing",
		VoltageInputPrompt:   "확인 텍스트 입력: ",
		VoltageWrongInput:    "입력이 올바르지 않습니다. 전압 인상이 취소되었습니다.",
		VoltageApplied:       "전압 인상이 성공적으로 적용되었습니다!",
		VoltageSkipped:       "전압 인상을 건너뛰었습니다.",
	},
}

var (
	languages = map[LanguageVariant]Language{
		ENGLISH: english,
		CHINESE: chinese,
		KOREAN:  korean,
	}
)

// ===================== 全局输入 reader =====================
var stdinReader = bufio.NewReader(os.Stdin)

// ===================== ANSI 颜色 & Fancy UI =====================
var (
	ansiReset   = "\033[0m"
	ansiRed     = "\033[31m"
	ansiDeepRed = "\033[38;5;196m"
	ansiGreen   = "\033[32m"
	ansiBlue    = "\033[34m"
	ansiCyan    = "\033[36m"
	ansiBold    = "\033[1m"
)

func supportsANSI() bool {
	info, err := os.Stdout.Stat()
	if err != nil {
		return false
	}
	if (info.Mode() & os.ModeCharDevice) == 0 {
		return false
	}
	return true
}

func colorWrap(s, code string) string {
	if !supportsANSI() {
		return s
	}
	return code + s + ansiReset
}

// ===================== ASCII LOGO: LCDYK =====================
func asciiLogoLCDYK() []string {
	return []string{
		`  _     ____ ______   ___  __`,
		` | |   / ___|  _ \ \ / / |/ / `,
		` | |  | |   | | | \ V /| ' /   `,
		` | |__| |___| |_| || | | . \  `,
		` |_____\____|____/ |_| |_|\_\ `,
	}
}

func fancyHeader(title string) {
	clearScreen()
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))
	for _, ln := range asciiLogoLCDYK() {
		fmt.Println(colorWrap(" "+ln, ansiBlue))
	}
	fmt.Println(colorWrap(" "+title, ansiBold+ansiGreen))
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))
	fmt.Println()
}

// ===================== 交互说明（双语） =====================
var (
	HDR  = ansiBold + ansiGreen
	BUL  = ansiBlue
	WARN = ansiBold + ansiRed
	EMP  = ansiBold + ansiCyan
	NOTE = ansiCyan
	DIM  = ""
)

func c(s, style string) string {
	if style == "" {
		return s
	}
	return colorWrap(s, style)
}

func p(s string) {
	fmt.Println(s)
}

func introAndWaitFancy(lang *Language) {
	menu1 := &lang.Menu1
	fancyHeader(menu1.SelectYourConsole)
	p(c(menu1.Welcome, HDR))
	p(c(menu1.NoteInfo1, BUL))
	p(c(menu1.NoteInfo2, NOTE))
	p(c(menu1.NoteInfo3, WARN))
	p("")
	p(c(menu1.BeforeSelectingConsole, EMP))
	p(c(menu1.SubInfo, BUL))
	p(c(menu1.Continue1, NOTE))
	p(c("-----------------------------------------", DIM))

	fmt.Print(colorWrap(menu1.Continue2, ansiBold))
	fmt.Print(colorWrap("q", ansiRed))
	fmt.Print(colorWrap(lang.Common.Exit, ansiBold))
	line, _ := stdinReader.ReadString('\n')
	if strings.TrimSpace(strings.ToLower(line)) == "q" {
		fmt.Println()
		fmt.Println(colorWrap(menu1.CancelledBye, ansiGreen))
		os.Exit(0)
	}
}

// ===================== 屏幕/终端检查 =====================
func isTerminal() bool {
	info, err := os.Stdin.Stat()
	if err != nil {
		return false
	}
	return (info.Mode() & os.ModeCharDevice) != 0
}

func clearScreen() {
	if !isTerminal() {
		return
	}
	switch runtime.GOOS {
	case "windows":
		cmd := exec.Command("cmd", "/c", "cls")
		cmd.Stdout = os.Stdout
		_ = cmd.Run()
	default:
		cmd := exec.Command("clear")
		cmd.Stdout = os.Stdout
		_ = cmd.Run()
	}
}

// ===================== 输入工具（双语提示） =====================
func prompt(msg string) (string, error) {
	if !isTerminal() {
		return "", errors.New("non-interactive stdin")
	}
	fmt.Print(msg)
	line, err := stdinReader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(line), nil
}

func readIntChoice(lang *Language, msg string) (int, error) {
	for {
		resp, err := prompt(msg)
		if err != nil {
			return -1, err
		}
		n, err := strconv.Atoi(resp)
		if err != nil {
			fmt.Println(colorWrap(lang.Common.PleaseEnterNumber, ansiRed))
			continue
		}
		return n, nil
	}
}

// ===================== 文件操作 =====================
func cleanTargetDirectory(lang *Language, baseDir string) error {
	cleanup := &lang.Cleanup

	fmt.Println()
	fmt.Println(colorWrap(cleanup.CleanTargetDir, ansiCyan))

	patterns := []string{"*.dtb", "*.ini", "*.orig", "*.tony", ".cn"}
	for _, pat := range patterns {
		pat := filepath.Join(baseDir, pat)
		matches, err := filepath.Glob(pat)
		if err != nil {
			return err
		}
		for _, f := range matches {
			fmt.Printf(cleanup.DeleteFileFmt, f)
			if err := os.Remove(f); err != nil {
				fmt.Printf(cleanup.DeletionFailedFmt, f, err)
			}
		}
	}

	bmpPath := filepath.Join(baseDir, "BMPs")
	if _, err := os.Stat(bmpPath); err == nil {
		fmt.Printf(cleanup.DeleteDirectoryFmt, bmpPath)
		if err := os.RemoveAll(bmpPath); err != nil {
			fmt.Printf(cleanup.DirDeletionFailedFmt, bmpPath, err)
		}
	}
	return nil
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	out, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	defer out.Close()

	buf := make([]byte, 32*1024)
	if _, err := io.CopyBuffer(out, in, buf); err != nil {
		return err
	}
	return nil
}

func copyDirectory(src, dst string) error {
	info, err := os.Stat(src)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("source is not a directory: %s", src)
	}

	return filepath.WalkDir(src, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		targetPath := filepath.Join(dst, rel)
		if d.IsDir() {
			if err := os.MkdirAll(targetPath, 0o755); err != nil {
				return err
			}
			return nil
		}
		return copyFile(path, targetPath)
	})
}

// ===================== 菜单相关（双语） =====================
type SelectedConsole struct {
	Config      *ConsoleConfig
	DisplayName string
}

type consoleOption struct {
	config      *ConsoleConfig
	brand       string
	displayName string
}

const searchEntry = "__search__"

func normalizeKeyword(s string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(s) {
		switch r {
		case ' ', '\t', '-', '_', '+':
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}

func matchField(normField, normQuery string) bool {
	if normField == "" {
		return false
	}
	if strings.Contains(normField, normQuery) {
		return true
	}
	return strings.HasPrefix(normQuery, normField)
}

func consoleMatchesKeyword(c *ConsoleConfig, normQuery string) bool {
	if normQuery == "" {
		return false
	}
	if matchField(normalizeKeyword(c.RealName), normQuery) {
		return true
	}
	for _, entry := range c.BrandEntries {
		if matchField(normalizeKeyword(entry.Brand), normQuery) ||
			matchField(normalizeKeyword(entry.DisplayName), normQuery) {
			return true
		}
	}
	for _, kw := range c.Keywords {
		if matchField(normalizeKeyword(kw), normQuery) {
			return true
		}
	}
	return false
}

func brandConsoleCount(brand string) int {
	count := 0
	for i := range Consoles {
		for _, entry := range Consoles[i].BrandEntries {
			if entry.Brand == brand {
				count++
			}
		}
	}
	return count
}

func buildBrandOptions(brand string) []consoleOption {
	var options []consoleOption
	for i := range Consoles {
		console := &Consoles[i]
		for _, entry := range console.BrandEntries {
			if entry.Brand == brand {
				options = append(options, consoleOption{
					config:      console,
					brand:       entry.Brand,
					displayName: entry.DisplayName,
				})
			}
		}
	}
	return options
}

func pickConsoleOption(lang *Language, options []consoleOption, showBrand bool) (*consoleOption, error) {
	for i, opt := range options {
		if showBrand {
			fmt.Printf("  %d. %s%s\n", i+1, colorWrap("["+opt.brand+"] ", ansiBlue), opt.displayName)
		} else {
			fmt.Printf("  %d. %s\n", i+1, opt.displayName)
		}
	}
	fmt.Printf("  %d. %s\n", 0, lang.Common.Back)

	for {
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return nil, err
		}
		if choice == 0 {
			return nil, nil
		}
		if choice > 0 && choice <= len(options) {
			selected := options[choice-1]
			fmt.Printf("Selected: %s\n", selected.displayName)
			return &selected, nil
		}
		fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
	}
}

func selectBrand(lang *Language) (string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(lang.Menu2.PleaseSelectBrand, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	for i, brand := range Brands {
		fmt.Printf("  %2d. %-18s (%d)\n", i+1, brand, brandConsoleCount(brand))
	}
	fmt.Printf("  %2d. %s\n", len(Brands)+1, colorWrap(lang.Menu2.SearchOption, ansiCyan))
	fmt.Printf("  %2d. %s\n", 0, lang.Common.Exit)
	fmt.Println()
	fmt.Println(colorWrap(lang.Menu2.SearchHint, NOTE))

	searchChoice := len(Brands) + 1
	for {
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return "", err
		}
		if choice == 0 {
			return "", nil
		}
		if choice == searchChoice {
			return searchEntry, nil
		}
		if choice > 0 && choice < searchChoice {
			return Brands[choice-1], nil
		}
		fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
	}
}

func searchConsoles(lang *Language) (*SelectedConsole, error) {
	for {
		clearScreen()
		fmt.Println()
		fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
		fmt.Printf("│ %s\n", colorWrap(lang.Menu2.SearchOption, ansiBold+ansiGreen))
		fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))

		query, err := prompt(lang.Menu2.SearchPrompt)
		if err != nil {
			return nil, err
		}
		normQuery := normalizeKeyword(query)
		if normQuery == "" {
			return nil, nil
		}

		var options []consoleOption
		for i := range Consoles {
			console := &Consoles[i]
			if !consoleMatchesKeyword(console, normQuery) {
				continue
			}
			for _, entry := range console.BrandEntries {
				options = append(options, consoleOption{
					config:      console,
					brand:       entry.Brand,
					displayName: entry.DisplayName,
				})
			}
		}

		fmt.Println()
		fmt.Println(colorWrap(fmt.Sprintf(lang.Menu2.SearchResultsFmt, strings.TrimSpace(query)), ansiBold+ansiGreen))
		if len(options) == 0 {
			fmt.Println(colorWrap(lang.Menu2.SearchNoResults, ansiRed))
			_, _ = prompt(lang.Common.PressEnterToContinue)
			continue
		}

		opt, err := pickConsoleOption(lang, options, true)
		if err != nil {
			return nil, err
		}
		if opt == nil {
			return nil, nil
		}
		return &SelectedConsole{Config: opt.config, DisplayName: opt.displayName}, nil
	}
}

func selectConsole(lang *Language, brand string) (*SelectedConsole, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Printf("│ %s\n", colorWrap(lang.Menu3.AvailableConsolesFor+brand, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))

	options := buildBrandOptions(brand)
	if len(options) == 0 {
		fmt.Println(colorWrap(lang.Menu3.NoConsolesFound, ansiRed))
		_, _ = prompt(lang.Common.PressEnterToContinue)
		return nil, nil
	}

	opt, err := pickConsoleOption(lang, options, false)
	if err != nil {
		return nil, err
	}
	if opt == nil {
		return nil, nil
	}
	return &SelectedConsole{Config: opt.config, DisplayName: opt.displayName}, nil
}

func showMenu(lang *Language) (*SelectedConsole, error) {
	for {
		brand, err := selectBrand(lang)
		if err != nil {
			return nil, err
		}
		if brand == "" {
			return nil, nil
		}
		if brand == searchEntry {
			selected, err := searchConsoles(lang)
			if err != nil || selected != nil {
				return selected, err
			}
			continue
		}
		selected, err := selectConsole(lang, brand)
		if err != nil {
			return nil, err
		}
		if selected != nil {
			return selected, nil
		}
	}
}

// ===================== 电池版本选择 =====================
func selectBatteryVersion(lang *Language) (string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(lang.Menu3.SelectBatteryVersion, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	fmt.Println(lang.Menu3.BatteryVersionOriginal)
	fmt.Println(lang.Menu3.BatteryVersionFix)

	for {
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return "", err
		}
		switch choice {
		case 1:
			return "original", nil
		case 2:
			return "arkos4clone_fix", nil
		default:
			fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
		}
	}
}

// ===================== 超频选择 =====================
func selectFrequency(lang *Language, label string, options []FreqOption, defaultVal int, defaultLabels map[int]string, extremeFreq int) (int, error) {
	for {
		clearScreen()
		fmt.Println()
		fmt.Println(colorWrap(label, ansiBold+ansiGreen))
		for i, opt := range options {
			prefix := fmt.Sprintf("  %d. %d MHz", i+1, opt.Value)
			if lbl, ok := defaultLabels[opt.Value]; ok {
				fmt.Printf("%s %s\n", prefix, colorWrap("("+lbl+")", ansiBold+ansiCyan))
			} else if opt.Value == defaultVal {
				fmt.Printf("%s %s\n", prefix, colorWrap("(Default)", ansiBold+ansiCyan))
			} else if extremeFreq > 0 && opt.Value == extremeFreq {
				fmt.Println(colorWrap(prefix, ansiBold+ansiDeepRed))
			} else if opt.Value > defaultVal {
				fmt.Println(colorWrap(prefix, ansiRed))
			} else {
				fmt.Println(prefix)
			}
		}
		fmt.Println()
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return 0, err
		}
		if choice >= 1 && choice <= len(options) {
			return options[choice-1].Value, nil
		}
		fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
	}
}

func selectOverclocking(lang *Language) (*OverclockConfig, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(lang.Overclock.OverclockTitle, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	fmt.Println(colorWrap(lang.Overclock.DefaultFreqNote, ansiCyan))
	fmt.Println(colorWrap(lang.Overclock.FreezeWarning, ansiBold+ansiRed))
	fmt.Println()
	fmt.Println(colorWrap(lang.Overclock.AskOverclock, ansiBold+ansiGreen))
	fmt.Println("  1. Yes")
	fmt.Println("  2. No")

	choice, err := readIntChoice(lang, lang.Common.SelectNumber)
	if err != nil {
		return nil, err
	}
	if choice != 1 {
		return nil, nil
	}

	// 超频警告
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiRed))
	fmt.Println(colorWrap(lang.Overclock.OCWarning, ansiBold+ansiRed))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiRed))
	fmt.Println()
	fmt.Println(colorWrap(lang.Overclock.FreezeWarning, ansiBold+ansiRed))
	fmt.Println()
	_, _ = prompt(lang.Common.PressEnterToContinue)

	cfg := &OverclockConfig{
		CPU: FreqSelection{MaxFreq: 1296, BootFreq: 1296},
		GPU: FreqSelection{MaxFreq: 520, BootFreq: 520},
		DDR: FreqSelection{MaxFreq: 666, BootFreq: 666},
	}

	ddrLabels := map[int]string{666: lang.Overclock.DDRCloneDefault, 786: lang.Overclock.DDROriginalDefault}

	// CPU Max
	cpuMax, err := selectFrequency(lang, lang.Overclock.ConfigCPU+" - "+lang.Overclock.MaxFreqLabel, cpuFreqOptions, 1296, nil, 1608)
	if err != nil {
		return nil, err
	}
	cfg.CPU.MaxFreq = cpuMax

	// CPU Boot
	cpuBoot, err := selectFrequency(lang, lang.Overclock.ConfigCPU+" - "+lang.Overclock.BootFreqLabel, filterFreqOptions(cpuFreqOptions, cpuMax), 1296, nil, 1608)
	if err != nil {
		return nil, err
	}
	cfg.CPU.BootFreq = cpuBoot

	// GPU
	gpuFreq, err := selectFrequency(lang, lang.Overclock.ConfigGPU, gpuFreqOptions, 520, nil, 650)
	if err != nil {
		return nil, err
	}
	cfg.GPU.MaxFreq = gpuFreq
	cfg.GPU.BootFreq = gpuFreq

	// DDR 提示
	fmt.Println(colorWrap(lang.Overclock.GPUDDRFreezeTip, ansiBold+ansiRed))

	// DDR
	ddrFreq, err := selectFrequency(lang, lang.Overclock.ConfigDDR, ddrFreqOptions, 666, ddrLabels, 1040)
	if err != nil {
		return nil, err
	}
	cfg.DDR.MaxFreq = ddrFreq
	cfg.DDR.BootFreq = ddrFreq

	// 电压选择
	voltage, err := selectVoltage(lang)
	if err != nil {
		return nil, err
	}
	cfg.Voltage = voltage

	return cfg, nil
}

func filterFreqOptions(options []FreqOption, maxVal int) []FreqOption {
	var filtered []FreqOption
	for _, opt := range options {
		if opt.Value <= maxVal {
			filtered = append(filtered, opt)
		}
	}
	return filtered
}

// ===================== 电压选择 =====================
func selectVoltage(lang *Language) (bool, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(lang.Overclock.VoltageTitle, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	fmt.Println(colorWrap(lang.Overclock.VoltageWarning, ansiBold+ansiRed))
	fmt.Println()
	fmt.Println(colorWrap(lang.Overclock.AskVoltage, ansiBold+ansiGreen))
	fmt.Println("  1. Yes")
	fmt.Println("  2. No")

	choice, err := readIntChoice(lang, lang.Common.SelectNumber)
	if err != nil {
		return false, err
	}
	if choice != 1 {
		fmt.Println(colorWrap(lang.Overclock.VoltageSkipped, ansiCyan))
		return false, nil
	}

	// 要求用户输入确认文本
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiRed))
	fmt.Println(colorWrap(lang.Overclock.VoltageWarning, ansiBold+ansiRed))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiRed))
	fmt.Println()
	fmt.Println(colorWrap(lang.Overclock.VoltageConfirmPrompt, ansiBold+ansiGreen))
	fmt.Println(colorWrap(lang.Overclock.VoltageConfirmText, ansiBold+ansiCyan))
	fmt.Println()

	resp, err := prompt(lang.Overclock.VoltageInputPrompt)
	if err != nil {
		return false, err
	}

	if strings.TrimSpace(strings.ToLower(resp)) != strings.ToLower(lang.Overclock.VoltageConfirmText) {
		fmt.Println(colorWrap(lang.Overclock.VoltageWrongInput, ansiRed))
		return false, nil
	}

	fmt.Println(colorWrap(lang.Overclock.VoltageApplied, ansiBold+ansiGreen))
	return true, nil
}

// ===================== 写入超频参数到 boot.ini =====================
func applyOverclockingToBootIni(baseDir string, oc *OverclockConfig) error {
	bootIni := filepath.Join(baseDir, "boot.ini")
	data, err := os.ReadFile(bootIni)
	if err != nil {
		return err
	}

	content := string(data)

	// 写入用户选择的频率参数
	ocArgs := fmt.Sprintf("max_cpufreq=%d boot_cpufreq=%d max_gpufreq=%d max_ddrfreq=%d",
		oc.CPU.MaxFreq, oc.CPU.BootFreq, oc.GPU.MaxFreq, oc.DDR.MaxFreq)
	re := regexp.MustCompile(`(setenv\s+bootargs\s+"[^"]*?)((?:\s+(?:max_cpufreq|boot_cpufreq|max_gpufreq|boot_gpufreq|max_ddrfreq|boot_ddrfreq)=\d+)*)\s*"`)
	if re.MatchString(content) {
		content = re.ReplaceAllString(content, "${1} "+ocArgs+"\"")
	}

	if oc.Voltage {
		// 添加 dtbo_loadaddr 变量
		content = strings.Replace(content,
			`setenv dtb_loadaddr "0x01f00000"`,
			"setenv dtb_loadaddr \"0x01f00000\"\nsetenv dtbo_loadaddr \"0x01f30000\"", 1)

		// 在 load dtb 后面追加 load dtbo 和 fdt 操作
		lines := strings.Split(content, "\n")
		var newLines []string
		for _, line := range lines {
			newLines = append(newLines, line)
			if strings.Contains(line, "load mmc 1:1 ${dtb_loadaddr}") {
				newLines = append(newLines, "load mmc 1:1 ${dtbo_loadaddr} consoles/dtbo/rk3326-oc-voltage.dtbo")
				newLines = append(newLines, "")
				newLines = append(newLines, "fdt addr ${dtb_loadaddr}")
				newLines = append(newLines, "fdt resize 8192")
				newLines = append(newLines, "fdt apply ${dtbo_loadaddr}")
			}
		}
		content = strings.Join(newLines, "\n")
	}

	return os.WriteFile(bootIni, []byte(content), 0644)
}

// ===================== 复制逻辑 =====================
func copySelectedConsole(lang *Language, selected *SelectedConsole, baseDir string) error {
	if selected == nil || selected.Config == nil {
		return errors.New("no console selected")
	}

	fmt.Printf("\n%s\n", colorWrap(lang.Menu3.Copying+selected.DisplayName, ansiCyan))

	srcPath := filepath.Join(baseDir, "consoles", selected.Config.RealName)
	if _, err := os.Stat(srcPath); os.IsNotExist(err) {
		return fmt.Errorf("source directory not found: %s", srcPath)
	}

	if err := copyDirectory(srcPath, baseDir); err != nil {
		return fmt.Errorf("failed to copy console: %v", err)
	}

	// 让用户选择电池驱动版本并复制 Image
	batteryVersion, err := selectBatteryVersion(lang)
	if err != nil {
		return fmt.Errorf("failed to select battery version: %v", err)
	}
	if batteryVersion != "" {
		kernelSrc := filepath.Join(baseDir, "consoles", "kernel", batteryVersion, "Image")
		if _, err := os.Stat(kernelSrc); err == nil {
			fmt.Printf(lang.Menu3.CopyingFmt, "kernel/"+batteryVersion+"/Image")
			if err := copyFile(kernelSrc, filepath.Join(baseDir, "Image")); err != nil {
				return fmt.Errorf("failed to copy kernel Image: %v", err)
			}
		} else {
			fmt.Printf("  Warning: Kernel Image not found: %s\n", kernelSrc)
		}
	}

	// 超频参数选择
	ocCfg, err := selectOverclocking(lang)
	if err != nil {
		return fmt.Errorf("failed to select overclocking: %v", err)
	}
	if ocCfg != nil {
		fmt.Println(colorWrap(lang.Overclock.ApplyOverclock, ansiCyan))
		if err := applyOverclockingToBootIni(baseDir, ocCfg); err != nil {
			return fmt.Errorf("failed to apply overclocking: %v", err)
		}
		fmt.Println(colorWrap(lang.Overclock.OverclockApplied, ansiBold+ansiGreen))
	} else {
		fmt.Println(colorWrap(lang.Overclock.UsingDefaults, ansiCyan))
	}

	fmt.Println(colorWrap(lang.Menu3.CopyingExtra, ansiCyan))
	for _, extra := range selected.Config.ExtraSources {
		extraSrc := filepath.Join(baseDir, "consoles", extra)
		if _, err := os.Stat(extraSrc); err == nil {
			fmt.Printf(lang.Menu3.CopyingFmt, extra)
			if err := copyDirectory(extraSrc, baseDir); err != nil {
				return fmt.Errorf("failed to copy extra source %s: %v", extra, err)
			}
		} else {
			fmt.Printf("  Warning: Extra source not found: %s\n", extra)
		}
	}

	return nil
}

func showSuccessFancy(lang *Language, consoleName string) {
	fmt.Println()
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))
	fmt.Println(colorWrap(lang.Cleanup.OperationCompleted, ansiBold+ansiGreen))
	fmt.Printf("  %s\n", colorWrap(lang.Cleanup.ModelsCopied+consoleName, ansiBold+ansiBlue))
	fmt.Println(colorWrap(lang.Cleanup.Tip1, ansiCyan))
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))

	_, _ = prompt(lang.Common.PressEnterToContinue)
}

func selectMenuLanguage() (*Language, error) {
	clearScreen()

	fmt.Println("====================================================")
	fmt.Println(" - Select the language you want to use for the menu")
	fmt.Println(" - 请选择菜单所使用的语言")
	fmt.Println(" - 메뉴에 사용할 언어를 선택하세요")
	fmt.Println("")
	fmt.Println("1. English")
	fmt.Println("2. 中文")
	fmt.Println("3. 한국어")
	fmt.Println("====================================================")

	for {
		resp, err := prompt("Select number: ")
		if err != nil {
			return nil, err
		}
		switch strings.TrimSpace(resp) {
		case "", "1":
			return &english, nil
		case "2":
			return &chinese, nil
		case "3":
			return &korean, nil
		default:
			fmt.Println("Invalid selection.")
		}
	}
}

// ===================== main =====================
func main() {
	// get the directory where the executable binary is located
	exePath, err := os.Executable()
	if err != nil {
		fmt.Printf("Failed to get exectuable directory: %v\n", err)
		return
	}
	baseDir := filepath.Dir(exePath)

	// Select lanauage for Menu.
	lang, err := selectMenuLanguage()
	if err != nil {
		fmt.Println("Language selection error:", err)
		return
	}

	clearScreen()
	fmt.Println(colorWrap(lang.Title, ansiBold+ansiGreen))
	introAndWaitFancy(lang)

	selected, err := showMenu(lang)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	if selected == nil {
		fmt.Println(colorWrap(lang.Common.GoodBye, ansiGreen))
		return
	}

	if err := cleanTargetDirectory(lang, baseDir); err != nil {
		fmt.Printf("Error cleaning directory: %v\n", err)
		return
	}

	if err := copySelectedConsole(lang, selected, baseDir); err != nil {
		fmt.Printf("Error copying files: %v\n", err)
		return
	}

	showSuccessFancy(lang, selected.DisplayName)

	// 根据菜单语言生成语言标记文件
	if lang.Variant == CHINESE || lang.Variant == KOREAN {
		f, err := os.Create(filepath.Join(baseDir, "."+string(lang.Variant)))
		if err != nil {
			fmt.Printf("Error creating language file: %v\n", err)
			return
		}
		defer f.Close()
		fmt.Println(colorWrap(lang.Menu4.TagFileCreated, ansiCyan))
	}

	fmt.Println(colorWrap(lang.Menu4.OperationComplete+string(lang.Variant), ansiGreen))
}
