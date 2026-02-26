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

var currentMenuLang = "en"

var i18n = map[string]map[string]string{
	"title": {
		"en": "DTB Selector Tool - Go Version",
		"cn": "DTB 选择工具 - Go 版本",
		"kr": "DTB 선택 도구 - Go 버전",
	},
	"choice_console": {
		"en": "DTB Selector - Select Your Console",
		"cn": "DTB Selector - 请选择机型",
		"kr": "DTB Selector - 콘솔을 선택하세요",
	},
	"welcome_info1": {
		"en": "\n================ Welcome ================",
		"cn": "\n================ 欢迎使用 ================",
		"kr": "\n================ 방가방가 ================",
	},
	"welcome_info2": {
		"en": "NOTE:\n• This system currently only supports the listed R36 clones;\n  if your clone is not in the list, it is not supported yet.",
		"cn": "说明：\n本系统目前只支持下列机型，如果你的 R36 克隆机不在列表中，则暂时无法使用。",
		"kr": "NOTE:\n• 이 시스템은 현재 나열된 기기만 지원합니다.\n  만약 사용하시는 기기가 목록에 없다면, 아직 지원되지 않습니다.",
	},
	"welcome_info3": {
		"en": "💡 If you don't know what clone your device is, use https://lcdyk0517.github.io/dtbTools.html to help identify it",
		"cn": "💡 如果你不知道你的设备是什么克隆，可以使用 https://lcdyk0517.github.io/dtbTools.html 来辅助判断",
		"kr": "💡 사용 중인 기기가 어떤 제품인지 모르는 경우, https://lcdyk0517.github.io/dtbTools.html 을 이용하여 확인하세요.",
	},
	"welcome_info4": {
		"en": "• Do NOT use the dtb files from the stock EmuELEC card with this system — it will brick the boot.",
		"cn": "请不要使用原装 EmuELEC 卡中的 dtb 文件搭配本系统，否则会导致系统无法启动！",
		"kr": "• 기본 EmuELEC 카드에 포함된 dtb 파일을 이 시스템에 사용하지 마십시오. 부팅이 불가능해집니다.",
	},
	"welcome_info5": {
		"en": "Before selecting a console:",
		"cn": "选择机型前请阅读：",
		"kr": "기기를 선택하기 전에 다음 내용을 읽어주세요:",
	},
	"welcome_info6": {
		"en": "  then copies the chosen console and any mapped extra sources.",
		"cn": "  • 随后复制所选机型及额外映射资源。",
		"kr": "  선택한 기기의 필요한 파일이 자동으로 복사됩니다.",
	},
	"welcome_info7": {
		"en": "  • Press Enter to continue; type 'q' to quit.",
		"cn": "  • 按 Enter 继续；输入 q 退出。",
		"kr": "  • 계속하려면 Enter 키를 누르고, 종료하려면 'q' 키를 누르세요.",
	},
	"welcome_info8": {
		"en": "\nPress Enter to continue, Press ",
		"cn": "\n按 Enter 继续，或输入 ",
		"kr": "\nEnter 계속，",
	},
	"welcome_info9": {
		"en": " Exit : ",
		"cn": " 退出：",
		"kr": " 종료：",
	},
	"welcome_info10": {
		"en": "Cancelled, bye! 👋",
		"cn": "已取消，拜拜 👋",
		"kr": "취소되었어요, 안녕! 👋",
	},
	"select_brand1": {
		"en": "│ Please select a brand",
		"cn": "│ 请选择品牌",
		"kr": "│ 브랜드를 선택하세요",
	},
	"select_brand2": {
		"en": "Exit",
		"cn": "退出",
		"kr": "종료",
	},
	"select_brand3": {
		"en": "\nSelect number: ",
		"cn": "\n选择序号: ",
		"kr": "\n선택하세요: ",
	},
	"select_brand4": {
		"en": "Invalid selection.",
		"cn": "选择无效，请重试.",
		"kr": "잘못된 선택이에요.",
	},
	"select_brand5": {
		"en": "Please enter a number",
		"cn": "请输入数字",
		"kr": "숫자를 입력하세요",
	},
	"select_console1": {
		"en": "Available consoles for: ",
		"cn": "该品牌可用机型: ",
		"kr": "선택 가능한 기기: ",
	},
	"select_console2": {
		"en": "No consoles found.",
		"cn": "该品牌下没有机型.",
		"kr": "기기를 찾을 수 없어요.",
	},
	"select_console3": {
		"en": "Press Enter to continue...",
		"cn": "按 Enter 返回...",
		"kr": "Enter를 눌러주세요...",
	},
	"select_console4": {
		"en": "Back",
		"cn": "返回",
		"kr": "뒤로가기",
	},
	"select_console5": {
		"en": "\nSelect number: ",
		"cn": "\n选择序号: ",
		"kr": "\n번호를 선택하세요: ",
	},
	"select_console6": {
		"en": "Invalid selection.",
		"cn": "选择无效，请重试.",
		"kr": "잘못된 선택이에요.",
	},
	"copy_selected_console1": {
		"en": "Copying: ",
		"cn": "开始复制: ",
		"kr": "복사중",
	},
	"copy_selected_console2": {
		"en": "Copying extra resources...",
		"cn": "正在复制额外资源...",
		"kr": "기타 리소스 복사중...",
	},
	"copy_selected_console3": {
		"en": "  Copying: %s\n",
		"cn": "  Copying: %s\n",
		"kr": "  복사중: %s\n",
	},
	"success_fancy1": {
		"en": "  ✅  Operation completed!",
		"cn": "  ✅  操作完成！",
		"kr": "  ✅  성공!",
	},
	"success_fancy2": {
		"en": "Models that have been copied： ",
		"cn": "已复制的机型： ",
		"kr": "복제된 모델： ",
	},
	"success_fancy3": {
		"en": "  Tip: verify files in the destination directory.",
		"cn": "  提示：请检查目标目录确保文件完整。",
		"kr": "  팁: 대상 폴더의 파일을 확인하십시오.",
	},
	"clean_target_directory1": {
		"en": "Cleaning target directory...",
		"cn": "开始清理目标目录...",
		"kr": "불필요한 파일 정리...",
	},
	"clean_target_directory2": {
		"en": "  Delete file: %s\n",
		"cn": "  删除文件: %s\n",
		"kr": "  파일삭제: %s\n",
	},
	"clean_target_directory3": {
		"en": "    Warning: Deletion failed %s: %v\n",
		"cn": "    警告: 删除失败 %s: %v\n",
		"kr": "    경고: 삭제실패 %s: %v\n",
	},
	"clean_target_directory4": {
		"en": "  Delete directory: %s\n",
		"cn": "  删除目录: %s\n",
		"kr": "  폴더 삭제: %s\n",
	},
	"clean_target_directory5": {
		"en": "    Warning: Directory deletion failed %s: %v\n",
		"cn": "    警告: 删除目录失败 %s: %v\n",
		"kr": "    경고: 폴더 삭제 실패 %s: %v\n",
	},
	"clean_target_directory6": {
		"en": "",
		"cn": "",
		"kr": "",
	},
	"select_language1": {
		"en": "Select language:",
		"cn": "请选择语言:",
		"kr": "언어 선택:",
	},
	"select_language2": {
		"en": "  1. English (Default)",
		"cn": "  1. English (默认)",
		"kr": "  1. English (기본)",
	},
	"select_language3": {
		"en": "Enter the number or press Enter. English is the default selection: ",
		"cn": "输入序号或按 Enter 默认选择 English: ",
		"kr": "번호를 입력하거나 Enter 키를 누르세요. 기본 설정은 영어입니다:",
	},
	"select_language4": {
		"en": "Invalid selection.",
		"cn": "选择无效，请重试 (Invalid selection).",
		"kr": "잘못된 선택이에요.",
	},
	"create_language1": {
		"en": "Chinese language tag file has been created. (.cn created)",
		"cn": "已创建中文语言标记文件. (.cn created)",
		"kr": "중국어 태그 파일이 생성되었어요. (.cn created)",
	},
	"create_language2": {
		"en": "Operation complete! Language selected: ",
		"cn": "操作完成！已选择语言: ",
		"kr": "작업이 완료되었어요! 언어가 선택되었어요: ",
	},
	"goodbye": {
		"en": "Goodbye!",
		"cn": "再见！",
		"kr": "빠이!",
	},
}

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

