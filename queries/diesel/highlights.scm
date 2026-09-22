; Keywords
[
  "patch"
  "macro"
  "sample"
  "data"
] @keyword

; Node declarations: `Sine osc1 { ... }`
(node type: (identifier) @type)
(node type: (string) @type)
(node name: (identifier) @variable.parameter)

; `from.port -> to.port`
(port_ref node: (identifier) @variable.parameter)
(port_ref port: (identifier) @property)
(port_ref port: (string) @property)

; `x = 120;`, `.cutoff = 800;`, `{ kind = "factory" }`
(field key: (identifier) @property)
(field key: (string) @property)
(port_value port: (identifier) @property)
(port_value port: (string) @property)
(pair key: (identifier) @property)
(pair key: (string) @property)

(macro name: (string) @string.special)
(macro target: (identifier) @variable.parameter)

(patch name: (string) @string.special)

(number) @number
(string) @string
(blob) @string.special
(boolean) @constant.builtin
(comment) @comment @spell

[ "->" "=" ] @operator
[ "{" "}" "(" ")" "[" "]" ] @punctuation.bracket
[ ";" "," "." ] @punctuation.delimiter
