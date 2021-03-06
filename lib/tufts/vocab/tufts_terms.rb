require 'rdf/vocab'
module Tufts
  module Vocab
    # http://dl.tufts.edu/terms/identifier
    class Terms < RDF::Vocabulary('http://dl.tufts.edu/terms#')
      # term :VotingRecord
      # term :EAD
      # term :EAC
      term :legacy_pid
      term :local_file_type
      term :steward
      term :internal_note
      term :displays_in
      term :term_of_restriction
      term :visibility
      term :batch_id
      term :namespace
      term :is_notes_of
      term :is_slides_of
      term :createdby
      term :template_name
    end
  end
end
