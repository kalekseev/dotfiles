; extends

(call
  (attribute
    object: (identifier) @_path (#eq? @_path "migrations")
    attribute: (identifier) @_name (#eq? @_name "RunSQL"))
  (argument_list
    (string
      (string_content) @injection.content
      )
    )
    (#set! injection.language "sql")
  )

;(call
;  (attribute
;    object: (identifier) @_path (#eq? @_path "cursor")
;    attribute: (identifier) @_name (#eq? @_name "execute"))
;  (argument_list
;    (string
;      (string_content) @injection.content
;      )
;    )
;    (#set! injection.language "sql")
;  )
