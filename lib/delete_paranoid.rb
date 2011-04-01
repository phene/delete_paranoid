require 'active_record'

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      class << self
        alias_method :destroy!, :destroy
      end
      alias_method :destroy!, :destroy
      default_scope where(:deleted_at => nil)
      include DeleteParanoid::InstanceMethods
      extend DeleteParanoid::ClassMethods
    end
  end
  module ClassMethods
    def with_deleted
      self.unscoped do
        yield
      end
    end
  end
  module InstanceMethods
    def destroy
      if persisted?
        with_transaction_returning_status do
          _run_destroy_callbacks do
            self.class.update_all ["deleted_at = ?", Time.now.utc], { :id => self.id }
            @destroyed = true
          end
        end
      else
        @destroyed = true
      end
      
      freeze
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
