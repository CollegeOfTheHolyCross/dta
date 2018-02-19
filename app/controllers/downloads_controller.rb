class DownloadsController < ApplicationController

  def show
    if base_file.nil?
      raise 'File was nil'
    else
      if params["file"].present? and params["file"] == 'thumbnail' and thumbnail.present?
        file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{thumbnail.path.split('.').last}"
        mime_type = thumbnail.mime_type
      else

        mime_type = base_file.mime_type
        if params[:institution].empty?
          file_name = "#{base_object.title.gsub(/[,;]/, '')}.#{base_file.path.split('.').last}"
          ahoy.track_visit
          ahoy.track "Object Download", {title: @object.title}, {collection_pid: @object.coll.pid, institution_pid: @object.inst.pid, pid: params[:id], model: "GenericObject", search_term: session[:search_term]}
          base_object.downloads = base_object.downloads + 1
          base_object.save!
        else
          file_name = "#{base_object.name.gsub(/[,;]/, '')}.#{base_file.path.split('.').last}"
        end
      end
    end

    send_data get_content, type: mime_type, disposition: 'inline', filename: "#{file_name}"
  end

  def base_object
    if params[:institution].present?
      @object ||= Inst.find_by(pid: params[:id])
    else
      @object ||= GenericObject.find_by(pid: params[:id])
    end

  end

  def base_file
    if params[:institution].present?
      @file ||= base_object.inst_image_files[0]
    else
      @file ||= base_object.base_files[0]
    end
  end

  def thumbnail
    if params[:institution].present?
      @file ||= base_file
    else
      @thumbnail ||= base_file.thumbnail_derivatives[0]
    end

  end

  def get_content
    return '' if base_file.nil?

    if params["file"].present? and params["file"] == 'thumbnail'
      if thumbnail.nil?
        return base_file.content
      else
        return thumbnail.content
      end
    else
      return base_file.content
    end
  end

  def authorize!
    return true
  end

=begin
  def send_content
    if file.mime_type == "application/pdf"
      self.status = 200
      response.headers['Content-Length'] = file.size.to_s
      response.headers['Content-Disposition'] = "inline;filename=#{asset.label.gsub(/[,;]/, '')}.pdf"
      render body: file.content, content_type: "application/pdf"
    else
      super
    end

  end
=end

end
