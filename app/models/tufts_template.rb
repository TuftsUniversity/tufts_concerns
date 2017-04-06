# Templates should never be published. They are meant 
# to be used by admin users to ingest files in bulk and 
# apply the same metadata to many files.  There should 
# be no need for them to be visible to general users.
class TuftsTemplate < ActiveFedora::Base
  include BaseModel

  property :template_name, predicate:  Tufts::Vocab::Terms.template_name , multiple: false do |index|
    index.as :stored_searchable
  end

  property :namespace, predicate:   Tufts::Vocab::Terms.namespace , multiple: false do |index|
    index.as :stored_searchable
  end

  property :displays_in, predicate: Tufts::Vocab::Terms.displays_in, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  validates :template_name, presence: true

  # Initialize and set the default namespace to use when creating templates;
  # If a PID is supplied, the PID namespace will override the default
  # If no PID is supplied, the next sequential PID will be assigned in the default namespace
  # Here templates override fedora's install default and use 'template' as their namespace

  def initialize(attributes = {})
    attributes = {} if attributes.nil?
    attributes = {namespace: 'template'}.merge(attributes)
    super
  end

  def self.active
    TuftsTemplate.where('object_state_ssi:A')
  end

  def published?
    false
  end

  def publishable?
    false
  end

  def terms_for_editing
    attributes.keys.collect {|x| x.to_sym } - [:id, :namespace, :access_control_id]
  end

  # The list of fields to edit from the DCA_ADMIN datastream
  def admin_display_fields
    super + [:template_name]
  end

  def terms_for_updating
    terms_for_editing - [:template_name]
  end

  def attributes_to_update
    updates = terms_for_updating.inject({}) do |attrs, attribute|
      value_of_attr = self.send(attribute)
      unless attr_empty?(value_of_attr)
        attrs.merge!(attribute => value_of_attr)
      end
      attrs
    end

    updates
  end

  def apply_attributes(*args)
    raise CannotApplyTemplateError.new
  end

private

  def attr_empty?(value)
    Array(value).all?{|x| x.blank? }
  end

end

class CannotApplyTemplateError < StandardError
  def message
    'Templates cannot be updated by templates'
  end
  def to_s
    self.class.to_s + ": " + message
  end
end
