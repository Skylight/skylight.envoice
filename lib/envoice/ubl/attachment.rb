# frozen_string_literal: true

module Envoice
  module Ubl
    class Attachment

      attr_reader :filename, :id, :description, :mime_type, :contents

      def initialize(filename:, id:, description:, mime_type:, contents:)
        @filename = filename
        @id = id
        @description = description
        @mime_type = mime_type
        @contents = contents
      end

    end
  end
end