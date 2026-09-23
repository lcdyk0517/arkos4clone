package main

import (
	"fmt"
	"os"
	"path/filepath"

	"arkos4clone/dtbtools/internal/ui"
	"arkos4clone/dtbtools/internal/ops"
)

func main() {
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

	ui.ClearScreen()
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