func tr(key string) string {
	if langMap, ok := i18n[key]; ok {
		if val, ok := langMap[currentMenuLang]; ok {
			return val
		}
		return langMap["en"]
	}
	return key
}

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

func introAndWaitFancy() {
	fancyHeader(tr("choice_console"))
	p(c(tr("welcome_info1"), HDR))
	p(c(tr("welcome_info2"), BUL))
	p(c(tr("welcome_info3"), NOTE))
	p(c(tr("welcome_info4"), WARN))
	p("")
	p(c(tr("welcome_info5"), EMP))
	p(c(tr("welcome_info6"), BUL))
	p(c(tr("welcome_info7"), NOTE))
	p(c("-----------------------------------------", DIM))
	
	fmt.Print(colorWrap(tr("welcome_info8"), ansiBold))
	fmt.Print(colorWrap("q", ansiRed))
	fmt.Print(colorWrap(tr("welcome_info9"), ansiBold))
	line, _ := stdinReader.ReadString('\n')
	if strings.TrimSpace(strings.ToLower(line)) == "q" {
		fmt.Println()
		fmt.Println(colorWrap(tr("welcome_info10"), ansiGreen))
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

func readIntChoice(msg string) (int, error) {
	for {
		resp, err := prompt(msg)
		if err != nil {
			return -1, err
		}
		n, err := strconv.Atoi(resp)
		if err != nil {
			fmt.Println(colorWrap(tr("select_brand5"), ansiRed))
			continue
		}
		return n, nil
	}
}

// ===================== 文件操作 =====================
func cleanTargetDirectory(baseDir string) error {
	fmt.Println()
	fmt.Println(colorWrap(tr("clean_target_directory1"), ansiCyan))

	patterns := []string{"*.dtb", "*.ini", "*.orig", "*.tony", ".cn"}
	for _, pat := range patterns {
		pat := filepath.Join(baseDir, pat)
		matches, err := filepath.Glob(pat)
		if err != nil {
			return err
		}
		for _, f := range matches {
			fmt.Printf(tr("clean_target_directory2"), f)
			if err := os.Remove(f); err != nil {
				fmt.Printf(tr("clean_target_directory3"), f, err)
			}
		}
	}

	bmpPath := filepath.Join(baseDir, "BMPs")
	if _, err := os.Stat(bmpPath); err == nil {
		fmt.Printf(tr("clean_target_directory4"), bmpPath)
		if err := os.RemoveAll(bmpPath); err != nil {
			fmt.Printf(tr("clean_target_directory5"), bmpPath, err)
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

func selectBrand() (string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Println(colorWrap(tr("select_brand1"), ansiBold+ansiGreen))
	fmt.Println(colorWrap("└────────────────────────────────────────┘", ansiCyan))
	for i, brand := range Brands {
		fmt.Printf("  %d. %s\n", i+1, brand)
	}
	fmt.Printf("  %d. %s\n", 0, tr("select_brand2"))

	for {
		choice, err := readIntChoice(tr("select_brand3"))
		if err != nil {
			return "", err
		}
		if choice == 0 {
			return "", nil
		}
		if choice > 0 && choice <= len(Brands) {
			return Brands[choice-1], nil
		}
		fmt.Println(colorWrap(tr("select_brand4"), ansiRed))
	}
}

func selectConsole(brand string) (*ConsoleConfig, string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap("┌────────────────────────────────────────┐", ansiCyan))
	fmt.Printf("│ %s\n", colorWrap(tr("select_console1")+brand, ansiBold+ansiGreen))
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
		fmt.Println(colorWrap(tr("select_console2"), ansiRed))
		_, _ = prompt(tr("select_console3"))
		return nil, "", nil
	}

	// 显示菜单 - 每个选项单独一行
	for i, option := range consoleOptions {
		fmt.Printf("  %d. %s\n", i+1, option.displayName)
	}
	fmt.Printf("  %d. %s\n", 0, tr("select_console4"))

	for {
		choice, err := readIntChoice(tr("select_console5"))
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
		fmt.Println(colorWrap(tr("select_console6"), ansiRed))
	}
}
func showMenu() (*SelectedConsole, error) {
	for {
		brand, err := selectBrand()
		if err != nil {
			return nil, err
		}
		if brand == "" {
			return nil, nil
		}
		console, displayName, err := selectConsole(brand)
		if err != nil {
			return nil, err
		}
		if console != nil {
			return &SelectedConsole{Config: console, DisplayName: displayName}, nil
		}
	}
}

// ===================== 复制逻辑 =====================
func copySelectedConsole(selected *SelectedConsole, baseDir string) error {
	if selected == nil || selected.Config == nil {
		return errors.New("no console selected")
	}

	fmt.Printf("\n%s\n", colorWrap(tr("copy_selected_console1")+selected.DisplayName, ansiCyan))

	srcPath := filepath.Join(baseDir, "consoles", selected.Config.RealName)
	if _, err := os.Stat(srcPath); os.IsNotExist(err) {
		return fmt.Errorf("source directory not found: %s", srcPath)
	}

	if err := copyDirectory(srcPath, baseDir); err != nil {
		return fmt.Errorf("failed to copy console: %v", err)
	}

	fmt.Println(colorWrap(tr("copy_selected_console2"), ansiCyan))
	for _, extra := range selected.Config.ExtraSources {
		extraSrc := filepath.Join(baseDir, "consoles", extra)
		if _, err := os.Stat(extraSrc); err == nil {
			fmt.Printf(tr("copy_selected_console3"), extra)
			if err := copyDirectory(extraSrc, baseDir); err != nil {
				return fmt.Errorf("failed to copy extra source %s: %v", extra, err)
			}
		} else {
			fmt.Printf("  Warning: Extra source not found: %s\n", extra)
		}
	}
	return nil
}

func showSuccessFancy(consoleName string) {
	fmt.Println()
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))
	fmt.Println(colorWrap(tr("success_fancy1"), ansiBold+ansiGreen))
	fmt.Printf("  %s\n", colorWrap(tr("success_fancy2")+consoleName, ansiBold+ansiBlue))
	fmt.Println(colorWrap(tr("success_fancy3"), ansiCyan))
	fmt.Println(colorWrap(strings.Repeat("=", 64), ansiCyan))

	_, _ = prompt(tr("select_console3"))
}

// ===================== 语言选择 =====================
func selectLanguage() (string, error) {
	clearScreen()
	fmt.Println()
	fmt.Println(colorWrap(tr("select_language1"), EMP))
	fmt.Println(tr("select_language2"))
	fmt.Println("  2. 中文")

	for {
		choice, err := prompt(tr("select_language3"))
		if err != nil {
			return "", err
		}

		switch strings.TrimSpace(choice) {
		case "", "1":
			return "en", nil
		case "2":
			return "cn", nil
		default:
			fmt.Println(colorWrap(tr("select_language4"), ansiRed))
		}
	}
}

// 创建语言标记文件
func createLanguageFile(lang string, baseDir string) error {
	if lang == "cn" {
		f, err := os.Create(filepath.Join(baseDir, ".cn"))
		if err != nil {
			return err
		}
		defer f.Close()
		fmt.Println(colorWrap(tr("create_language1"), ansiCyan))
	}
	return nil
}

func selectMenuLanguage() (string, error) {
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
			return "", err
		}
		switch strings.TrimSpace(resp) {
			case "", "1":
				return "en", nil
			case "2":
				return "cn", nil
			case "3":
				return "kr", nil
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
	menuLang, err := selectMenuLanguage()
	if err != nil {
		fmt.Println("Language selection error:", err)
		return
	}
	currentMenuLang = menuLang

	clearScreen()
	fmt.Println(colorWrap(tr("title"), ansiBold+ansiGreen))
	introAndWaitFancy()

	selected, err := showMenu()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	if selected == nil {
		fmt.Println(colorWrap(tr("goodbye"), ansiGreen))
		return
	}

	if err := cleanTargetDirectory(baseDir); err != nil {
		fmt.Printf("Error cleaning directory: %v\n", err)
		return
	}

	if err := copySelectedConsole(selected, baseDir); err != nil {
		fmt.Printf("Error copying files: %v\n", err)
		return
	}

	showSuccessFancy(selected.DisplayName)

	// ===== 新增语言选择 =====
	lang, err := selectLanguage()
	if err != nil {
		fmt.Printf("Error selecting language: %v\n", err)
		return
	}
	if err := createLanguageFile(lang, baseDir); err != nil {
		fmt.Printf("Error creating language file: %v\n", err)
		return
	}

	fmt.Println(colorWrap(tr("create_language2")+lang, ansiGreen))
}
