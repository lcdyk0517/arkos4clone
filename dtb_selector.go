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
	"runtime"
	"strconv"
	"strings"
)

// ===================== 配置：别名 & 排除 =====================
type ConsoleConfig struct {
	RealName     string
	BrandEntries []BrandEntry
	ExtraSources []string
}

type BrandEntry struct {
	Brand       string
	DisplayName string
}

// 控制台配置
var Consoles = []ConsoleConfig{
	{
		RealName: "mymini",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mymini"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "mini40",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan Mini40"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "r36max",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "r36pro",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Pro"},
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "xf35h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF35H"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "xf40h",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40H"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "dc40v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF40V"},
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC40V"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "dc35v",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan DC35V"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "xf28",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan XF28"},
		},
		ExtraSources: []string{"logo/480P-1/", "kernel/common/"},
	},
	{
		RealName: "r36max2",
		BrandEntries: []BrandEntry{
			{Brand: "XiFan HandHelds", DisplayName: "XiFan R36Max2"},
		},
		ExtraSources: []string{"logo/768P/", "kernel/common/"},
	},
	{
		RealName: "k36s",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole K36S"},
			{Brand: "AISLPC", DisplayName: "GameConsole R36T"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "r36tmax",
		BrandEntries: []BrandEntry{
			{Brand: "AISLPC", DisplayName: "GameConsole R36T MAX"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "hg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole HG36 (HG3506)"},
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480p/", "kernel/common/"},
	},
	{
		RealName: "r36ultra",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole R36Ultra"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "rx6h",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RX6H"},
		},
		ExtraSources: []string{"logo/480p/", "kernel/common/"},
	},
	{
		RealName: "r46h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R46H"},
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX ProMax"},
		},
		ExtraSources: []string{"logo/768p/", "kernel/common/"},
	},
	{
		RealName: "r40xx",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R40XX"},
		},
		ExtraSources: []string{"logo/768p/", "kernel/common/"},
	},
	{
		RealName: "r45h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R45H"},
			{Brand: "GameConsole", DisplayName: "GameConsole R36H ProMax"},
		},
		ExtraSources: []string{"logo/768p/", "kernel/common/"},
	},
	{
		RealName: "r36splus",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36sPlus"},
		},
		ExtraSources: []string{"logo/720p/", "kernel/common/"},
	},
	{
		RealName: "origin panel0",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 0"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "origin panel1",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 1"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "origin panel2",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 2"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "origin panel3",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 3"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "origin panel4",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "v22 panel4",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36s Panel 4 V22"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "origin panel4",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36XX"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "r36h",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R36H"},
			{Brand: "GameConsole", DisplayName: "GameConsole O30S"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "r50s",
		BrandEntries: []BrandEntry{
			{Brand: "GameConsole", DisplayName: "GameConsole R50S"},
		},
		ExtraSources: []string{"logo/854x480P/", "kernel/common/"},
	},
	{
		RealName: "sauce v03",
		BrandEntries: []BrandEntry{
			{Brand: "SaySouce R36s", DisplayName: "Soy Sauce V03 (ArkOS4Clone kernel)"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "sauce v04",
		BrandEntries: []BrandEntry{
			{Brand: "SaySouce R36s", DisplayName: "Soy Sauce V04 (ArkOS4Clone kernel)"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "a10mini",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "a10miniv2",
		BrandEntries: []BrandEntry{
			{Brand: "YMC", DisplayName: "YMC A10MINI V2"},
		},
		ExtraSources: []string{"logo/540P/", "kernel/common/"},
	},
	{
		RealName: "k36",
		BrandEntries: []BrandEntry{
			{Brand: "Kinhank", DisplayName: "K36 Origin Panel"},
			{Brand: "Clone R36s", DisplayName: "Clone Type 1 Without Amplifier And Invert Right Joystick"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "clone type2",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 Without Amplifier"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "clone type2 amp",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 2 With Amplifier"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "clone type3",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 3"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "clone type4",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 4"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "clone type5",
		BrandEntries: []BrandEntry{
			{Brand: "Clone R36s", DisplayName: "Clone Type 5"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "xgb36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole XGB36 (G26)"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "t16max",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole T16MAX"},
		},
		ExtraSources: []string{"logo/720P/", "kernel/common/"},
	},
	{
		RealName: "u8",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8"},
		},
		ExtraSources: []string{"logo/480P5-3/", "kernel/common/"},
	},
	{
		RealName: "u8-v2",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole U8 V2"},
		},
		ExtraSources: []string{"logo/480P5-3/", "kernel/common/"},
	},
	{
		RealName: "g350",
		BrandEntries: []BrandEntry{
			{Brand: "Batlexp", DisplayName: "Batlexp G350"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "dr28s",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "Diium Dr28s"},
		},
		ExtraSources: []string{"logo/480P-270/", "kernel/common/"},
	},
	{
		RealName: "d007",
		BrandEntries: []BrandEntry{
			{Brand: "Diium(SZDiiER)", DisplayName: "SZDiiER D007(Plus)"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "rg36",
		BrandEntries: []BrandEntry{
			{Brand: "Other", DisplayName: "GameConsole RG36"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
	{
		RealName: "rgb20s",
		BrandEntries: []BrandEntry{
			{Brand: "Powkiddy", DisplayName: "Powkiddy RGB20S"},
		},
		ExtraSources: []string{"logo/480P/", "kernel/common/"},
	},
}

// 品牌列表
var Brands = []string{
	"YMC",
	"AISLPC",
	"Batlexp",
	"Kinhank",
	"Powkiddy",
	"Clone R36s",
	"GameConsole",
	"SaySouce R36s",
	"Diium(SZDiiER)",
	"XiFan HandHelds",
	"Other",
}

// Multiple Language Support
type Language struct {
	Title   string
	Variant LanguageVariant

	Common  LanguageCommon
	Menu1   LanguageMenu1
	Menu2   LanguageMenu2
	Menu3   LanguageMenu3
	Cleanup LanguageCleanup
	Menu4   LanguageMenu4
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
}

type LanguageMenu3 struct {
	AvailableConsolesFor string
	NoConsolesFound      string
	Copying              string
	CopyingExtra         string
	CopyingFmt           string
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
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor: "Available consoles for: ",
		NoConsolesFound:      "No consoles found.",
		Copying:              "Copying: ",
		CopyingExtra:         "Copying extra resources...",
		CopyingFmt:           "  Copying: %s\n",
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
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor: "该品牌可用机型: ",
		NoConsolesFound:      "该品牌下没有机型.",
		Copying:              "开始复制: ",
		CopyingExtra:         "正在复制额外资源...",
		CopyingFmt:           "  开始复制: %s\n",
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
	},
	Menu3: LanguageMenu3{
		AvailableConsolesFor: "선택 가능한 기기: ",
		NoConsolesFound:      "기기를 찾을 수 없어요.",
		Copying:              "복사중",
		CopyingExtra:         "기타 리소스 복사중...",
		CopyingFmt:           "  복사중: %s\n",
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
	ansiReset = "\033[0m"
	ansiRed   = "\033[31m"
	ansiGreen = "\033[32m"
	ansiBlue  = "\033[34m"
	ansiCyan  = "\033[36m"
	ansiBold  = "\033[1m"
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

func selectBrand(lang *Language) (string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(lang.Menu2.PleaseSelectBrand, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	for i, brand := range Brands {
		fmt.Printf("  %d. %s\n", i+1, brand)
	}
	fmt.Printf("  %d. %s\n", 0, lang.Common.Exit)

	for {
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return "", err
		}
		if choice == 0 {
			return "", nil
		}
		if choice > 0 && choice <= len(Brands) {
			return Brands[choice-1], nil
		}
		fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
	}
}

func selectConsole(lang *Language, brand string) (*ConsoleConfig, string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Printf("│ %s\n", colorWrap(lang.Menu3.AvailableConsolesFor+brand, ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))

	// 重新组织数据结构，每个显示名称对应一个配置
	type consoleOption struct {
		config      *ConsoleConfig
		displayName string
	}
	var consoleOptions []consoleOption

	// 查找属于当前品牌的所有设备，每个显示名称都作为独立选项
	for i := range Consoles {
		console := &Consoles[i]
		for _, entry := range console.BrandEntries {
			if entry.Brand == brand {
				consoleOptions = append(consoleOptions, consoleOption{
					config:      console,
					displayName: entry.DisplayName,
				})
			}
		}
	}

	if len(consoleOptions) == 0 {
		fmt.Println(colorWrap(lang.Menu3.NoConsolesFound, ansiRed))
		_, _ = prompt(lang.Common.PressEnterToContinue)
		return nil, "", nil
	}

	// 显示菜单 - 每个选项单独一行
	for i, option := range consoleOptions {
		fmt.Printf("  %d. %s\n", i+1, option.displayName)
	}
	fmt.Printf("  %d. %s\n", 0, lang.Common.Back)

	for {
		choice, err := readIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return nil, "", err
		}
		if choice == 0 {
			return nil, "", nil
		}
		if choice > 0 && choice <= len(consoleOptions) {
			selected := consoleOptions[choice-1]
			fmt.Printf("Selected: %s\n", selected.displayName)
			return selected.config, selected.displayName, nil
		}
		fmt.Println(colorWrap(lang.Common.InvalidSelection, ansiRed))
	}
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
		console, displayName, err := selectConsole(lang, brand)
		if err != nil {
			return nil, err
		}
		if console != nil {
			return &SelectedConsole{Config: console, DisplayName: displayName}, nil
		}
	}
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
