# frozen_string_literal: true

require "test_helper"

class TestEnvoiceUblParty < Minitest::Test
  def test_party_is_in_the_european_economic_area
    be_party = Envoice::Ubl::Party.new(name: 'Skylight BV', street: 'Moerkantsebaan', number: 293, zip_code: '2910', city: 'Essen', country_iso2: Envoice::CountryCode::ISO_2_BE, vat_number: 'BE0897703722', email: 'administration@skylight.be')
    assert be_party.in_european_economic_area?

    uk_party = Envoice::Ubl::Party.new(name: 'ASTRAZENECA UK LIMITED', street: 'Francis Crick Avenue', number: 1, additional_address_information: 'Cambridge Biomedical Campus', zip_code: 'CB2 0AA', city: 'Cambridge', country_iso2: Envoice::CountryCode::ISO_2_GB, vat_number: 'GB582323642', email: 'info@astrazeneca.com')
    refute uk_party.in_european_economic_area?
  end
end