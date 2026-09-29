package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"arkos4clone/dtbtools/internal/ops"
	"arkos4clone/dtbtools/internal/ui"
)

// Version is injected at build time via -ldflags "-X main.Version=<date>"
var Version = "dev"

// fetchLatestReleaseTag 拉取 GitHub 最新 release 的 tag; 失败返回 "" (静默)
func fetchLatestReleaseTag() string {
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get("https://api.github.com/repos/lcdyk0517/arkos4clone/releases/latest")
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	var d struct {
		TagName string `json:"tag_name"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&d); err != nil {
		return ""
	}
	return d.TagName
}

// normalizeVersion 只保留数字 ("2026.09.29" -> "20260929"), 便于与 release tag 比较
func normalizeVersion(v string) string {
	return strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, v)
}

// hasDifferentRelease: 与线上 release tag 不一致 (不一致即提示, 按需求约定)
func hasDifferentRelease(latest string) bool {
	cur := normalizeVersion(Version)
	lat := normalizeVersion(latest)
	if cur == "" || lat == "" {
		return false
	}
	c, err1 := strconv.ParseInt(cur, 10, 64)
	l, err2 := strconv.ParseInt(lat, 10, 64)
	if err1 != nil || err2 != nil {
		return cur != lat
	}
	return c != l
}

func main() {
	// 同步给 ui 包: 每个界面的版本显示
	ui.AppVersion = Version

	// 后台检查 GitHub 最新 release (失败静默); 语言选择界面也要显示提示, 默认英语
	updateCh := make(chan string, 1)
	go func() { updateCh <- fetchLatestReleaseTag() }()
	var latestTag string
	select {
	case latestTag = <-updateCh:
	case <-time.After(2 * time.Second):
	}
	updateAvailable := latestTag != "" && hasDifferentRelease(latestTag)
	if updateAvailable {
		ui.UpdateHint = "⚠ New version available: v" + latestTag // 语言选择界面: 默认英语
	}

	exePath, err := os.Executable()
	if err != nil {
		fmt.Printf("Failed to get executable directory: %v\n", err)
		return
	}
	baseDir := filepath.Dir(exePath)

	lang, err := ui.SelectMenuLanguage()
	if err != nil {
		fmt.Println("Language selection error:", err)
		return
	}

	// 提示本地化 (选完语言后)
	txt := "New version available"
	if updateAvailable {
		txt = lang.Common.UpdateAvailable
		if txt == "" {
			txt = "New version available"
		}
		ui.UpdateHint = "⚠ " + txt + ": v" + latestTag
	}

	ui.ClearScreen()
	// 一次性弹窗横幅: 必须在 ClearScreen 之后打印, 否则会被立即清屏抹掉
	if updateAvailable {
		ui.Println("")
		ui.Println(ui.ColorWrap("⚠ "+txt+": v"+latestTag, ui.StyleBoldRed))
		ui.Println(ui.ColorWrap("  "+ui.UpdateURL, ui.StyleDim))
	}
	ui.Println(ui.ColorWrap(lang.Title, ui.StyleBoldGreen))
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Menu1.Welcome, ui.StyleBoldGreen))
	ui.Println(ui.ColorWrap(lang.Menu1.NoteInfo1, ui.StyleBlue))
	ui.Println(ui.ColorWrap(lang.Menu1.NoteInfo2, ui.StyleCyan))
	ui.Println(ui.ColorWrap(lang.Menu1.NoteInfo3, ui.StyleBoldRed))
	ui.Println("")
	ui.Println(ui.ColorWrap(lang.Menu1.BeforeSelectingConsole, ui.StyleBoldCyan))
	ui.Println(ui.ColorWrap(lang.Menu1.SubInfo, ui.StyleBlue))
	ui.Println(ui.ColorWrap(lang.Menu1.Continue1, ui.StyleCyan))
	ui.Println(ui.ColorWrap("-----------------------------------------", ui.StyleDim))

	ui.Print(ui.ColorWrap(lang.Menu1.Continue2, ui.StyleBold))
	ui.Print(ui.ColorWrap("q", ui.StyleRed))
	ui.Print(ui.ColorWrap(lang.Common.Exit, ui.StyleBold))
	line, _ := ui.Prompt("")
	if line != "" && line[0] == 'q' {
		ui.Println("")
		ui.Println(ui.ColorWrap(lang.Menu1.CancelledBye, ui.StyleGreen))
		os.Exit(0)
	}

	selected, err := ui.ShowMenu(lang)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	if selected == nil {
		ui.Println(ui.ColorWrap(lang.Common.GoodBye, ui.StyleGreen))
		return
	}

	if err := ops.CleanTargetDirectory(lang, baseDir); err != nil {
		fmt.Printf("Error cleaning directory: %v\n", err)
		return
	}

	if err := ops.CopySelectedConsole(lang, selected, baseDir); err != nil {
		fmt.Printf("Error copying files: %v\n", err)
		return
	}

	ops.ShowSuccessFancy(lang, selected.DisplayName)

	if lang.Variant == "cn" || lang.Variant == "ko" {
		f, err := os.Create(filepath.Join(baseDir, "."+string(lang.Variant)))
		if err != nil {
			fmt.Printf("Error creating language file: %v\n", err)
			return
		}
		f.Close()
		ui.Println(ui.ColorWrap(lang.Menu4.TagFileCreated, ui.StyleCyan))
	}

	ui.Println(ui.ColorWrap(lang.Menu4.OperationComplete+string(lang.Variant), ui.StyleGreen))
}
