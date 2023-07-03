; extends

(call
  (attribute
    object: (identifier) @_path (#eq? @_path "migrations")
    attribute: (identifier) @_name (#eq? @_name "RunSQL"))
  (argument_list
    (string
      (string_content) @sql
      )
    )
  )
