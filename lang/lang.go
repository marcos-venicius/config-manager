package lang

import (
	"fmt"
	"os"
)

type location_t struct {
	line, column int
}

type token_kind_t int

type token_t struct {
	kind     token_kind_t
	content  string
	location location_t
}

type lexer_t struct {
	content                string
	content_start_offset   int
	content_current_offset int
	location               location_t
	location_stack         []location_t
	tokens                 []token_t
}

const (
	token_kind_string token_kind_t = iota
	token_kind_symbol
	token_kind_at
	token_kind_code_block
	token_kind_left_bracket
	token_kind_right_bracket
	token_kind_left_square
	token_kind_right_square
	token_kind_colon
	token_kind_comma
	token_kind_new_line
)

func isLetter(c byte) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

func createLexer(content string) lexer_t {
	return lexer_t{
		content:                content,
		content_start_offset:   0,
		content_current_offset: 0,
		location: location_t{
			line:   1,
			column: 1,
		},
		location_stack: make([]location_t, 0),
		tokens:         make([]token_t, 0),
	}
}

func (k token_kind_t) String() string {
	switch k {
	case token_kind_string:
		return "token_kind_string"
	case token_kind_symbol:
		return "token_kind_symbol"
	case token_kind_at:
		return "token_kind_at"
	case token_kind_code_block:
		return "token_kind_code_block"
	case token_kind_left_bracket:
		return "token_kind_left_bracket"
	case token_kind_right_bracket:
		return "token_kind_right_bracket"
	case token_kind_left_square:
		return "token_kind_left_square"
	case token_kind_right_square:
		return "token_kind_right_square"
	case token_kind_colon:
		return "token_kind_colon"
	case token_kind_comma:
		return "token_kind_comma"
	case token_kind_new_line:
		return "token_kind_new_line"
	default:
		panic(fmt.Sprintf("unhandled token kind %d", k))
	}
}

func (l lexer_t) error(message string) {
	fmt.Printf("error %d:%d: %s\n", l.location.line, l.location.column, message)
	os.Exit(1)
}

func (l lexer_t) isEmpty() bool {
	return l.content_current_offset >= len(l.content)
}

func (l *lexer_t) chr() byte {
	if !l.isEmpty() {
		return l.content[l.content_current_offset]
	}

	return '0'
}

func (l *lexer_t) forward() {
	if !l.isEmpty() {
		if l.content[l.content_current_offset] == '\n' {
			l.location.line += 1
			l.location.column = 1
		} else {
			l.location.column += 1
		}

		l.content_current_offset += 1
	}
}

func (l lexer_t) lookFar(offset int) byte {
	idx := l.content_current_offset + offset

	if idx >= len(l.content) {
		return '0'
	}

	return l.content[idx]
}

func (l *lexer_t) setContentStartOffset() {
	l.content_start_offset = l.content_current_offset
}

func (l *lexer_t) stackLocation() {
	l.location_stack = append(l.location_stack, location_t{
		line:   l.location.line,
		column: l.location.column,
	})
}

func (l *lexer_t) popLocation() location_t {
	if len(l.location_stack) == 0 {
		panic("there is nothing on location's stack")
	}

	idx := len(l.location_stack) - 1

	location := l.location_stack[idx]

	l.location_stack = l.location_stack[:idx]

	return location
}

func (l *lexer_t) appendToken(kind token_kind_t) {
	content := l.content[l.content_start_offset:l.content_current_offset]
	location := l.popLocation()

	token := token_t{
		kind:     kind,
		content:  content,
		location: location,
	}

	l.tokens = append(l.tokens, token)
}

func (l *lexer_t) trimWhitespace() {
	for !l.isEmpty() && l.chr() == ' ' || l.chr() == '\t' {
		l.forward()
	}
}

func (l *lexer_t) lexSymbol() {
	for !l.isEmpty() && isLetter(l.chr()) {
		l.forward()
	}

	l.appendToken(token_kind_symbol)
}

func (l *lexer_t) lexSingleToken(kind token_kind_t) {
	l.forward()

	l.appendToken(kind)
}

func (l *lexer_t) lexString() {
	l.forward()
	l.setContentStartOffset()

	for !l.isEmpty() && l.chr() != '"' {
		l.forward()
	}

	if l.isEmpty() {
		l.error("unclosed string")
	}

	l.appendToken(token_kind_string)
	l.forward()
}

func (l *lexer_t) lexCodeBlock() {
	l.forward()

	expected_start_tokens := []byte{'<', '<', '{'}
	expected_end_tokens := []byte{'>', '>', '}'}

	for _, b := range expected_start_tokens {
		if l.isEmpty() {
			l.error(fmt.Sprintf("expected '%c' but got EOF", b))
		}

		if l.chr() != b {
			l.error(fmt.Sprintf("expected '%c' but got '%c'", b, l.chr()))
		}

		l.forward()
	}

	l.setContentStartOffset()

	for !l.isEmpty() {
		for offset, b := range expected_end_tokens {
			if l.isEmpty() {
				l.error(fmt.Sprintf("expected '%c' but got EOF", b))
			}

			if l.lookFar(offset) != b {
				goto not_found_end_code_block
			}
		}

		l.appendToken(token_kind_code_block)

		for range len(expected_end_tokens) {
			l.forward()
		}

		return

	not_found_end_code_block:
		l.forward()
	}

	if l.isEmpty() {
		l.error("expected '<<}' but got EOF")
	} else {
		l.error(fmt.Sprintf("expected '<<}' but got '%c'", l.chr()))
	}
}

func (l *lexer_t) run() []token_t {
	for !l.isEmpty() {
		l.trimWhitespace()
		l.setContentStartOffset()

		c := l.chr()

		l.stackLocation()

		switch {
		case isLetter(c):
			l.lexSymbol()
		case c == '"':
			l.lexString()
		case c == '@':
			l.lexSingleToken(token_kind_at)
		case c == '{':
			l.lexSingleToken(token_kind_left_bracket)
		case c == '}':
			l.lexSingleToken(token_kind_right_bracket)
		case c == '\n':
			l.lexSingleToken(token_kind_new_line)
		case c == ':':
			l.lexSingleToken(token_kind_colon)
		case c == '[':
			l.lexSingleToken(token_kind_left_square)
		case c == ']':
			l.lexSingleToken(token_kind_right_square)
		case c == '!':
			l.lexCodeBlock()
		default:
			println("unhandled case")
			goto end
		}
	}

end:
	return l.tokens
}

func Run(content string) {
	lexer := createLexer(content)

	tokens := lexer.run()

	for _, token := range tokens {
		fmt.Printf("kind: %+v\n", token.kind)
		if token.kind == token_kind_new_line {
			fmt.Println("content: \033[0;32m\\n\033[0m")
		} else {
			fmt.Printf("content: |\033[0;32m%+v\033[0m|\n", token.content)
		}
		fmt.Printf("location: %+v\n", token.location)
		fmt.Println()
	}
}
