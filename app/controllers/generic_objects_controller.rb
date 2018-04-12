class GenericObjectsController < ApplicationController
  include Blacklight::Catalog
  include DtaSearchHelper
  include DtaStaticBuilder

  copy_blacklight_config_from(CatalogController)

  before_action :get_latest_content

  before_action :verify_contributor, except: [:show, :citation] #FIXME: Added show for now... but need to remove that...

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  #skip_load_and_authorize_resource :only=> [:create, :swap_visibility, :show] #FIXME: Why needed for swap visibility exactly?

  #GenericFilesController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    search_catalog_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  # routed to /files/:id
  def show
    #super
    @generic_file = GenericObject.find_by(pid: params[:id])
    @generic_file.views = @generic_file.views + 1
    @generic_file.save!
    if @generic_file.visibility == "hidden" and !current_or_guest_user.contributor?
      redirect_to root_path
    else
      search_term = current_search_session.present? ? current_search_session.query_params["q"].to_s : 'N/A: Directly Linked'
      session[:search_term] = search_term

      unless current_user.present? and current_user.contributor?
        ahoy.track_visit
        ahoy.track "Object View", {title: @generic_file.title}, {collection_pid: @generic_file.coll.pid, institution_pid: @generic_file.inst.pid, pid: params[:id], model: "GenericObject", search_term: search_term}
      end

      respond_to do |format|
        format.html do
          setup_next_and_previous_documents
          @show_response, @document = fetch(params[:id])
        end
      end
    end
  end

  def new
    @generic_object = GenericObject.new

    if session[:unsaved_generic_object].present?
      begin
        @generic_object.update(ActiveSupport::HashWithIndifferentAccess.new(session[:unsaved_generic_object]))
      rescue => ex
      end
      session[:unsaved_generic_object] = nil
    end

    @selectable_collection = []

    institutions = Inst.all.pluck(:name, :pid)
    @selectable_institution = institutions.sort_by { |key, val| key }
  end

  def set_object(form_fields)
    @generic_object.title = form_fields[:title]
    @generic_object.alt_titles = form_fields[:alt_titles].reject { |c| c.empty? } if form_fields[:alt_titles][0].present?
    @generic_object.creators = form_fields[:creators].reject { |c| c.empty? } if form_fields[:creators][0].present?
    @generic_object.contributors = form_fields[:contributors].reject { |c| c.empty? } if form_fields[:contributors][0].present?
    @generic_object.date_created = form_fields[:date_created].reject { |c| c.empty? } if form_fields[:date_created][0].present?
    @generic_object.date_issued = form_fields[:date_issued].reject { |c| c.empty? } if form_fields[:date_issued][0].present?
    @generic_object.temporal_coverage = form_fields[:temporal_coverage].reject { |c| c.empty? } if form_fields[:temporal_coverage][0].present?

    form_fields[:lcsh_subjects].each_with_index do |s, index|
      if s.present?
        form_fields[:lcsh_subjects][index] = s.split('(').last
        form_fields[:lcsh_subjects][index].gsub!(/\)$/, '')
      end
    end
    form_fields[:geonames].each_with_index do |s, index|
      if s.present?
        form_fields[:geonames][index] = s.split('(').last
        form_fields[:geonames][index].gsub!(/\)$/, '')
      end
    end
    form_fields[:homosaurus_subjects].each_with_index do |s, index|
      if s.present?
        form_fields[:homosaurus_subjects][index] = s.split('(').last
        form_fields[:homosaurus_subjects][index].gsub!(/\)$/, '')
      end
    end
    @generic_object.geonames = form_fields[:geonames].reject { |c| c.empty? } if form_fields[:geonames][0].present?
    @generic_object.homosaurus_subjects = form_fields[:homosaurus_subjects].reject { |c| c.empty? } if form_fields[:homosaurus_subjects][0].present?
    @generic_object.lcsh_subjects = form_fields[:lcsh_subjects].reject { |c| c.empty? } if form_fields[:lcsh_subjects][0].present?
    @generic_object.other_subjects = form_fields[:other_subjects].reject { |c| c.empty? } if form_fields[:other_subjects][0].present?

    @generic_object.flagged = form_fields[:flagged]
    @generic_object.analog_format = form_fields[:analog_format] if form_fields[:analog_format][0].present?
    @generic_object.digital_format = form_fields[:digital_format] if form_fields[:digital_format][0].present?

    @generic_object.descriptions = form_fields[:descriptions].reject { |c| c.empty? } if form_fields[:descriptions][0].present?
    @generic_object.toc = form_fields[:toc].reject { |c| c.empty? } if form_fields[:toc][0].present?
    @generic_object.languages = form_fields[:languages].reject { |c| c.empty? } if form_fields[:languages][0].present?

    @generic_object.publishers = form_fields[:publishers].reject { |c| c.empty? } if form_fields[:publishers][0].present?
    @generic_object.related_urls = form_fields[:related_urls].reject { |c| c.empty? } if form_fields[:related_urls][0].present?
    @generic_object.rights = form_fields[:rights] if form_fields[:rights][0].present?
    @generic_object.rights_free_text = form_fields[:rights_free_text].reject { |c| c.empty? } if form_fields[:rights_free_text][0].present?
    @generic_object.depositor = current_user.to_s

    @generic_object.is_shown_at = form_fields[:is_shown_at] if form_fields[:is_shown_at][0].present?
    @generic_object.hosted_elsewhere = form_fields[:hosted_elsewhere]

    # These were missing
    @generic_object.genres = form_fields[:genres].reject { |c| c.empty? }
    @generic_object.resource_types = form_fields[:resource_types].reject { |c| c.empty? } if form_fields[:resource_types][0].present?

    @generic_object.inst = Inst.find_by(pid: params[:institution])
    @generic_object.coll = Coll.find_by(pid: params[:collection])
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      unless validate_metadata(params, 'create')
        session[:unsaved_generic_object] = params[:generic_object]
        #redirect_to new_generic_object_path
        redirect_back(fallback_location: new_generic_object_path)
      else

        @generic_object = GenericObject.find_or_initialize_by(pid: params[:pid])
        #@generic_object = GenericObject.new
        form_fields = params['generic_object']

        self.set_object(form_fields)

        @generic_object.visibility = "private"

        if params[:generic_object][:hosted_elsewhere] != "0"
          if params.key?(:filedata)
            file = params[:filedata]

            image = MiniMagick::Image.open(file.path())

            if File.extname(file.original_filename) == '.pdf'
              image.format('jpg', 0, {density: '300'})
            else
              image.format "jpg"
            end

            image.resize "500x600"

            @generic_object.add_file(image.to_blob, 'image/jpeg', File.basename(file.original_filename,File.extname(file.original_filename)))
          end
        else
          file = params[:filedata]
          @generic_object.add_file(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
        end

        @generic_object.save!

        # Make this better
        @generic_object.coll.send_solr
        @generic_object.inst.send_solr

        #ProcessFileWorker.perform_async(@generic_object.base_files[0].id)
        @generic_object.base_files[0].create_derivatives
        redirect_to generic_object_path(@generic_object.pid), notice: "This object has been created."
      end

    end
  end

  def update
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      @generic_object = GenericObject.find(params[:id])

      unless validate_metadata(params, 'update')
        raise params[:generic_object][:temporal_coverage].to_s
        redirect_back(fallback_location: edit_generic_object_path(@generic_object.pid))
      else


        #@generic_object = GenericObject.new

        form_fields = params['generic_object']
        # There is a bug with completely removing a value
        self.set_object(form_fields)

        if params.key?(:filedata)
          # FIXME: This does it before save...
          @generic_object.base_files.clear

          file = params[:filedata]

          if params[:generic_object][:hosted_elsewhere] != "0"
            image = MiniMagick::Image.open(file.path())

            if File.extname(file.original_filename) == '.pdf'
              image.format('jpg', 0, {density: '300'})
            else
              image.format "jpg"
            end

            image.resize "500x600"

            @generic_object.add_file(image.to_blob, 'image/jpeg', File.basename(file.original_filename,File.extname(file.original_filename)))
          else
            @generic_object.add_file(File.open(file.path(), 'rb').read, file.content_type, file.original_filename)
          end
        end

        @generic_object.save!

        if params.key?(:filedata)
          @generic_object.base_files[0].create_derivatives
        end

        # Make this better
        @generic_object.coll.send_solr
        @generic_object.inst.send_solr

        redirect_to generic_object_path(@generic_object.pid), notice: "This object has been updated."
      end

    end
  end

  def destroy
    GenericObject.find_by(pid: params[:id]).destroy!
    redirect_to root_path, notice: "This object has been removed from the system."
  end

  def validate_metadata(params, type)
    if !params.key?(:filedata) && params[:generic_object][:hosted_elsewhere] != "1" && type != 'update'
      flash[:error] = 'No file was uploaded!'

      return false
    end

    params[:generic_object][:date_created].each do |date_created|
      if date_created.present? and Date.edtf(date_created).nil?
        flash[:error] = 'Incorrect format for date created. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:date_issued].each do |date_issued|
      if date_issued.present? and Date.edtf(date_issued).nil?
        flash[:error] = 'Incorrect format for date issued. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:temporal_coverage].each do |temporal_coverage|
      if temporal_coverage.present? and Date.edtf(temporal_coverage).nil?
        flash[:error] = 'Incorrect format for temporal coverage. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_object][:languages].each do |language|
      if language.present? and !language.match(/id\.loc\.gov\/vocabulary\/iso639\-2\/\w\w\w/)
        flash[:error] = 'Language was not selected from the autocomplete?'
        return false
      end
    end
    return true
  end

  def swap_visibility
    obj = GenericObject.find_by(pid: params[:id])
    if obj.visibility == 'private'
      obj.visibility = 'public'
    else
      obj.visibility = 'private'
    end
    obj.save!
    flash[:notice] = "Visibility of object was changed!"
    redirect_to generic_object_path(obj.pid)
    #redirect_to request.referrer
  end

  def regenerate_thumbnail
    obj = GenericObject.find_by(pid: params[:id])
    obj.base_files[0].create_derivatives
    flash[:notice] = "Thumbnail was regenerated!"
    redirect_to generic_object_path(obj.pid)
  end

  def edit
    if params[:version_id].present?
      @generic_object = PaperTrail::Version.find(params[:version_id]).reify
    else
      @generic_object = GenericObject.find_by(pid: params[:id])
    end

    institutions = Inst.all.pluck(:name, :pid)
    @selectable_institution = institutions.sort_by { |key, val| key }

    @institution_id = @generic_object.inst.pid
    @collection_id = @generic_object.coll.pid

    @selectable_collection = []
    @selectable_collection = @generic_object.inst.colls.pluck(:title, :pid)
    @selectable_collection.uniq!
    @selectable_collection = @selectable_collection.sort_by { |key, val| key }
  end
  
end
