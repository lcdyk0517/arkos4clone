package ui

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"

	"arkos4clone/dtbtools/internal/i18n"
)

// TerminalReader reads user input from stdin.
var TerminalReader = bufio.NewReader(os.Stdin)

// ANSI color codes.
const (
	ANSIReset   = "\033[0m"
	ANSIRed     = "\033[31m"
	ANSIDeepRed = "\033[38;5;196m"
	ANSIGreen   = "\033[32m"
	ANSIBlue    = "\033[34m"
	ANSICyan    = "\033[36m"
	ANSIBold    = "\033[1m"
)

// Style represents a combined ANSI style.
type Style string

const (
	StyleBold      Style = ANSIBold
	StyleRed       Style = ANSIRed
	StyleDeepRed   Style = ANSIDeepRed
	StyleBoldDeepRed Style = ANSIBold + ANSIDeepRed
	StyleGreen     Style = ANSIGreen
	StyleBlue      Style = ANSIBlue
	StyleCyan      Style = ANSICyan
	StyleBoldRed   Style = ANSIBold + ANSIRed
	StyleBoldGreen Style = ANSIBold + ANSIGreen
	StyleBoldBlue  Style = ANSIBold + ANSIBlue
	StyleBoldCyan  Style = ANSIBold + ANSICyan
	StyleDim       Style = ""
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

// ColorWrap applies ANSI color if supported.
func ColorWrap(s string, style Style) string {
	if style == "" || !supportsANSI() {
		return s
	}
	return string(style) + s + ANSIReset
}

// Println prints a line.
func Println(s string) {
	fmt.Println(s)
}

// Printf prints formatted text.
func Printf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

// Print prints text without newline.
func Print(s string) {
	fmt.Print(s)
}

// ClearScreen clears the terminal screen.
func ClearScreen() {
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

func isTerminal() bool {
	info, err := os.Stdin.Stat()
	if err != nil {
		return false
	}
	return (info.Mode() & os.ModeCharDevice) != 0
}

// Prompt displays a message and reads user input.
func Prompt(msg string) (string, error) {
	if !isTerminal() {
		return "", errors.New("non-interactive stdin")
	}
	Print(msg)
	line, err := TerminalReader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(line), nil
}

// ReadIntChoice repeatedly prompts until a valid integer is entered.
func ReadIntChoice(lang *i18n.Language, msg string) (int, error) {
	for {
		resp, err := Prompt(msg)
		if err != nil {
			return -1, err
		}
		n, err := strconv.Atoi(resp)
		if err != nil {
			Println(ColorWrap(lang.Common.PleaseEnterNumber, StyleBoldRed))
			continue
		}
		return n, nil
	}
}

// BoxHeader renders a header inside a cyan box.
func BoxHeader(title string) {
	Println(ColorWrap("┌────────────────────────────────────────┐", StyleCyan))
	Println(ColorWrap("│ "+title, StyleBoldGreen))
	Println(ColorWrap("└────────────────────────────────────────┘", StyleCyan))
}

// WaitEnter waits for the user to press Enter.
func WaitEnter(msg string) {
	_, _ = Prompt(msg)
}

// SelectMenuLanguage renders the language selection menu.
func SelectMenuLanguage() (*i18n.Language, error) {
	ClearScreen()

	Println("====================================================")
	Println(" - Select the language you want to use for the menu")
	Println(" - 请选择菜单所使用的语言")
	Println(" - 메뉴에 사용할 언어를 선택하세요")
	Println("")
	Println("1. English")
	Println("2. 中文")
	Println("3. 한국어")
	Println("4. Português (BR)")
	Println("5. Deutsch")
	Println("6. Ελληνικά")
	Println("7. Español")
	Println("8. Français")
	Println("9. 日本語")
	Println("10. Polski")
	Println("11. Português")
	Println("12. Русский")
	Println("13. Svenska")
	Println("14. Tiếng Việt")
	Println("15. 繁體中文")
	Println("====================================================")

	for {
		resp, err := Prompt("Select number: ")
		if err != nil {
			return nil, err
		}
		switch strings.TrimSpace(resp) {
		case "", "1":
			return &i18n.English, nil
		case "2":
			return &i18n.Chinese, nil
		case "3":
			return &i18n.Korean, nil
		case "4":
			return &i18n.BrazilianPortuguese, nil
		case "5":
			return &i18n.German, nil
		case "6":
			return &i18n.Greek, nil
		case "7":
			return &i18n.Spanish, nil
		case "8":
			return &i18n.French, nil
		case "9":
			return &i18n.Japanese, nil
		case "10":
			return &i18n.Polish, nil
		case "11":
			return &i18n.Portuguese, nil
		case "12":
			return &i18n.Russian, nil
		case "13":
			return &i18n.Swedish, nil
		case "14":
			return &i18n.Vietnamese, nil
		case "15":
			return &i18n.ChineseTraditional, nil
		default:
			Println("Invalid selection.")
		}
	}
}
