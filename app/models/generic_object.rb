class GenericObject < ActiveRecord::Base
  include CommonSolrAssignments
  include GenericObjectAssignments
  has_paper_trail # on: [:update, :destroy]

  before_destroy :remove_from_solr
  #after_save :send_solr

  serialize :descriptions, Array
  serialize :temporal_coverage, Array
  serialize :date_issued, Array
  serialize :date_created, Array
  serialize :alt_titles, Array
  serialize :publishers, Array
  serialize :related_urls, Array
  serialize :rights_free_text, Array
  serialize :languages, Array
  # Has the following main tables
  # title - singular
  # datastream - polymorphic
  #

  # Belongs to
  belongs_to :coll
  belongs_to :inst

  # Normal has_many
  has_many :base_files

  # Has Many Through Ones
  has_many :object_genres, dependent: :destroy
  has_many :genres, :through=>:object_genres

  has_many :object_geonames, dependent: :destroy
  has_many :geonames, :through=>:object_geonames

  has_many :object_homosaurus_subjects, dependent: :destroy
  has_many :homosaurus_subjects, :through=>:object_homosaurus_subjects

  has_many :object_lcsh_subjects, dependent: :destroy
  has_many :lcsh_subjects, :through=>:object_lcsh_subjects

  has_many :object_resource_types, dependent: :destroy
  has_many :resource_types, :through=>:object_resource_types

  has_many :object_rights, dependent: :destroy
  has_many :rights, :through=>:object_rights

  # Has Many
  has_many :contributors, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :other_subjects, dependent: :destroy


  def model_name
    "GenericFile"
  end

  def delete
    self.destroy
  end

  def iiif_id
    workpls = GenericFile.find(self.id)
    if self.base_files.present?
      path = self.base_files.directory
      path.gsub!('/', '%2F')
    else
      path = 'doesnotexist'
    end
    path
  end

  def generate_solr_content(doc={})
    doc = solr_common_content(doc)

    doc[:dta_altLabel_all_subject_ssim] = []
    doc[:dta_all_subject_ssim] = []
    doc[:dta_other_subject_ssim] = []
    doc[:dta_homosaurus_subject_ssim] = []
    doc[:dta_lcsh_subject_ssim] = []

    doc[:date_created_search_tesim] = []
    doc[:date_issued_search_tesim] = []
    doc[:date_temporal_search_tesim] = []
    doc[:date_created_display_ssim] = []
    doc[:date_issued_display_ssim] = []
    doc[:date_temporal_display_ssim] = []
    doc[:dta_dates_ssim] = []
    doc[:dta_sortable_date_dtsi] = []


    doc[:ident_tesi] = doc[:id]
    doc[:identifier_ssim] = [doc[:ident_tesi]]
    doc[:collection_name_ssim] = [self.coll.title]
    doc[:institution_name_ssim] = [self.inst.name]
    doc[:primary_institution_ssi] = self.inst.name
    doc[:depositor_ssim] = [self.depositor]
    doc[:depository_tesim] = doc[:depositor_ssim]
    doc[:title_tesim] = [self.title]
    doc[:title_ssim] = doc[:title_tesim]
    doc[:label_tesim] = doc[:title_tesim]
    doc[:description_tesim] = [self.descriptions]

    doc[:mime_type_tesim] = self.base_files.pluck(:mime_type)
    doc[:mime_type_tesim].uniq!

    doc[:resource_type_tesim] = self.resource_types.pluck(:label)
    doc[:creator_tesim] = self.creators.pluck(:label)
    doc[:creator_ssim] = doc[:creator_tesim]
    doc[:contributor_tesim] = self.contributors.pluck(:label)
    doc[:contributor_ssim] = doc[:contributor_tesim]
    doc[:rights_tesim] = self.rights.pluck(:label)
    doc[:publisher_tesim] = self.publishers
    doc[:publisher_ssim] = doc[:publisher_tesim]

    doc[:language_tesim] = self.languages
    doc[:based_near_tesim] = self.geonames.pluck(:uri)
    doc[:based_near_ssim] = doc[:based_near_tesim]

    doc[:isPartOf_ssim] = self.coll.pid # collection
    doc[:isMemberOf_ssim] = self.inst.pid # institution
    doc[:temporal_coverage_tesim] = self.temporal_coverage
    doc[:date_issued_tesim] = self.date_issued
    doc[:genre_tesim] = self.genres.pluck(:label)
    doc[:genre_ssim] = doc[:genre_tesim]

    doc[:alternative_tesim] = self.alt_titles
    doc[:flagged_tesim] = [self.flagged]
    doc[:lcsh_subject_tesim] = self.lcsh_subjects.pluck(:uri)
    doc[:lcsh_subject_ssim] = doc[:lcsh_subject_tesim]
    doc[:other_subject_tesim] = self.other_subjects.pluck(:label)
    doc[:other_subject_ssim] = doc[:other_subject_tesim]
    doc[:dta_other_subject_tesim] = doc[:other_subject_ssim]
    doc[:homosaurus_subject_tesim] = self.homosaurus_subjects.pluck(:uri)
    doc[:homosaurus_subject_ssim] = doc[:homosaurus_subject_tesim]

    #file_format_tesim like pdf (Portable Document Format)
    # Label versions
    self.homosaurus_subjects.each do |term|
      doc[:dta_homosaurus_subject_ssim] << (term.label[0].upcase + term.label[1..-1])
      doc[:dta_all_subject_ssim] << (term.label[0].upcase + term.label[1..-1])
      term.alt_labels.each do |alt|
        doc[:dta_altLabel_all_subject_ssim] << alt
      end
    end

    self.lcsh_subjects.each do |term|
      doc[:dta_lcsh_subject_ssim] << term.label
      doc[:dta_all_subject_ssim] << term.label
      term.alt_labels.each do |alt|
        doc[:dta_altLabel_all_subject_ssim] << alt
      end
    end

    self.other_subjects.each do |term|
      doc[:dta_other_subject_ssim] << term.label
    end

    doc[:dta_homosaurus_subject_ssim].sort_by!{|word| word.downcase}
    doc[:dta_all_subject_ssim].sort_by!{|word| word.downcase}
    doc[:dta_lcsh_subject_ssim].sort_by!{|word| word.downcase}
    doc[:dta_other_subject_ssim].sort_by!{|word| word.downcase}

    doc[:dta_other_subject_tesim] = doc[:dta_other_subject_ssim]
    doc[:dta_subject_primary_searchable_tesim] = doc[:dta_all_subject_ssim] + doc[:dta_other_subject_ssim]
    doc[:dta_subject_alt_searchable_tesim] = doc[:dta_altLabel_all_subject_ssim]

    doc[:dta_all_subject_ssim].uniq!
    doc[:dta_altLabel_all_subject_ssim].uniq!

    # Dates copied over
    self.date_issued.each do |raw_date|
      date = Date.edtf(raw_date)
      doc[:date_issued_search_tesim] << keyword_edtf(date)
      doc[:date_issued_display_ssim] << humanize_edtf(date)
      if date.class == Date
        doc[:date_start_dtsi] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:date_end_dtsi] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:dta_dates_ssim] << date.year
        #doc['dta_sortable_date_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:dta_sortable_date_dtsi] = "#{date.year}-#{date.month.to_s.rjust(2, '0')}-#{date.day.to_s.rjust(2, '0')}T00:00:00.000Z"
      elsif date.present?
        doc[:date_start_dtsi] = date.first.year.to_s + '-01-01T00:00:00.000Z'
        doc[:date_end_dtsi] = date.last.year.to_s + '-01-01T00:00:00.000Z'
        if date.last.year.to_i == date.first.year.to_i
          doc[:dta_sortable_date_dtsi] = date.last.year.to_i.to_s + '-' + (((date.last.month.to_i - date.first.month.to_i) / 2) + date.first.month.to_i).to_i.to_s.rjust(2, '0') + '-01T00:00:00.000Z'
        else
          doc[:dta_sortable_date_dtsi] = (((date.last.year.to_i - date.first.year.to_i) / 2) + date.first.year.to_i).to_i.to_s + '-01-01T00:00:00.000Z'
        end

        (date.first.year..date.last.year).step(1) do |year_step|
          doc[:dta_dates_ssim] << year_step
        end
      end
    end

    self.date_created.each do |raw_date|
      date = Date.edtf(raw_date)
      doc[:date_created_search_tesim] << keyword_edtf(date)
      doc[:date_created_display_ssim] << humanize_edtf(date)
      if date.class == Date
        doc[:date_start_dtsi] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:date_end_dtsi] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:dta_dates_ssim] << date.year
        #doc['dta_sortable_date_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc[:dta_sortable_date_dtsi] = "#{date.year}-#{date.month.to_s.rjust(2, '0')}-#{date.day.to_s.rjust(2, '0')}T00:00:00.000Z"
      elsif date.present?
        doc[:date_start_dtsi] = date.first.year.to_s + '-01-01T00:00:00.000Z'
        doc[:date_end_dtsi] = date.last.year.to_s + '-01-01T00:00:00.000Z'
        if date.last.year.to_i == date.first.year.to_i
          doc[:dta_sortable_date_dtsi] = date.last.year.to_i.to_s + '-' + (((date.last.month.to_i - date.first.month.to_i) / 2) + date.first.month.to_i).to_i.to_s.rjust(2, '0') + '-01T00:00:00.000Z'
        else
          doc[:dta_sortable_date_dtsi] = (((date.last.year.to_i - date.first.year.to_i) / 2) + date.first.year.to_i).to_i.to_s + '-01-01T00:00:00.000Z'
        end

        (date.first.year..date.last.year).step(1) do |year_step|
          doc[:dta_dates_ssim] << year_step
        end
      end
    end

    self.temporal_coverage.each do |raw_date|
      date = Date.edtf(raw_date)
      doc[:date_temporal_search_tesim] << keyword_edtf(date)
      doc[:date_temporal_display_ssim] << humanize_edtf(date)
    end

    doc[:date_created_search_ssim] = doc[:date_created_search_tesim]
    doc[:date_issued_search_ssim] = doc[:date_issued_search_tesim]
    doc[:date_temporal_search_ssim] = doc[:date_temporal_search_tesim]


    # Adding in manually
    doc[:toc_tesim] = [self.toc]
    doc[:analog_format_tesim] = self.analog_format
    doc[:digital_format_tesim] = self.digital_format
    doc[:is_shown_at_tesim] = [self.is_shown_at]
    doc[:is_shown_at_ssim] = doc[:is_shown_at_tesim]
    doc[:preview_tesim] = [self.preview]
    doc[:preview_ssim] = doc[:preview_tesim]
    doc[:hosted_elsewhere_ssi] = self.hosted_elsewhere
    doc[:rights_free_text_tesim] = self.rights_free_text
    doc[:rights_free_text_ssim] = doc[:rights_free_text_tesim]

    # More Transfer
    if self.base_files.present? && self.base_files.first.ocr.present?
      doc['dta_ocr_tiv'] = self.base_files.first.ocr.squish
    end
    doc['language_label_ssim'] = []
    self.languages.each do |lang|
      if lang.match(/eng$/)
        doc['language_label_ssim'] << 'English'
      else
        result = BplEnrich::Authorities.parse_language(lang.split('/').last)
        if result.present?
          doc['language_label_ssim'] << result[:label]
        end
      end
    end

    # MISSING THESE
    doc[:subject_geojson_facet_ssim] = []
    doc[:subject_coordinates_geospatial] = []
    doc[:subject_geographic_hier_ssim] = []
    doc[:subject_geographic_ssim] = []
    doc[:subject_geographic_tesim] = []
    doc[:based_near_ssim] = self.geonames.pluck(:uri) if self.geonames.present?

    self.geonames.each do |geo|
      doc[:subject_geojson_facet_ssim] << geo.geo_json_hash.stringify_keys.to_s
      doc[:subject_coordinates_geospatial] << "#{geo.lat},#{geo.lng}"
      doc[:subject_geographic_ssim] << geo.hierarchy_full
      #    t.text :hierarchy_full
      #t.text :hierarchy_display
      doc[:subject_geographic_hier_ssim] << geo.hierarchy_display.join('||')
    end
    doc[:subject_geographic_ssim].uniq!
    doc[:subject_geographic_tesim] = doc[:subject_geographic_ssim]

    doc[:dta_altLabel_all_subject_ssim] = []
    self.homosaurus_subjects.each do |subj|
      subj.alt_labels.each do |lbl|
        doc[:dta_altLabel_all_subject_ssim] << lbl
      end
    end

    self.lcsh_subjects.each do |subj|
      subj.alt_labels.each do |lbl|
        doc[:dta_altLabel_all_subject_ssim] << lbl
      end
    end

    doc
  end

  def humanize_edtf(edtf_date)
    humanized_edtf = edtf_date.humanize
    # Capitalize the seasons
    humanized_edtf = humanized_edtf.split(' ').map! { |word| ['summer', 'winter', 'autumn', 'spring'].include?(word) ? word.capitalize : word }.join(' ')

    #Abbreviate the Months
    humanized_edtf = humanized_edtf.split(' ').map! { |word|  Date::MONTHNAMES.include?(word) ? "#{Date::ABBR_MONTHNAMES[Date::MONTHNAMES.find_index(word)]}." : word }.join(' ')

    #Remove period from "May"
    humanized_edtf = humanized_edtf.split(' ').map! { |word|  word.include?('May.') ? "May" : word }.join(' ')

    humanized_edtf
  end

  def keyword_edtf(edtf_date)
    humanized_edtf = edtf_date.humanize
    # Capitalize the seasons
    humanized_edtf = humanized_edtf.split(' ').map! { |word| ['summer', 'winter', 'autumn', 'spring'].include?(word) ? word.capitalize : word }.join(' ')

    #Abbreviate the Months
    humanized_edtf = humanized_edtf.split(' ').map! { |word|  Date::MONTHNAMES.include?(word) ? "#{Date::ABBR_MONTHNAMES[Date::MONTHNAMES.find_index(word)]} #{word}" : word }.join(' ')

    humanized_edtf
  end

end
