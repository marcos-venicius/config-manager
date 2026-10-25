package lang

import "fmt"

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
