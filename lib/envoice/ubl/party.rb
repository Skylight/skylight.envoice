module Envoice
  module Ubl
    class Party

      attr_accessor :peppol_endpoint_scheme_id, :peppol_endpoint_id, :name, :street, :number, :bus, :additional_address_information, :city, :zip_code, :country_iso2, :vat_number, :email

      def self.endpoint_scheme_id_for_country_with_iso2(country_iso2)
        # https://docs.peppol.eu/poacc/billing/3.0/codelist/eas/

        case country_iso2
        when Envoice::CountryCode::ISO_2_BE
          return 9925
        when Envoice::CountryCode::ISO_2_DE
          return 9930
        when Envoice::CountryCode::ISO_2_FR
          return 9957
        when Envoice::CountryCode::ISO_2_GB
          return 9932
        when Envoice::CountryCode::ISO_2_IE
          return 9935
        when Envoice::CountryCode::ISO_2_LU
          return 9938
        when Envoice::CountryCode::ISO_2_NL
          return 9944
        end

        raise "Unknown endpoint scheme for country with iso2 #{country_iso2}"
      end

      def initialize(name:, street:, number:, city:, zip_code:, country_iso2:, vat_number:, email:, bus: nil, additional_address_information: nil, peppol_endpoint_scheme_id: nil, peppol_endpoint_id: nil)
        @name = name

        @street = street
        @number = number
        @bus = bus
        @additional_address_information = additional_address_information

        @city = city
        @zip_code = zip_code
        @country_iso2 = country_iso2

        @vat_number = vat_number

        @email = email

        @peppol_endpoint_scheme_id = peppol_endpoint_scheme_id || self.class.endpoint_scheme_id_for_country_with_iso2(@country_iso2)
        @peppol_endpoint_id = peppol_endpoint_id || @vat_number
      end

      def address_information
        address_information = "#{street} #{number}".strip
        if bus.present?
          address_information = "#{address_information} - #{bus}".strip
        end

        address_information
      end

      def in_european_economic_area?
        Envoice::CountryCode::EUROPEAN_ECONOMIC_AREAS.member?(@country_iso2)
      end

    end
  end
end