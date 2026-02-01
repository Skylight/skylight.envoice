# frozen_string_literal: true

module Envoice
  module Ubl
    class Document
      TYPE_INVOICE = :invoice
      TYPE_CREDIT_NOTE = :credit_note

      attr_reader :type
      attr_accessor :id, :issue_date, :due_date, :currency, :tax_exemption_reason, :buyer_reference
      attr_reader :sender, :receiver

      attr_accessor :payment_means
      attr_accessor :payment_terms
      attr_reader :lines, :attachments

      def self.tax_rate_to_classified_tax_category(tax_rate, document)
        # https://docs.peppol.eu/poacc/billing/3.0/codelist/UNCL5305/

        return 'S' if tax_rate > 0.0

        (document.receiver.in_european_economic_area? && (document.receiver.country_iso2 != document.sender.country_iso2)) ? 'K' : 'E'
      end

      def self.tax_exemption_reason(classified_tax_category)
        return 'Intra-community supply - Services B2B' if classified_tax_category == 'K'

        nil
      end

      def initialize(type:, id:, issue_date:, due_date:, currency:, tax_exemption_reason: nil, buyer_reference: nil)
        @type = type
        @id = id
        @issue_date = issue_date
        @due_date = due_date
        @currency = currency
        @tax_exemption_reason = tax_exemption_reason
        @buyer_reference = buyer_reference
        @lines = []
        @attachments = []
      end

      def invoice?
        @type == TYPE_INVOICE
      end

      def credit_note?
        @type == TYPE_CREDIT_NOTE
      end

      def add_line(name:, quantity:, unit_price:, tax_rate:, description: nil, unit: 'ZZ', classified_tax_category: nil, line_extension_amount: nil, tax_amount: nil)
        classified_tax_category ||= self.class.tax_rate_to_classified_tax_category(tax_rate, self)
        @lines << Envoice::Ubl::Line.new(id: (lines.size + 1), name: name, quantity: quantity, unit_price: unit_price, currency: @currency, tax_rate: tax_rate, description: description, unit: unit, classified_tax_category: classified_tax_category, line_extension_amount: line_extension_amount, tax_amount: tax_amount)
      end

      def add_attachment(filename:, id:, description:, mime_type:, contents:, document_type_code: nil)
        @attachments << Envoice::Ubl::Attachment.new(filename: filename, id: id, description: description, mime_type: mime_type, contents: contents, document_type_code: document_type_code)
      end

      def add_attachment_from_file(absolute_file_name:, id:, description:, mime_type:, filename: nil, document_type_code: nil)
        raise "File does not exist: #{absolute_file_name}" unless File.exist?(absolute_file_name)

        filename ||= File.basename(absolute_file_name)
        @attachments << Envoice::Ubl::Attachment.new(filename: filename, id: id, description: description, mime_type: mime_type, contents: File.binread(absolute_file_name), document_type_code: document_type_code)
      end

      def sender=(value)
        raise "Sender is not a Party" unless value.instance_of?(Envoice::Ubl::Party)
        @sender = value
      end

      def receiver=(value)
        raise "Receiver is not a Party" unless value.instance_of?(Envoice::Ubl::Party)
        @receiver = value
      end

      def tax_groups
        raise "No lines on document" if @lines.none?

        @lines.group_by(&:tax_rate).map do |tax_rate, lines|
          classified_tax_categories = lines.map(&:classified_tax_category).uniq

          raise "Multiple tax categories `#{classified_tax_categories.inspect}`" if classified_tax_categories.size != 1

          classified_tax_category = classified_tax_categories.first
          tax_exemption_reason = self.tax_exemption_reason_for_tax_rate(tax_rate)
          total_vat_amount = lines.sum(&:tax_amount).round(2)
          total_amount_without_vat = lines.sum(&:line_extension_amount).round(2)

          Envoice::Ubl::TaxGroup.new(tax_rate: tax_rate, classified_tax_category: classified_tax_category, tax_exemption_reason: tax_exemption_reason, total_vat_amount: total_vat_amount, total_amount_without_vat: total_amount_without_vat)
        end.sort_by(&:tax_rate)
      end

      def tax_exemption_reason_for_tax_rate(tax_rate)
        return nil if tax_rate > 0.0

        raise "`tax_exemption_reason` is not defined for document" if self.tax_exemption_reason.to_s.empty?

        self.tax_exemption_reason
      end

      def total_without_vat
        @lines.sum(&:line_extension_amount).round(2)
      end

      def total_vat_amount
        @lines.sum(&:tax_amount).round(2)
      end

      def total_with_vat
        (total_without_vat + total_vat_amount).round(2)
      end

    end
  end
end