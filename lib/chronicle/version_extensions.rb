module Chronicle::VersionExtensions
  # Return an instance of the versioned ActiveRecord model with the attribute
  # values and page parts of this version.  Initializes it just like #find so 
  # you can compare objects.
  def instance(reload=false)
    if reload || @instance.nil?
      attributes = YAML::load( self.yaml )
      associations = (attributes.keys - versionable.class.column_names).map {|k| [k,attributes[k]] }
      instance_class = case versionable_type
      when "Page"
         attributes[:class_name] ? attributes[:class_name].constantize : Page
      else
        versionable_type.constantize
      end
      obj = instance_class.send(:instantiate, attributes)
#TODO: Make a VersionedAssociationCollection that handles find_by_name?  Or just define another method, #part(name), that always does an Array#find.
      associations.each do |assoc_name,assoc_value|
        obj.instance_variable_set "@#{assoc_name}", assoc_value
        (class << obj; self; end).send(:define_method, assoc_name) do
          instance_variable_get "@#{assoc_name}"
        end
      end
      obj.parts
      @instance = obj
    end
    @instance
  end
  
  def saved_by
    instance.updated_by || instance.created_by
  end
  
  def current?
    versionable.versions.current.number == self.number
  end
  alias_method :current_dev?, :current?
  
  def current_live?
    current_live = versionable.versions.current_live
    current_live && (current_live.number == self.number)
  end
  
  def only_visible_in_dev_mode?
    status_id < Status[:published].id
  end
  
  def diff
    if previous
      previous.instance.diff(self.instance)
    else
      self.instance.diff(self.instance)
    end
  end
end