# Generated via
#  `rails generate curation_concerns:work Work`
module CurationConcerns
  class WorkForm < CurationConcerns::Forms::WorkForm
    include CommonFormProperties
    self.model_class = ::Work
  end
end
