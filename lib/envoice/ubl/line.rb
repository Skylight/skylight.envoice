# frozen_string_literal: true
module Envoice
  module Ubl
    class Line

      attr_reader :id, :name, :quantity, :unit, :unit_price, :currency, :tax_rate, :description, :classified_tax_category

      def initialize(id:, name:, quantity:, unit_price:, currency:, tax_rate:, classified_tax_category:, description: nil, unit: nil)
        @id = id
        @name = name
        @quantity = quantity
        @unit_price = unit_price
        @currency = currency
        @tax_rate = tax_rate
        @classified_tax_category = classified_tax_category
        @description = description
        @unit = unit
      end

      def line_extension_amount
        @line_extension_amount ||= (@quantity * @unit_price).round(2)
      end

      def tax_amount
        @tax_amount ||= (self.line_extension_amount * (@tax_rate / 100.0)).round(2)
      end

    end
  end
end