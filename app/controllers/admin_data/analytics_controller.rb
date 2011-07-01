require "ostruct"

module AdminData
  class AnalyticsController < ApplicationController

    before_filter :get_class_from_params
    before_filter :set_ivars

    rescue_from AdminData::NoCreatedAtColumnException, :with => :render_no_created_at

    def get_hm_instance(row)
      klass = row[:klass].camelize.constantize
      relationship = row[:relationship]
      hm_klass = ActiveRecordUtil.new(klass).klass_for_association_type_and_name(:has_many, relationship)
      Analytics::HmAssociation.new(klass, hm_klass, relationship)
    end

    def build_chart_search
      @data_points = []

      record = OpenStruct.new
      hm_instance1 = get_hm_instance(params[:search][:row_1])
      record.data = hm_instance1.count_of_main_klass_records_in_hm_klass
      record.title = "Users with phone_number"
      @data_points << record

      record = OpenStruct.new
      hm_instance2 = get_hm_instance(params[:search][:row_2])
      record.data = hm_instance2.count_of_main_klass_records_not_in_hm_klass
      record.title = "Users without phone_number"
      @data_points << record

      respond_to do |format|
        format.js do
          render :template => 'admin_data/analytics/build_chart_search', :layout => false
        end
      end
    end

    def build_chart
      @has_many_associations = ActiveRecordUtil.new(@klass).declared_has_many_association_names
    end

    def render_no_created_at
      render :text => "Model #{@klass} does not have created_at column"
    end

    def daily
      @chart_title = "#{@klass.name} records created in the last 30 days"

      a = AdminData::Analytics.daily_report(@klass, Time.now)
      @chart_data_s = a.map {|e| e.last }.join(', ')
      @chart_data_x_axis = a.map {|e| e.first}.join(', ')
      render :action => 'index'
    end

    def monthly
      @chart_title = "#{@klass.name} rercords created last year"
      a = AdminData::Analytics.monthly_report(@klass, Time.now)
      @chart_data_s = a.map {|e| e.last }.join(', ')
      @chart_data_x_axis = a.map {|e| e.first}.join(', ')
      render :action => 'index'
    end

    def set_ivars
      @chart_width = 950
      @chart_height = 400
      @chart_h_axis_title = ''
      @chart_legend_name = 'Created'
    end

  end
end
