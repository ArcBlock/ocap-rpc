version = OcapRpc.MixProject.get_version()
otp_version = OcapRpc.MixProject.get_otp_version()

["rel", "plugins", "*.exs"]
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  default_release: :default,
  default_environment: Mix.env()

environment :dev do
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :arcblock)
end

environment :staging do
  set(include_erts: "/tmp/esl_otp_#{otp_version}/usr/lib/erlang")
  set(include_src: false)
  set(cookie: :"F!!O{%,rp]p1^}c44yFu6NVs^L0m5lB8?H!USeCkLx>(^DPBNPinYXU/l5!|@S5Q")
end

environment :prod do
  set(include_erts: "/tmp/esl_otp_#{otp_version}/usr/lib/erlang")
  set(include_src: false)
  set(cookie: :"&CKitUm*!T%K}XTR6tBo3A:Z/XcX5k<n7dNju?4%(Q/Umfn872[*kr}):b$%y*:d")
end

release :ocap_rpc do
  set(version: version)

  set(
    applications: [
      :runtime_tools,
      logger_sentry: :permanent,
      parse_trans: :permanent,
      recon: :permanent,
      recon_ex: :permanent,
      ocap_rpc: :permanent
    ]
  )
end
