; extends

(application_expression
  (long_identifier_or_op (identifier) @_name (#eq? @_name "sql"))
  (const (triple_quoted_string) @injection.content (#offset! @injection.content 0 3 0 -3))
  (#set! injection.language "sql")
  )

(application_expression
  (long_identifier_or_op (identifier) @_name (#eq? @_name "sql"))
  (const (string) @injection.content (#offset! @injection.content 0 1 0 -1))
  (#set! injection.language "sql")
  )
