locals_without_parens = [
  defparsec: 2,
  defparsec: 3,
  defparsecp: 2,
  defparsecp: 3,
  defcombinator: 2,
  defcombinator: 3,
  defcombinatorp: 2,
  defcombinatorp: 3
]

[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
