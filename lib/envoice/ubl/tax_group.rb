module Envoice
  module Ubl
    class TaxGroup

      attr_accessor :tax_rate, :classified_tax_category, :tax_exemption_reason, :total_vat_amount, :total_amount_without_vat

      def initialize(tax_rate:, classified_tax_category:, tax_exemption_reason:, total_vat_amount:, total_amount_without_vat:)
        @tax_rate = tax_rate
        @classified_tax_category = classified_tax_category
        @tax_exemption_reason = tax_exemption_reason
        @total_vat_amount = total_vat_amount
        @total_amount_without_vat = total_amount_without_vat
      end

    end
  end
end