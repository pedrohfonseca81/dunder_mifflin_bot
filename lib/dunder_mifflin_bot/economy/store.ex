defmodule DunderMifflinBot.Economy.Store do
  alias DunderMifflinBot.Payments.AbacatePay
  alias DunderMifflinBot.Economy.Wallet
  alias DunderMifflinBot.{Members, Servers}

  @sb_packs [
    %{id: "starter", name: "Starter", sb: 100, price_brl: 490, label: "100 SB — R$4,90"},
    %{id: "regular", name: "Regular", sb: 300, price_brl: 990, label: "300 SB — R$9,90"},
    %{id: "premium", name: "Premium", sb: 800, price_brl: 1990, label: "800 SB — R$19,90"},
    %{id: "regional_manager", name: "Regional Manager", sb: 2000, price_brl: 3990, label: "2000 SB — R$39,90"}
  ]

  @event_packs [
    %{id: "branch_budget", name: "Branch Budget", credits: 100, price_brl: 1490, label: "100 events — R$14,90"},
    %{id: "corporate_fund", name: "Corporate Fund", credits: 500, price_brl: 4990, label: "500 events — R$49,90"}
  ]

  @donation_options [
    %{amount_brl: 500, label: "☕ R$5,00 — A coffee for Michael"},
    %{amount_brl: 1000, label: "🥨 R$10,00 — A pretzel for Stanley"},
    %{amount_brl: 2500, label: "🎖️ R$25,00 — A golden Dundie"},
    %{amount_brl: 5000, label: "💼 R$50,00 — Dunder Mifflin investor"}
  ]

  def sb_packs, do: @sb_packs
  def event_packs, do: @event_packs
  def donation_options, do: @donation_options

  def get_sb_pack(id), do: Enum.find(@sb_packs, &(&1.id == id))
  def get_event_pack(id), do: Enum.find(@event_packs, &(&1.id == id))

  def create_sb_purchase(user_id, server_id, pack_id, customer) do
    pack = get_sb_pack(pack_id)

    if pack do
      metadata = %{
        type: "sb_purchase",
        user_id: to_string(user_id),
        server_id: to_string(server_id),
        pack_id: pack_id,
        sb_amount: pack.sb
      }

      AbacatePay.create_pix(pack.price_brl, "#{pack.name} — Schrute Bucks", customer, metadata)
    else
      {:error, :invalid_pack}
    end
  end

  def create_event_purchase(server_id, pack_id, customer) do
    pack = get_event_pack(pack_id)

    if pack do
      metadata = %{
        type: "event_purchase",
        server_id: to_string(server_id),
        pack_id: pack_id,
        credits: pack.credits
      }

      AbacatePay.create_pix(pack.price_brl, "#{pack.name} — Event Credits", customer, metadata)
    else
      {:error, :invalid_pack}
    end
  end

  def create_donation(amount_brl, user_id, server_id, customer) do
    metadata = %{
      type: "donation",
      user_id: to_string(user_id),
      server_id: to_string(server_id)
    }

    AbacatePay.create_pix(amount_brl, "Donation — Dunder Mifflin Bot", customer, metadata)
  end

  def fulfill_purchase(billing_id, metadata) do
    case metadata["type"] do
      "sb_purchase" ->
        user_id = String.to_integer(metadata["user_id"])
        server_id = String.to_integer(metadata["server_id"])
        sb = metadata["sb_amount"]
        Wallet.credit(user_id, server_id, sb, "purchase", billing_id: billing_id)

      "event_purchase" ->
        server_id = String.to_integer(metadata["server_id"])
        credits = metadata["credits"]
        Servers.add_event_credits(server_id, credits)

      "donation" ->
        user_id = String.to_integer(metadata["user_id"])
        server_id = String.to_integer(metadata["server_id"])
        Members.set_investor(user_id, server_id)

      _ ->
        {:error, :unknown_type}
    end
  end
end
