class Api::V1::SchemaMappingsController < ApplicationController
  before_action :set_schema_mapping

  def confirm
    @schema_mapping.update!(confirmed: true)
    head :no_content
  end

  def reject
    @schema_mapping.destroy!
    head :no_content
  end

  private

  def set_schema_mapping
    @schema_mapping = current_user.adler_schema&.schema_mappings&.find(params[:id])
    head :not_found unless @schema_mapping
  end
end
