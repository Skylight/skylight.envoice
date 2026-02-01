# frozen_string_literal: true

require "test_helper"
require "date"

class TestEnvoiceUblGenerator < Minitest::Test

  def test_ubl_invoice_file_be_to_be
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: "F2024-005",
      issue_date: DateTime.parse('2024-02-01'),
      due_date: Date.parse('2024-03-02'),
      currency: 'EUR',
      buyer_reference: 'PO 1234567890'
    )

    document.sender = Envoice::Ubl::Party.new(
      peppol_endpoint_scheme_id: '0208',
      peppol_endpoint_id: '0897703722',
      name: 'Skylight BV',
      street: 'Moerkantsebaan',
      number: 293,
      city: 'Essen',
      zip_code: '2910',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE0897703722',
      email: 'administration@skylight.be',
      legal_form: 'RPR Antwerpen'
    )

    document.receiver = Envoice::Ubl::Party.new(
      name: 'CAT-Solutions BV',
      street: 'Beneluxlaan',
      number: 1,
      bus: 'A',
      additional_address_information: nil,
      zip_code: '8500',
      city: 'Kortrijk',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE 0898.625.024',
      email: 'facturen@customer.test'
    )

    document.payment_means = Envoice::Ubl::PaymentMeans.new(
      account_name: 'SKYLIGHT SA',
      iban: 'BE29735065007364',
      bic: 'KREDBEBB',
      payment_reference: 'F2024-005'
    )

    document.payment_terms = "Net within 30 days"

    document.add_line(name: 'Service 1', quantity: 1.0, unit_price: 240.0, tax_rate: 21.0)
    document.add_line(name: 'Service 2', quantity: 2.0, unit_price: 55.55, tax_rate: 21.0)

    dummy_pdf_filename = File.join(ROOT_PATH, 'test', 'assets', 'test-document-001.pdf')
    assert File.exist?(dummy_pdf_filename)

    document.add_attachment_from_file(absolute_file_name: dummy_pdf_filename, id: 'F2024-005', description: "Invoice F2024-005", mime_type: 'application/pdf', document_type_code: 130)

    expected_ubl_filename = File.join(ROOT_PATH, 'test', 'assets', 'ubl', 'invoice_file_be_to_be.xml')

    generated_ubl = Envoice::Ubl::Generator.generate_ubl_invoice(document).to_s

    # Update `Golden Master Verification` file if output format changes;
    # File.write(expected_ubl_filename, generated_ubl)

    assert File.exist?(expected_ubl_filename)

    assert_equal generated_ubl, File.read(expected_ubl_filename)
  end

  def test_ubl_invoice_file_be_to_ch
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: "F2024-005",
      issue_date: DateTime.parse('2024-02-01'),
      due_date: Date.parse('2024-03-02'),
      currency: 'EUR',
      buyer_reference: 'PO 1234567890'
    )

    document.sender = Envoice::Ubl::Party.new(
      peppol_endpoint_scheme_id: '0208',
      peppol_endpoint_id: '0897703722',
      name: 'Skylight BV',
      street: 'Moerkantsebaan',
      number: 293,
      city: 'Essen',
      zip_code: '2910',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE0897703722',
      email: 'administration@skylight.be',
      legal_form: 'RPR Antwerpen'
    )

    document.receiver = Envoice::Ubl::Party.new(
      name: 'AstraZeneca BV',
      street: 'Postbus',
      number: 648,
      additional_address_information: 'EBS Accounts Payable',
      zip_code: '2700 AP',
      city: 'Zoetermeer',
      country_iso2: Envoice::CountryCode::ISO_2_NL,
      vat_number: 'NL 0097.39.129.B.01',
      email: 'facturen@customer.test'
    )

    document.payment_means = Envoice::Ubl::PaymentMeans.new(
      account_name: 'SKYLIGHT SA',
      iban: 'BE29735065007364',
      bic: 'KREDBEBB',
      payment_reference: 'F2024-005'
    )

    document.payment_terms = "Net within 30 days"
    document.tax_exemption_reason = 'BTW verlegd'

    document.add_line(name: 'Service 1', quantity: 1.0, unit_price: 240.0, tax_rate: 0.0)
    document.add_line(name: 'Service 2', quantity: 2.0, unit_price: 55.55, tax_rate: 0.0)

    dummy_pdf_filename = File.join(ROOT_PATH, 'test', 'assets', 'test-document-001.pdf')
    assert File.exist?(dummy_pdf_filename)

    document.add_attachment_from_file(absolute_file_name: dummy_pdf_filename, id: 'F2024-005', description: "Invoice F2024-005", mime_type: 'application/pdf', document_type_code: 130)

    expected_ubl_filename = File.join(ROOT_PATH, 'test', 'assets', 'ubl', 'invoice_file_be_to_nl.xml')

    generated_ubl = Envoice::Ubl::Generator.generate_ubl_invoice(document).to_s

    # Update `Golden Master Verification` file if output format changes;
    # File.write(expected_ubl_filename, generated_ubl)

    assert File.exist?(expected_ubl_filename)

    assert_equal generated_ubl, File.read(expected_ubl_filename)
  end


  def test_ubl_invoice_with_attachments_from_stream
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: "F2024-005",
      issue_date: DateTime.parse('2024-02-01'),
      due_date: Date.parse('2024-03-02'),
      currency: 'EUR',
      buyer_reference: 'PO 1234567890'
    )

    document.sender = Envoice::Ubl::Party.new(
      peppol_endpoint_scheme_id: '0208',
      peppol_endpoint_id: '0897703722',
      name: 'Skylight BV',
      street: 'Moerkantsebaan',
      number: 293,
      city: 'Essen',
      zip_code: '2910',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE0897703722',
      email: 'administration@skylight.be',
      legal_form: 'RPR Antwerpen'
    )

    document.receiver = Envoice::Ubl::Party.new(
      name: 'CAT-Solutions BV',
      street: 'Beneluxlaan',
      number: 1,
      bus: 'A',
      additional_address_information: nil,
      zip_code: '8500',
      city: 'Kortrijk',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE 0898.625.024',
      email: 'facturen@customer.test'
    )

    document.payment_means = Envoice::Ubl::PaymentMeans.new(
      account_name: 'SKYLIGHT SA',
      iban: 'BE29735065007364',
      bic: 'KREDBEBB',
      payment_reference: 'F2024-005'
    )

    document.payment_terms = "Net within 30 days"

    document.add_line(name: 'Service 1', quantity: 1.0, unit_price: 240.0, tax_rate: 21.0)
    document.add_line(name: 'Service 2', quantity: 2.0, unit_price: 55.55, tax_rate: 21.0)

    dummy_pdf_filename = File.join(ROOT_PATH, 'test', 'assets', 'test-document-001.pdf')
    assert File.exist?(dummy_pdf_filename)

    attachment = File.binread(dummy_pdf_filename)

    document.add_attachment(filename: 'test-document-001.pdf', id: 'F2024-005', description: "Invoice F2024-005", mime_type: 'application/pdf', contents: attachment, document_type_code: 130)

    expected_ubl_filename = File.join(ROOT_PATH, 'test', 'assets', 'ubl', 'invoice_file_be_to_be.xml')

    generated_ubl = Envoice::Ubl::Generator.generate_ubl_invoice(document).to_s

    # Update `Golden Master Verification` file if output format changes;
    # File.write(expected_ubl_filename, generated_ubl)

    assert File.exist?(expected_ubl_filename)

    assert_equal generated_ubl, File.read(expected_ubl_filename)
  end

  def test_ubl_credit_note_file_be_to_be
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_CREDIT_NOTE,
      id: "C2024-005",
      issue_date: DateTime.parse('2024-02-01'),
      due_date: Date.parse('2024-03-02'),
      currency: 'EUR',
      buyer_reference: 'PO 1234567890'
    )

    document.sender = Envoice::Ubl::Party.new(
      peppol_endpoint_scheme_id: '0208',
      peppol_endpoint_id: '0897703722',
      name: 'Skylight BV',
      street: 'Moerkantsebaan',
      number: 293,
      city: 'Essen',
      zip_code: '2910',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE0897703722',
      email: 'administration@skylight.be'
    )

    document.receiver = Envoice::Ubl::Party.new(
      name: 'CAT-Solutions BV',
      street: 'Beneluxlaan',
      number: 1,
      bus: 'A',
      additional_address_information: nil,
      zip_code: '8500',
      city: 'Kortrijk',
      country_iso2: Envoice::CountryCode::ISO_2_BE,
      vat_number: 'BE 0898.625.024',
      email: 'facturen@customer.test'
    )

    document.payment_means = Envoice::Ubl::PaymentMeans.new(
      account_name: 'SKYLIGHT SA',
      iban: 'BE29735065007364',
      bic: 'KREDBEBB',
      payment_reference: 'C2024-005'
    )

    document.add_line(name: 'Service 1', quantity: 1.0, unit_price: 240.0, tax_rate: 21.0)
    document.add_line(name: 'Service 2', quantity: 2.0, unit_price: 55.55, tax_rate: 21.0)

    dummy_pdf_filename = File.join(ROOT_PATH, 'test', 'assets', 'test-document-001.pdf')
    assert File.exist?(dummy_pdf_filename)

    document.add_attachment_from_file(absolute_file_name: dummy_pdf_filename, id: 'C2024-005', description: "Credit Note C2024-005", mime_type: 'application/pdf')

    expected_ubl_filename = File.join(ROOT_PATH, 'test', 'assets', 'ubl', 'credit_note_file_be_to_be.xml')

    generated_ubl = Envoice::Ubl::Generator.generate_ubl_credit_note(document).to_s

    # Update `Golden Master Verification` file if output format changes;
    # File.write(expected_ubl_filename, generated_ubl)

    assert File.exist?(expected_ubl_filename)

    assert_equal generated_ubl, File.read(expected_ubl_filename)
  end

end