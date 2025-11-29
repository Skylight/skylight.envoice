# frozen_string_literal: true
module Envoice
  module Ubl
    class Generator
      def self.generate_ubl_invoice(document)
        raise "Document should be an instance of `Accounting::Ubl::Document`" unless document.instance_of?(Accounting::Ubl::Document)
        raise "Document should be an invoice" unless document.invoice?

        namespaces = {
          'xmlns' => 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
          'xmlns:cac' => 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
          'xmlns:cbc' => 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'
        }
        customization_id = 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0'
        profile_id = 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0'

        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.Invoice(namespaces) do
            xml['cbc'].CustomizationID customization_id
            xml['cbc'].ProfileID profile_id
            xml['cbc'].ID document.id
            xml['cbc'].IssueDate document.issue_date.strftime('%Y-%m-%d')
            xml['cbc'].DueDate document.due_date.strftime('%Y-%m-%d')
            xml['cbc'].InvoiceTypeCode 380
            xml['cbc'].DocumentCurrencyCode document.currency
            if document.buyer_reference.empty?
              xml["cac"].OrderReference do
                xml["cbc"].ID document.id
              end
            else
              xml['cbc'].BuyerReference document.buyer_reference
            end

            document.attachments.each do |attachment|
              self._build_attachments(xml, attachment)
            end

            xml['cac'].AccountingSupplierParty do |asp|
              self._build_party(asp, document.sender)
            end

            xml['cac'].AccountingCustomerParty do |acp|
              self._build_party(acp, document.receiver)
            end

            if document.payment_means.present?
              self._build_payment_means_for_note(xml, document.payment_means)
            end

            if document.payment_terms.present?
              xml['cac'].PaymentTerms do |pt|
                pt['cbc'].Note document.payment_terms
              end
            end

            self._build_tax_total_for_note(xml, document)

            self._build_legal_monetary_total(xml, document)

            self._build_invoice_lines(xml, document)
          end
        end.doc
      end

      def self.generate_ubl_credit_note(document)
        namespaces = {
          'xmlns' => 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2',
          'xmlns:cac' => 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
          'xmlns:cbc' => 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'
        }
        customization_id = 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0'
        profile_id = 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0'

        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.CreditNote(namespaces) do
            xml['cbc'].CustomizationID customization_id
            xml['cbc'].ProfileID profile_id
            xml['cbc'].ID document.id
            xml['cbc'].IssueDate document.issue_date.strftime('%Y-%m-%d')
            # xml['cbc'].DueDate document.expires.strftime('%Y-%m-%d') # not allowed in credit note!
            xml['cbc'].CreditNoteTypeCode 381
            xml['cbc'].DocumentCurrencyCode document.currency
            if document.buyer_reference.empty?
              xml["cac"].OrderReference do
                xml["cbc"].ID document.id
              end
            else
              xml['cbc'].BuyerReference document.buyer_reference
            end

            document.attachments.each do |attachment|
              self._build_attachments(xml, attachment)
            end

            xml['cac'].AccountingSupplierParty do |asp|
              self._build_party(asp, document.sender)
            end

            xml['cac'].AccountingCustomerParty do |acp|
              self._build_party(acp, document.receiver)
            end

            self._build_tax_total_for_note(xml, document)

            self._build_legal_monetary_total(xml, document)

            self._build_credit_note_lines(xml, document)
          end
        end.doc
      end

      private

      def self._build_attachments(xml, attachment)
        xml['cac'].AdditionalDocumentReference do
          xml['cbc'].ID attachment.id
          xml['cbc'].DocumentDescription attachment.description
          xml['cac'].Attachment do
            xml['cbc'].EmbeddedDocumentBinaryObject(mimeCode: attachment.mime_type, filename: File.basename(attachment.absolute_file_name)) { xml.text Base64.strict_encode64(File.binread(attachment.absolute_file_name)) }
          end
        end
      end

      def self._build_party(xml, party)
        xml['cac'].Party do |p|
          p['cbc'].EndpointID(party.peppol_endpoint_id, schemeID: party.peppol_endpoint_scheme_id)

          p['cac'].PartyName do |pn|
            pn['cbc'].Name party.name
          end

          p['cac'].PostalAddress do |pa|
            pa['cbc'].StreetName party.address_information
            pa['cbc'].AdditionalStreetName party.additional_address_information if party.additional_address_information.present?
            pa['cbc'].CityName party.city
            pa['cbc'].PostalZone party.zip_code

            pa['cac'].Country do |c|
              c['cbc'].IdentificationCode party.country_iso2
            end
          end

          p['cac'].PartyTaxScheme do |pts|
            pts['cbc'].CompanyID party.vat_number
            pts['cac'].TaxScheme do |ts|
              ts['cbc'].ID 'VAT'
            end
          end

          p['cac'].PartyLegalEntity do |partyLegalEntity|
            partyLegalEntity['cbc'].RegistrationName party.name
            partyLegalEntity['cbc'].CompanyID party.vat_number
          end
        end
      end

      def self._build_payment_means_for_note(xml, payment_means)
        xml['cac'].PaymentMeans do |pm|
          pm['cbc'].PaymentMeansCode(payment_means.peppol_code, name: payment_means.peppol_name)
          pm['cbc'].PaymentID payment_means.payment_reference

          pm['cac'].PayeeFinancialAccount do |pfa|
            pfa['cbc'].ID payment_means.iban
            pfa['cbc'].Name payment_means.account_name
            pfa['cac'].FinancialInstitutionBranch do |fib|
              fib['cbc'].ID payment_means.bic
            end
          end
        end
      end

      # https://docs.peppol.eu/poacc/billing/3.0/codelist/UNCL5305/
      def self._build_tax_total_for_note(xml, document)
        document.tax_groups.each do |tax_group|
          xml['cac'].TaxTotal do |tt|
            tt['cbc'].TaxAmount(tax_group.total_vat_amount, currencyID: document.currency)
            tt['cac'].TaxSubtotal do |tst|
              tst['cbc'].TaxableAmount(tax_group.total_amount_without_vat, currencyID: document.currency)
              tst['cbc'].TaxAmount(tax_group.total_vat_amount, currencyID: document.currency)
              tst['cac'].TaxCategory do |tc|
                tc['cbc'].ID tax_group.classified_tax_category
                tc['cbc'].Percent tax_group.tax_rate
                tc['cbc'].TaxExemptionReason tax_group.tax_exemption_reason if tax_group.tax_exemption_reason.present?
                tc['cac'].TaxScheme do |ts|
                  ts['cbc'].ID 'VAT'
                end
              end
            end
          end
        end
      end

      def self._build_legal_monetary_total(xml, document)
        xml['cac'].LegalMonetaryTotal do |lmt|
          lmt['cbc'].LineExtensionAmount(document.total_without_vat, currencyID: document.currency)
          lmt['cbc'].TaxExclusiveAmount(document.total_without_vat, currencyID: document.currency)
          lmt['cbc'].TaxInclusiveAmount(document.total_with_vat, currencyID: document.currency)
          lmt['cbc'].ChargeTotalAmount(0.0, currencyID: document.currency)
          lmt['cbc'].PayableAmount(document.total_with_vat, currencyID: document.currency)
        end
      end

      def self._build_invoice_lines(xml, document)
        document.lines.each do |line|
          xml['cac'].InvoiceLine do |il|
            il['cbc'].ID line.id
            il['cbc'].InvoicedQuantity(line.quantity, unitCode: line.unit)
            il['cbc'].LineExtensionAmount(line.line_extension_amount, currencyID: line.currency)
            il['cac'].Item do |i|
              i['cbc'].Description line.description if line.description.present?
              i['cbc'].Name line.name
              i['cac'].ClassifiedTaxCategory do |ctc|
                ctc['cbc'].ID line.classified_tax_category
                ctc['cbc'].Percent line.tax_rate
                ctc['cac'].TaxScheme do |tc|
                  tc['cbc'].ID 'VAT'
                end
              end
            end
            il['cac'].Price do |p|
              p['cbc'].PriceAmount(line.unit_price, currencyID: line.currency)
            end
          end
        end
      end

      def self._build_credit_note_lines(xml, document)
        document.lines.each do |line|
          xml['cac'].CreditNoteLine do |il|
            il['cbc'].ID line.id
            il['cbc'].CreditedQuantity(line.quantity, unitCode: line.unit)
            il['cbc'].LineExtensionAmount(line.line_extension_amount, currencyID: line.currency)
            il['cac'].Item do |i|
              i['cbc'].Description line.description if line.description.present?
              i['cbc'].Name line.name
              i['cac'].ClassifiedTaxCategory do |ctc|
                ctc['cbc'].ID line.classified_tax_category
                ctc['cbc'].Percent line.tax_rate
                ctc['cac'].TaxScheme do |tc|
                  tc['cbc'].ID 'VAT'
                end
              end
            end
            il['cac'].Price do |p|
              p['cbc'].PriceAmount(line.unit_price, currencyID: line.currency)
            end
          end
        end
      end

    end
  end
end