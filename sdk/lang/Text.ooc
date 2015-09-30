Text: cover {
	_buffer: CString
	_count: Int
	count ::= this _count
	init: func@ {}
	init: func@ ~fromStringLiteral (string: CString) {
		this init(string, strlen(string))
	}
	init: func@ ~fromStringLiteralWithCount (string: CString, =_count) {}

}
makeTextLiteral: func (str: CString, strLen: Int) -> Text {
    Text new(str, strLen)
}
