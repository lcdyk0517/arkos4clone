package ui

import (
	"fmt"
	"strings"

	"arkos4clone/dtbtools/internal/console"
	"arkos4clone/dtbtools/internal/i18n"
)

const searchEntry = "__search__"

// NormalizeKeyword removes spaces and common separators for matching.
func NormalizeKeyword(s string) string {
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

// MatchField checks if a normalized field matches a normalized query.
func MatchField(normField, normQuery string) bool {
	if normField == "" {
		return false
	}
	if strings.Contains(normField, normQuery) {
		return true
	}
	return strings.HasPrefix(normQuery, normField)
}

// ConsoleMatchesKeyword checks if a console config matches the normalized query.
func ConsoleMatchesKeyword(c *console.ConsoleConfig, normQuery string) bool {
	if normQuery == "" {
		return false
	}
	if MatchField(NormalizeKeyword(c.RealName), normQuery) {
		return true
	}
	for _, entry := range c.BrandEntries {
		if MatchField(NormalizeKeyword(entry.Brand), normQuery) ||
			MatchField(NormalizeKeyword(entry.DisplayName), normQuery) {
			return true
		}
	}
	for _, kw := range c.Keywords {
		if MatchField(NormalizeKeyword(kw), normQuery) {
			return true
		}
	}
	return false
}

// BrandConsoleCount returns how many consoles belong to a brand.
func BrandConsoleCount(brand string) int {
	count := 0
	for i := range console.Consoles {
		for _, entry := range console.Consoles[i].BrandEntries {
			if entry.Brand == brand {
				count++
			}
		}
	}
	return count
}

// ConsoleOption represents a selectable console entry.
type ConsoleOption struct {
	Config      *console.ConsoleConfig
	Brand       string
	DisplayName string
}

// BuildBrandOptions returns all console options for a given brand.
func BuildBrandOptions(brand string) []ConsoleOption {
	var options []ConsoleOption
	for i := range console.Consoles {
		consoleItem := &console.Consoles[i]
		for _, entry := range consoleItem.BrandEntries {
			if entry.Brand == brand {
				options = append(options, ConsoleOption{
					Config:      consoleItem,
					Brand:       entry.Brand,
					DisplayName: entry.DisplayName,
				})
			}
		}
	}
	return options
}

// PickConsoleOption prints options and returns the selected one.
func PickConsoleOption(lang *i18n.Language, options []ConsoleOption, showBrand bool) (*ConsoleOption, error) {
	for i, opt := range options {
		if showBrand {
			Printf("  %2d. %s%s\n", i+1, ColorWrap("["+opt.Brand+"] ", StyleBlue), opt.DisplayName)
		} else {
			Printf("  %2d. %s\n", i+1, opt.DisplayName)
		}
	}
	Printf("  %2d. %s\n", 0, lang.Common.Back)

	for {
		choice, err := ReadIntChoice(lang, lang.Common.SelectNumber)
		if err != nil {
			return nil, err
		}
		if choice == 0 {
			return nil, nil
		}
		if choice > 0 && choice <= len(options) {
			selected := options[choice-1]
			Printf("Selected: %s\n", selected.DisplayName)
			return &selected, nil
		}
		Println(ColorWrap(lang.Common.InvalidSelection, StyleRed))
	}
}

// SelectBrand renders the brand selection menu.
func SelectBrand(lang *i18n.Language) (string, error) {
	ClearScreen()
	Print("\n")
	BoxHeader(lang.Menu2.PleaseSelectBrand)
	for i, brand := range console.Brands {
		Printf("  %2d. %-18s (%d)\n", i+1, brand, BrandConsoleCount(brand))
	}
	Printf("  %2d. %s\n", len(console.Brands)+1, ColorWrap(lang.Menu2.SearchOption, StyleCyan))
	Printf("  %2d. %s\n", 0, lang.Common.Exit)
	Print("\n")
	Println(ColorWrap(lang.Menu2.SearchHint, StyleCyan))

	searchChoice := len(console.Brands) + 1
	for {
		choice, err := ReadIntChoice(lang, lang.Common.SelectNumber)
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
			return console.Brands[choice-1], nil
		}
		Println(ColorWrap(lang.Common.InvalidSelection, StyleRed))
	}
}

// SearchConsoles renders the keyword search UI.
func SearchConsoles(lang *i18n.Language) (*ConsoleOption, error) {
	for {
		ClearScreen()
		Print("\n")
		BoxHeader(lang.Menu2.SearchOption)

		query, err := Prompt(lang.Menu2.SearchPrompt)
		if err != nil {
			return nil, err
		}
		normQuery := NormalizeKeyword(query)
		if normQuery == "" {
			return nil, nil
		}

		var options []ConsoleOption
		for i := range console.Consoles {
			consoleItem := &console.Consoles[i]
			if !ConsoleMatchesKeyword(consoleItem, normQuery) {
				continue
			}
			for _, entry := range consoleItem.BrandEntries {
				options = append(options, ConsoleOption{
					Config:      consoleItem,
					Brand:       entry.Brand,
					DisplayName: entry.DisplayName,
				})
			}
		}

		Print("\n")
		Println(ColorWrap(fmt.Sprintf(lang.Menu2.SearchResultsFmt, strings.TrimSpace(query)), StyleBoldGreen))
		if len(options) == 0 {
			Println(ColorWrap(lang.Menu2.SearchNoResults, StyleRed))
			WaitEnter(lang.Common.PressEnterToContinue)
			continue
		}

		opt, err := PickConsoleOption(lang, options, true)
		if err != nil {
			return nil, err
		}
		if opt == nil {
			return nil, nil
		}
		return opt, nil
	}
}

// SelectConsole renders the console list for a selected brand.
func SelectConsole(lang *i18n.Language, brand string) (*ConsoleOption, error) {
	ClearScreen()
	Print("\n")
	BoxHeader(lang.Menu3.AvailableConsolesFor + brand)

	if brand == "Clone R36s" && lang.Menu3.CloneR36sNote != "" {
		Print("\n")
		Println(ColorWrap("┌────────────────────────────────────────┐", StyleCyan))
		for _, line := range strings.Split(lang.Menu3.CloneR36sNote, "\n") {
			Println(ColorWrap("│ "+line, StyleCyan))
		}
		Println(ColorWrap("└────────────────────────────────────────┘", StyleCyan))
		Print("\n")
	}

	options := BuildBrandOptions(brand)
	if len(options) == 0 {
		Println(ColorWrap(lang.Menu3.NoConsolesFound, StyleRed))
		WaitEnter(lang.Common.PressEnterToContinue)
		return nil, nil
	}

	opt, err := PickConsoleOption(lang, options, false)
	if err != nil {
		return nil, err
	}
	if opt == nil {
		return nil, nil
	}
	return opt, nil
}

// ShowMenu runs the main brand/search/console selection loop.
func ShowMenu(lang *i18n.Language) (*ConsoleOption, error) {
	for {
		brand, err := SelectBrand(lang)
		if err != nil {
			return nil, err
		}
		if brand == "" {
			return nil, nil
		}
		if brand == searchEntry {
			selected, err := SearchConsoles(lang)
			if err != nil || selected != nil {
				return selected, err
			}
			continue
		}
		selected, err := SelectConsole(lang, brand)
		if err != nil {
			return nil, err
		}
		if selected != nil {
			return selected, nil
		}
	}
}

// SelectedConsole wraps the user's selection.
type SelectedConsole struct {
	Config      *console.ConsoleConfig
	DisplayName string
}
