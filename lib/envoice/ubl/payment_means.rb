module Envoice
  module Ubl
    class PaymentMeans

      attr_accessor :account_name, :iban, :bic, :payment_reference, :peppol_code, :peppol_name

      def initialize(account_name:, iban:, bic:, payment_reference:, peppol_code: nil, peppol_name: nil)
        @account_name = account_name
        @iban = iban
        @bic = bic

        @payment_reference = payment_reference

        @peppol_code = peppol_code || 31
        @peppol_name = peppol_name || 'Debit transfer'
      end

    end
  end
end