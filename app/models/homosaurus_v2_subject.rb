class HomosaurusV2Subject < HomosaurusSubject
  #after_save :send_solr

  def self.find_with_conditions(q:, rows:, fl:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = 'active_fedora_model_ssi:HomosaurusV2'
    result = DSolr.find(opts)
    result
  end

  def terms
    ['closeMarch', 'exactMatch']
  end

  def self.loadV2(xml_location)
    ActiveRecord::Base.transaction do
      HomosaurusV2Subject.all.each do |subj|
        subj.destroy!
      end

      doc = File.open(xml_location) { |f| Nokogiri::XML(f) }

      doc.remove_namespaces!

      doc.xpath("//Concept").each do |concept|
        obj = {}
        obj[:label] = concept.xpath('./prefLabel').text.to_s.gsub(/[\n\t]+/, '').gsub('’', "'").strip
        obj[:identifier] = createIdentifier(obj[:label])

        obj[:alt_labels] = concept.xpath('./altLabel').map{ |l| l.text.to_s.gsub(/[\n\t]+/, '').strip }
        obj[:related] = concept.xpath('./related').map{ |l| createIdentifier(l.text.to_s.gsub(/[\n\t]+/, '').gsub('’', "'").strip )}
        obj[:broader] = concept.xpath('./broader').map{ |l| createIdentifier(l.text.to_s.gsub(/[\n\t]+/, '').gsub('’', "'").strip )}
        obj[:narrower] = concept.xpath('./narrower').map{ |l| createIdentifier(l.text.to_s.gsub(/[\n\t]+/, '').gsub('’', "'").strip )}
        obj[:uri] = "http://homosaurus.org/v2/#{obj[:identifier]}"
        obj[:pid] = "homosaurus/v2/#{obj[:identifier]}"
        obj[:version] = "v2"
        obj[:description] = concept.xpath('./scopeNote').text.to_s.gsub(/[\n\t]+/, '').strip

        existing = HomosaurusV2Subject.find_by(identifier: obj[:identifier])
        if existing.blank?
          HomosaurusV2Subject.create(obj)
        else
          existing.alt_labels = (existing.alt_labels + obj[:alt_labels]).uniq if obj[:alt_labels].present?
          existing.related = existing.related + obj[:related] if obj[:related].present?
          existing.broader = existing.broader + obj[:broader] if obj[:broader].present?
          existing.narrower = existing.narrower + obj[:narrower] if obj[:narrower].present?
          existing.description = existing.description if obj[:description].present?
          existing.save!
        end

      end
    end


    self.clean_all

  end

  def self.clean_all
    HomosaurusV2Subject.all.each do |subj|
      related = clean_up(subj.related)
      subj.related = related unless related == subj.related

      narrower = clean_up(subj.narrower)
      subj.narrower = narrower unless narrower == subj.narrower

      broader = clean_up(subj.broader)
      subj.broader = broader unless broader == subj.broader

      subj.save!
    end
  end

  def self.clean_up(array)
    values = []
    array.each do |rel|
      if HomosaurusV2Subject.exists?(identifier: rel)
        values << rel
      elsif HomosaurusV2Subject.exists?(identifier: rel[0..-2])
        values << rel[0..-2]
      end
    end
    values
  end

  def self.createIdentifier(s)
    match = HomosaurusSubject.find_by(label: s)
    return match.identifier if match.present?

    identifier = ''
    s.gsub(/[\(\)]*/, '').gsub(/['";\n\t]+/, '').gsub('á', "a").gsub('ā', 'a').split(/[ \-]/).each_with_index do |t, index|
      if t.upcase == t
        identifier += t
      elsif index == 0
        identifier += t.downcase
      else
        identifier += t.capitalize
      end
    end

    if identifier.include?('MRKHMullerian')
      identifier = 'MRKH'
    elsif identifier.length > 34
      identifier = identifier[0..35]
    end

    identifier.strip
  end

  def model_name
    "HomosaurusV2"
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/v2/#{self.identifier}"
  end

  def delete
    self.destroy
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def generate_solr_content(doc={})
    doc[:id] = "homosaurus/v2/#{self.identifier}"
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:model_ssi] = self.model_name
    doc[:has_model_ssim] = [self.model_name]
    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:issued_dtsi] = doc[:system_create_dtsi]
    doc[:modified_dtsi] = doc[:system_modified_dtsi]

    doc[:version_ssi] = self.version

    doc[:prefLabel_ssim] = [self.label]
    doc[:prefLabel_tesim] = doc[:prefLabel_ssim]
    doc[:label_eng_ssim] = [self.label_eng]
    doc[:label_eng_tesim] = doc[:label_eng_ssim]
    doc[:broader_ssim] = self.broader
    doc[:related_ssim] = self.related
    doc[:narrower_ssim] = self.narrower
    doc[:closeMatch_ssim] = self.closeMatch
    doc[:exactMatch_ssim] = self.exactMatch
    doc[:altLabel_tesim] = self.alt_labels
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:identifier_ssi] = self.identifier
    doc[:description_ssi] = self.description
    doc[:description_tesim] = [self.description]

    doc[:dta_homosaurus_lcase_prefLabel_ssi] = self.label.downcase
    doc[:dta_homosaurus_lcase_altLabel_ssim] = []
    self.alt_labels.each do |alt|
      doc[:dta_homosaurus_lcase_altLabel_ssim] << alt.downcase
    end

    @broadest_terms = []
    get_broadest(self.identifier)
    doc[:topConcept_ssim] = @broadest_terms.uniq if @broadest_terms.present?
    doc[:new_model_ssi] = 'HomosaurusV2Subject'
    doc[:active_fedora_model_ssi] = 'HomosaurusV2'
    doc
  end

  def get_broadest(item)
    if HomosaurusV2Subject.find_by(identifier: item).broader.blank?
      @broadest_terms << item.split('/').last
    else
      puts 'FINDING FOR: ' + self.identifier.to_s
      HomosaurusV2Subject.find_by(identifier: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

  def verify_hierarchy(obj, type: 'broader')
    obj.send(type).each do |sub|
      HomosaurusV2Subject.find_by(identifier: sub).send(type).each do |sub2|
        return sub2 if sub2 == obj.identifier
      end
    end
    return nil
  end

  def verify_related(obj, type: 'related')
    match = false
    obj.send(type).each do |sub|
      HomosaurusV2Subject.find_by(identifier: sub).send(type).each do |sub2|
        match = true if sub2 == obj.identifier
      end
    end
    return obj.identifier unless match
    return nil
  end


  def self.show_fields
    ['prefLabel', 'label@en_us', 'altLabel', 'description', 'identifier', 'issued', 'modified', 'exactMatch', 'closeMatch']
  end

  def self.get_values(field, obj)
    case field
    when "identifier"
      [obj["identifier_ssi"]] || []
    when "prefLabel"
      obj["prefLabel_ssim"] || []
    when "label@en_us"
      obj["label_eng_ssim"] || []
    when "altLabel"
      obj["altLabel_ssim"] || []
    when "description"
      [obj["description_ssi"]] || []
    when "issued"
      obj["date_created_ssim"] || []
    when "modified"
      obj["date_created_ssim"] || []
    when "exactMatch"
      [nil]
    when "closeMatch"
      [nil]
    when "related"
      obj["related_ssim"] || []
    when "broader"
      obj["broader_ssim"] || []
    when "narrower"
      obj["narrower_ssim"] || []
    else
      [nil]
    end
  end

  def self.getLabel field
    case field
    when "identifier"
      "<a href='http://purl.org/dc/terms/identifier' target='blank' title='Definition of Identifier in the Dublin Core Terms Vocabulary'>Identifier</a>"
    when "prefLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Preferred Label in the SKOS Vocabulary'>Preferred Label</a>"
    when "label@en_us"
      "<a href='https://terms.tdwg.org/wiki/rdfs:label' target='blank'  title='RDFS label property with the english language flag.'>US English Label</a>"
    when "altLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#altLabel' target='blank'  title='Definition of Alternative Label in the SKOS Vocabulary'>Alternative Label (Use For)</a>"
    when "description"
      "<a href='http://www.w3.org/2000/01/rdf-schema#comment' target='blank'  title='Definition of Comment in the RDF Schema Vocabulary'>Description</a>"
    when "issued"
      "<a href='http://purl.org/dc/terms/issued' target='blank'  title='Definition of Issued in the Dublin Core Terms Vocabulary'>Issued (Created)</a>"
    when "modified"
      "<a href='http://purl.org/dc/terms/modified' target='blank'  title='Definition Modified in the Dublin Core Terms Vocabulary'>Modified</a>"
    when "exactMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#exactMatch' target='blank'  title='Definition of exactMatch in the SKOS Vocabulary'>External Exact Match</a>"
    when "closeMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#closeMatch' target='blank'  title='Definition of Modified in the SKOS Vocabulary'>External Close Match</a>"
    when "related"
      "<a href='http://www.w3.org/2004/02/skos/core#related' target='blank'  title='Definition of Related in the SKOS Vocabulary'>Related Terms</a>"
    when "broader"
      "<a href='http://www.w3.org/2004/02/skos/core#broader' target='blank'  title='Definition of Broader in the SKOS Vocabulary'>Broader Terms</a>"
    when "narrower"
      "<a href='http://www.w3.org/2004/02/skos/core#narrower' target='blank'  title='Definition of Narrower in the SKOS Vocabulary'>Narrower Terms</a>"
    else
      field.humanize
    end
  end
end
