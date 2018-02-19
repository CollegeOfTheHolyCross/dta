class DSolr
  def self.find_by_id(id)
    solr = RSolr.connect :url => Settings.solr_url
    response = solr.get 'select', :params => {:q => "id:#{id}"}
    # result["response"]["docs"][0]["visibility_ssi"]
    response["response"]["docs"][0]
  end

  def self.find(args)
    solr = RSolr.connect :url => Settings.solr_url
    response = solr.get 'select', :params => args
    response["response"]["docs"]
  end

  def self.delete_by_id(id)
    solr = RSolr.connect :url => Settings.solr_url, update_format: :json
    solr.delete_by_id "#{id}"
  end

  def self.put(doc)
    raise 'No valid :id found' if doc.blank? || doc[:id].blank? || !doc[:id].match(/.....+/)
    solr = RSolr.connect :url => Settings.solr_url, update_format: :json
    solr.add [doc]
    solr.update data: '<commit/>', headers: { 'Content-Type' => 'text/xml' }
  end

  def self.reindex(model)
    model.constantize.find_in_batches(batch_size: 200) do |model_batch|
      Rails.application.executor.wrap do
        th = Thread.new do
          Rails.application.executor.wrap do
            solr = RSolr.connect :url => Settings.solr_url, update_format: :json
            model_batch.each do |obj|
              doc = obj.generate_solr_content({})
              solr.add [doc]
            end
          end
        end
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          th.join # outer thread waits here, but has no lock
        end
      end
    end
    # Commit the reindex
    solr = RSolr.connect :url => Settings.solr_url, update_format: :json
    solr.update data: '<commit/>', headers: { 'Content-Type' => 'text/xml' }
  end

end
