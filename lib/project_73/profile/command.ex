defmodule Project73.Profile.Command do
  alias Project73.Profile.Command.Create
  alias Project73.Profile.Command
  use Project73.Utils.ValidatedStruct

  @type t() ::
          Command.Create.t()
          | Command.UpdatePaymentAccount.t()
          | Command.RequestDeposit.t()
          | Command.Update.t()

  validated_struct Create do
    field :id, :string, not_empty: true
    field :provider, :string, not_empty: true
    field :email, :string, not_empty: true
  end

  validated_struct UpdatePaymentAccount do
    field :payment_account_id, :string, not_empty: true
  end

  validated_struct RequestDeposit do
    field :amount, :decimal, gt: 0
  end

  validated_struct Update do
    field :username, :string, not_empty: true
    field :first_name, :string, not_empty: true
    field :last_name, :string, not_empty: true
    field :address, Project73.Shared.Address.t(), dive: true
  end

  def validate(%Command.Create{} = cmd), do: Command.Create.validate(cmd)

  def validate(%Command.UpdatePaymentAccount{} = cmd),
    do: Command.UpdatePaymentAccount.validate(cmd)

  def validate(%Command.RequestDeposit{} = cmd), do: Command.RequestDeposit.validate(cmd)
  def validate(%Command.Update{} = cmd), do: Command.Update.validate(cmd)
end
