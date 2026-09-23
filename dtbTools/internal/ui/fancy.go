package ui

import "strings"

// ASCIILogoLCDYK returns the ASCII art logo lines.
func ASCIILogoLCDYK() []string {
	return []string{
		`  _     ____ ______   ___  __`,
		` | |   / ___|  _ \ \ / / |/ / `,
		` | |  | |   | | | \ V /| ' /   `,
		` | |__| |___| |_| || | | . \  `,
		` |_____\____|____/ |_| |_|\_\ `,
	}
}

// FancyHeader prints the ASCII logo and title.
func FancyHeader(title string) {
	ClearScreen()
	Println(ColorWrap(strings.Repeat("=", 64), StyleCyan))
	for _, ln := range ASCIILogoLCDYK() {
		Println(ColorWrap(" "+ln, StyleBlue))
	}
	Println(ColorWrap(" "+title, StyleBoldGreen))
	Println(ColorWrap(strings.Repeat("=", 64), StyleCyan))
	Print("")
}
