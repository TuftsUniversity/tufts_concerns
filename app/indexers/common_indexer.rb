# COPIED From https://github.com/mkorcy/tdl_hydra_head/blob/master/lib/tufts/model_methods.rb
require 'chronic'

class CommonIndexer < CurationConcerns::WorkIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      create_facets solr_doc
      # create_formatted_fields solr_doc
      # index_sort_fields solr_doc
    end # End super.tap
  end # End def generate_solr_document

  private

  def index_sort_fields(solr_doc)
    # CREATOR SORT
    Solrizer.insert_field(solr_doc, 'author', object.creator.first, :sortable) unless creator.empty?

    # TITLE SORT
    Solrizer.insert_field(solr_doc, 'title', object.title, :sortable) if object.title
  end

  # MISCNOTES:
  # There will be no facet for RCR. There will be no way to reach RCR via browse.
  # 3. There will be a facet for "collection guides", namely EAD, namely the landing page view we discussed on Friday.
  def create_facets(solr_doc)

    index_names_info(solr_doc)
    index_subject_info(solr_doc)
    index_date_info(solr_doc)
    index_pub_date(solr_doc)
    index_format_info(solr_doc)

    #index_unstemmed_values(solr_doc)
    index_deposit_method(solr_doc)
  end

  def index_deposit_method(solr_doc)
    case object.createdby
      when 'selfdep' #Contribution::SELFDEP
        Solrizer.insert_field(solr_doc, 'deposit_method', 'self-deposit', :stored_sortable)
    end
  end

  def index_unstemmed_values(solr_doc)
    titleize_and_index_array(solr_doc, 'corpname', corpname, :unstemmed_searchable)
    titleize_and_index_array(solr_doc, 'geogname', geogname, :unstemmed_searchable)
    titleize_and_index_array(solr_doc, 'subject_topic', subject, :unstemmed_searchable)
    titleize_and_index_array(solr_doc, 'persname', persname, :unstemmed_searchable)
    titleize_and_index_array(solr_doc, 'author', creator, :unstemmed_searchable)
    titleize_and_index_single(solr_doc, 'title', title, :unstemmed_searchable)

  end

  def index_names_info(solr_doc)
    [:creator, :contributor, :personal_name, :corporate_name].each do |name_field|
      names = object.send(name_field)
      index_array(solr_doc, 'names', names, :facetable)  #names_sim
    end
    solr_doc
  end

  def index_subject_info(solr_doc)
    [:subject, :corporate_name, :personal_name, :complex_subject].each do |subject_field|
      subjects = object.send(subject_field)
      index_array(solr_doc, 'subject_topic', subjects, :facetable)  #subject_sim
    end
  end


  def index_array(solr_doc, field_prefix, values, index_type)
    values.each do |name|
      index_single(solr_doc, field_prefix, name, index_type)
    end
  end

  def index_single(solr_doc, field_prefix, name, index_type)
    if name.present? &&  !name.downcase.include?('unknown')
      Solrizer.insert_field(solr_doc, field_prefix, name, index_type)
    end
  end

  def format_dd_mm_yyyy(date)
    #handle 01/01/2004 style dates
    if (!date.nil? && !date[/\//].nil?)
      date = date[date.rindex('/')+1..date.length()]
      #check for 2 digit year
      if (date.length() == 2)
        date = "19" + date
      end
    end
    #end handle 01/01/2004 style dates
    date
  end

  def format_nd(date)
    #handle n.d.
    if (!date.nil? && date[/n\.d/])
      date = "0"
    end
    #end n.d.
    date
  end

  def format_yyyy_mm_dd(date)
    #handle YYYY-MM-DD and MM-DD-YYYY
    if (!date.nil? && !date[/-/].nil?)
      if (date.index('-') == 4)
        date = date[0..date.index('-')-1]
      else
        date = date[date.rindex('-')+1..date.length()]
      end
    end
    #end YYYY-MM-DD
    date
  end

  def temporal_or_created
    dates = object.date_created

    if dates.empty?
      dates = object.temporal
    end

    dates
  end

  def format_circa(date)
    if (!date.nil? && !date[/^c/].nil?)
      date = date.split[1..10].join(' ')
    end
    #end handling circa dates
    date
  end

  def extract_year(valid_date)
    if valid_date == "0"
      valid_date_string = "0"
    else
      valid_date_string = valid_date.strftime("%Y")
    end
    valid_date_string
  end

  def convert_to_year(date)
    valid_date = Time.new
    unless (date.nil? || date == "0")
      if date.length() == 4
        date += "-01-01"
      elsif date.length() == 9
        date = date[0..3] += "-01-01"
      elsif date.length() == 7
        date = date[0..3] += "-01-01"
      end

      unparsed_date =Chronic.parse(date)
      unless unparsed_date.nil?
        valid_date = Time.at(unparsed_date)
      end
    end
    valid_date
  end

  def index_pub_date(solr_doc)
    dates = temporal_or_created

    return if dates.empty?
    date = dates[0]
    date = date.to_s
    date = format_circa(date)
    date = format_dd_mm_yyyy(date)
    date = format_nd(date)
    date = format_yyyy_mm_dd(date)

    #Chronic is not gonna like the 4 digit date here it may interpret as military time, and
    #this may be imperfect but lets try this.
    valid_date = convert_to_year(date)
    valid_date_string = extract_year(valid_date)
    Solrizer.insert_field(solr_doc, 'pub_date', valid_date_string.to_i, :stored_sortable)
  end

  #if possible, exposed as ranges, cf. the Virgo catalog facet "publication era". Under the heading
  #"Date". Also, if possible, use Temporal if "Date.Created" is unavailable.)

  #Only display these as years (ignore the MM-DD) and ideally group them into ranges. E.g.,
  ##if we had 4 items that had the years 2001, 2004, 2006, 2010, the facet would look like 2001-2010.
  #Perhaps these could be 10-year ranges, or perhaps, if it's not too difficult, the ranges could generate
  #automatically based on the available data.

  def index_date_info(solr_doc)
    dates = temporal_or_created

    unless dates.empty?
      dates.each do |date|
        if date.length() == 4
          date += "-01-01"
        end

        valid_date = Chronic.parse(date)
        unless valid_date.nil?
          last_digit= valid_date.year.to_s[3,1]
          decade_lower = valid_date.year.to_i - last_digit.to_i
          decade_upper = valid_date.year.to_i + (10-last_digit.to_i)
          if decade_upper >= 2020
            decade_upper ="Present"
          end
          Solrizer.insert_field(solr_doc, 'year', "#{decade_lower} to #{decade_upper}", :facetable)
        end
      end
    end
  end

  # The facets in this category will have labels and several types of digital objects might fit under one label.
  #For example, if you look at the text bullet here, you will see that we have the single facet "format" which
  #includes PDF, faculty publication, and TEI).

  #The labels are:


  #Text Includes PDF, faculty publication, TEI, captioned audio.

  #Images Includes 4 DS image, 3 DS image
  #Preferably, not PDF page images, not election record images.
  #Note that this will include the individual images used in image books and other TEI, but not the books themselves.
  ##Depending on how we deal with the PDFs, this might include individual page images for PDF. Problem?

  #Datasets include wildlife pathology, election records, election images (if possible), Boston streets splash pages.
  #Periodicals any PID that begins with UP.
  #Collection guides Text.EAD
  #Audio Includes audio, captioned audio, oral history.

  def index_format_info(solr_doc)
    Solrizer.insert_field(solr_doc, 'object_type', object.human_readable_type, :facetable)


    #Solrizer.insert_field(solr_doc, 'object_type', model_s, :facetable) if model_s
    #Solrizer.insert_field(solr_doc, 'object_type', model_s, :symbol) if model_s


    # At this point primary classification is complete but there are some outlier cases where we want to
    # Attribute two classifications to one object, now's the time to do that
    ##,"info:fedora/cm:Audio.OralHistory","info:fedora/afmodel:TuftsAudioText" -> needs text
    ##,"info:fedora/cm:Image.HTML" -->needs text
    #if ["info:fedora/cm:Audio","info:fedora/afmodel:TuftsAudio","info:fedora/afmodel:TuftsVideo"].include? model
    #  unless self.datastreams['ARCHIVAL_XML'].dsLocation.nil?
    #    Solrizer.insert_field(solr_doc, 'object_type', 'Text', :facetable)
    #    Solrizer.insert_field(solr_doc, 'object_type', 'Text', :symbol)
    #  end
    #end
  end

  def create_formatted_fields(solr_doc)
    self.date_created.each do |date_created|
      # we're storing BCE dates as -0462 using ISO-6801 standard but we want to retrieve them for display formatted for the screen
      if date_created.start_with? '-'
        date_created = "#{date_created.sub(/^[0\-]*/,'')} BCE"
      end

      Solrizer.insert_field(solr_doc, 'date_created_formatted', "#{date_created}", :stored_searchable) #tesim
    end
  end

  def insert_object_type(solr_doc, model)

  end

end
