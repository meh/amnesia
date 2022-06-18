[
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    deftable: :*
    defhook: :*
  ],
  export: [
    locals_without_parens: [
      deftable: :*
      defhook: :*
    ]
  ]
]
