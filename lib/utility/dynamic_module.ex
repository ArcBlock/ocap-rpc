defmodule UtilityBelt.CodeGen.DynamicModule do
  @moduledoc """
  Generate a new module based on AST
  """
  defmacro gen(mod_name, preamble, contents, opts \\ []) do
    quote bind_quoted: [
            mod_name: mod_name,
            preamble: preamble,
            contents: contents,
            opts: opts
          ] do
      mod_doc = Access.get(opts, :doc, false)
      path = Access.get(opts, :path, "")
      create? = Access.get(opts, :create, true)

      moduledoc =
        quote do
          @moduledoc unquote(mod_doc)
        end

      name = String.to_atom("Elixir.#{mod_name}")

      case create? do
        false ->
          nil

        _ ->
          Module.create(
            name,
            [moduledoc] ++ [preamble] ++ [contents],
            Macro.Env.location(__ENV__)
          )
      end

      case File.mkdir_p(path) do
        {:error, :enoent} ->
          IO.puts("Module #{mod_name} is generated.")

        _ ->
          filename = Path.join(path, "#{mod_name}.ex")

          term =
            case is_list(contents) do
              true ->
                quote do
                  defmodule unquote(name) do
                    unquote(moduledoc)
                    unquote(preamble)
                    unquote_splicing(contents)
                  end
                end

              _ ->
                quote do
                  defmodule unquote(name) do
                    unquote(moduledoc)
                    unquote(preamble)
                    unquote(contents)
                  end
                end
            end

          term =
            term
            |> Macro.to_string()
            |> String.replace(~r/(\(\s|\s\))/, "")
            # |> String.replace(~r/\(([^)(]+)\)/, " \\1")
            |> String.replace(~r/def([^(]*)\((.*?)\) do/, "def\\1 \\2 do")
            |> String.replace(~r/create([^(]*)\((.*?)\) do/, "create\\1 \\2 do")

          File.write!(filename, term)
          IO.puts("Module #{mod_name} is generated and file gets created at #{filename}.")
      end
    end
  end

  def gen_module_name(app, prefix, name, postfix \\ "") do
    app_name = app |> Atom.to_string() |> Recase.to_pascal()
    name = name |> Recase.to_pascal()

    case postfix do
      "" -> "#{app_name}.#{prefix}.#{name}"
      _ -> "#{app_name}.#{prefix}.#{name}.#{postfix}"
    end
  end

  def normalize_name(nil), do: nil
  def normalize_name(name) when is_atom(name), do: name
  def normalize_name(name), do: String.to_atom(name)
end
