require 'rubygems'
require 'ostruct'

module DBStruct
  # The purpose of this module is to have a struct inside an ordinary object
  # to contain feilds for persistence. The fields are accessed the same way
  # as the other fields inside the object.. 
  # 
  
  
  # Define dynamic accessors to struct fields
  def method_missing(mid, *args) 
    fieldname = mid.id2name
    
    if mid.id2name.match("=")
      fieldname.chop!
      if args.length != 1
        raise ArgumentError, "Setter must have only one argument. Number of arguments found was (#{len} for 1)", caller(1)
      end
      
      # Make sure fields aren't added in error (typos)
      if !@_dbdata.marshal_dump.key?(fieldname.to_sym) & @_frozen 
        raise ArgumentError, "Struct fields are frozen, reopen before using <field>= . Field was (#{fieldname} for 1)", caller(1)
      end
    end
    
    if @_dbdata == nil
      super(mid, *args)
      
    elsif  @_dbdata.marshal_dump.key?(fieldname.to_sym)
      @_dbdata.send(mid.id2name,args[0])
      
      # Route method missing to struct object  
    elsif !@_frozen & mid.id2name.match("=")
      @_dbdata.method_missing(mid, *args)
      
      # Forward methods missing not related to struct
    else
      super(mid, *args)
    end
  end
  
  # Used for creating an object based on an hash (primarily for loading records directly from DB
  def load(response)
    if response != nil
      @_dbdata = OpenStruct.new(response)
      @_frozen = true
    end
  end
  
  # Export hash from struct
  def save(*args)
    @_dbdata.marshal_dump(*args)
  end
  
  def get(db, pkid)
    @_dbdata.pkid = db[self.class.get_table].filter(:pkid =>pkid)
  end
  
  
  def insert(db)
    @_dbdata.pkid = db[self.class.get_table].insert(save)
  end
  
  def delete(db,search_criteria)
    db[self.class.get_table].filter({:pkid =>pkid}).delete
  end
   
  
  def update(db)
    db[self.class.get_table].filter({:pkid => pkid}).update(save)
  end
 
  
  # Define which fields are needed. Sent in as an array of symbols or strings
  def setup_fields(fields)
    h = {}
    fields.each do |field|
      if field.kind_of? Symbol     
        h[field.to_s] = nil
      else
        h[field] = nil
      end
    end
    @_dbdata = OpenStruct.new(fields)
    @_frozen = true
  end
  
  # Avoid anyone referencing @_dbdata directly
  def empty?
    @_dbdata == nil
  end
  
  # When overiding method_missing this one should also be...
  def respond_to(*args)
    super(*args)
  end
  
  # Freeze struct so new fields aren't added by mistake
  def freeze_fields
    @_frozen = true
  end
  
  # Unfreeze struct so new fields can be added manually. Remember to freeze afterwards
  def unfreeze_fields
    @_frozen = false
  end
  
  #Class methods for included dbstructs
  def self.included receiver
    receiver.extend DBStructClassMethods
  end
  
  module DBStructClassMethods
    # Used to create objects based on database rows
   
    
    
    def create(rows)
      list = []
      if rows == nil
        return list
      end
      rows.each do |row|
        the_instance = self.new
        the_instance.load(row)
        list << the_instance
      end
      list
    end 
   
    #Hack enable referencing modularized class-variable from instance
    def get_table
      return @@_table
    end
    
    #Binds class to given table in the database, Sequel specific
    def bind_table(db,table)
      tablefields = []
      @@_table = table
      
      if db.schema(table).empty?
        raise ArgumentError, "Table [#{table}] was not found. Unable to bind object", caller(1)
      end
      
      db.schema(table).each do |fields|
        tablefields << fields[0] 
      end
      bind(tablefields)
    end
    
    # Use this to bind a class to a table, so new objects created with template will match fields in database
    def bind(fields)
      
      if fields.empty?
        raise ArgumentError, "Trying to bind object to empty list of fields..."
      end
      
      if (@@_template rescue nil) != nil
        raise ArgumentError, "Class already bound to table: #{@@_template.to_s}. Use method rebind if new binding is needed", caller(1)
      end
      @@_template = {}
      fields.each { |field| @@_template[field] = nil} 
      return 
    end
    
    # Method can rebind fields if database changes dynamicly.... I'm not sure you should need this one....
    def rebind!(fields)
      @@_template = {}
      fields.each { |field| @@_template[field] = nil}
      return 
    end

        
  def find(db,search_criteria)
    db[@@_table].filter(search_criteria)
  end

    
  def delete!(db,search_criteria)
    db[@@_table].filter(search_criteria).delete
  end
  
   
  def update!(db,search_criteria, update_criteria)
    db[@@_table ].filter(search_criteria).update(update_criteria)
  end
  
 
    
    def template(*args)
      the_instance = self.new(*args)
      the_instance.load(@@_template)
      the_instance
    end  
    
  def find(db,search_criteria)
    create(db[@@_table].where(search_criteria))
    
  end
  
  end
  
end
