defmodule DunderMifflinBot.Payments.WebhookHandler do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/webhooks/abacatepay" do
    secret = Application.get_env(:dunder_mifflin_bot, :webhook_secret)

    with sig when is_binary(sig) <- get_req_header(conn, "x-abacatepay-signature") |> List.first(),
         true <- valid_signature?(conn.body_params, sig, secret) do
      %Oban.Job{} =
        %{"billing_id" => conn.body_params["billing"]["id"]}
        |> DunderMifflinBot.Workers.PaymentWorker.new()
        |> Oban.insert!()

      send_resp(conn, 200, Jason.encode!(%{ok: true}))
    else
      _ -> send_resp(conn, 401, Jason.encode!(%{error: "invalid signature"}))
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp valid_signature?(_body, _sig, nil), do: true

  defp valid_signature?(body, sig, secret) do
    expected = :crypto.mac(:hmac, :sha256, secret, Jason.encode!(body)) |> Base.encode16(case: :lower)
    Plug.Crypto.secure_compare(expected, sig)
  end
end
